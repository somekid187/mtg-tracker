import {
  hashPassword,
  verifyPassword,
  encrypt,
  decrypt,
} from "../utils/passwordUtil";
import pool from "../config/db.config";
import crypto from "node:crypto";
import jwt from "jsonwebtoken";
import {
  generateAccessToken,
  generateRefreshToken,
  hashToken,
} from "../middleware/auth.middleware";
import { sendActivationEmail } from "../utils/email";

import {
  validateEmail,
  validatePassword,
  validateUsername,
} from "../utils/validators";

export async function registerService(req: any) {
  // Validate that req.body exists
  if (!req.body) {
    throw {
      code: "INVALID_REQUEST",
      message:
        "Request body is missing. Make sure Content-Type is application/json",
    };
  }

  const { username, email, password } = req.body;

  // Validate required fields
  if (!username || !email || !password) {
    throw {
      code: "MISSING_FIELDS",
      message: "Username, email, and password are required",
    };
  }

  const emailValidation = validateEmail(email);
  const passwordValidation = validatePassword(password);
  const usernameValidation = validateUsername(username);

  // If any validation fails, throw an error with the corresponding message
  if (!emailValidation.isValid) {
    throw { code: "INVALID_EMAIL", message: emailValidation.message };
  }
  if (!passwordValidation.isValid) {
    throw { code: "INVALID_PASSWORD", message: passwordValidation.message };
  }
  if (!usernameValidation.isValid) {
    throw { code: "INVALID_USERNAME", message: usernameValidation.message };
  }

  // Hash the password and generate a verification token
  const hashedPassword = await hashPassword(password);
  const verificationToken = crypto.randomBytes(32).toString("hex");
  const encryptedPassword = encrypt(hashedPassword);

  // Call the stored procedure to create the user and handle the result
  const connection = await pool.getConnection();
  try {
    await connection.execute("CALL sp_user_create(?, ?, ?, ?, @out_response)", [
      username,
      email,
      encryptedPassword,
      verificationToken,
    ]);

    const [rows]: any = await connection.query(
      "SELECT @out_response as result",
    );
    const result = JSON.parse(rows[0].result);

    if (!result || !result.success) {
      throw {
        code: result?.code || "INTERNAL_SERVER_ERROR",
        message: result?.message || "An error occurred",
      };
    }

    // IMPORTANT: sp_user_create commits internally, so email sending can't be part of the same DB transaction.
    // If email sending fails, we do a compensating delete to keep registration "all-or-nothing".
    try {
      await sendActivationEmail({
        to: email,
        username,
        activationToken: verificationToken,
      });
    } catch (emailError: any) {
      const createdUserId = result?.data?.pk_appUser;
      if (createdUserId) {
        try {
          await connection.execute("CALL sp_user_delete(?, @out_response)", [
            createdUserId,
          ]);
        } catch {
          // If cleanup fails, we still surface the original failure (email send).
        }
      }

      throw {
        code: "ACTIVATION_EMAIL_FAILED",
        message:
          "User could not be registered because the activation email failed to send.",
        cause: emailError?.message || String(emailError),
      };
    }

    return {
      success: true,
      data: result.data,
      error: null,
    };
  } finally {
    connection.release();
  }
}

export async function loginService(req: any) {
  // Validate that req.body exists
  if (!req.body) {
    throw {
      code: "INVALID_REQUEST",
      message:
        "Request body is missing. Make sure Content-Type is application/json",
    };
  }

  const { email, password } = req.body;

  // Validate required fields
  if (!email || !password) {
    throw {
      code: "MISSING_FIELDS",
      message: "Email and password are required",
    };
  }

  const emailValidation = validateEmail(email);

  if (!emailValidation.isValid) {
    throw { code: "INVALID_EMAIL", message: emailValidation.message };
  }

  const connection = await pool.getConnection();
  try {
    await connection.execute("CALL sp_user_get_password(?, @out_response)", [
      email,
    ]);

    const [rows]: any = await connection.query(
      "SELECT @out_response as result",
    );
    const result = JSON.parse(rows[0].result);

    if (!result || !result.success) {
      throw {
        code: result?.code || "INVALID_CREDENTIALS",
        message: result?.message || "Invalid email or password",
      };
    }

    const passwordHash = decrypt(result.data.passwordHash);
    const passwordMatch = await verifyPassword(passwordHash, password);
    if (!passwordMatch) {
      throw {
        code: "INVALID_CREDENTIALS",
        message: "Invalid email or password",
      };
    }

    // sp_user_get_password only returns the passwordHash, so we fetch the user id separately.
    const [userRows]: any = await connection.execute(
      "SELECT pk_appUser FROM AppUser WHERE email = ?",
      [email],
    );
    if (!userRows || userRows.length === 0) {
      throw {
        code: "INVALID_CREDENTIALS",
        message: "Invalid email or password",
      };
    }
    const userId = userRows[0].pk_appUser;

    const accessToken = generateAccessToken({
      userId,
    });
    const refreshToken = generateRefreshToken();

    // Hash the refresh token before storing
    const tokenHash = hashToken(refreshToken.trim());

    // Get client IP and device info
    const clientIp = req.ip || req.connection?.remoteAddress || "unknown";
    const deviceName = req.headers["user-agent"] || "unknown";

    // Calculate expiration date (7 days from now)
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days in milliseconds

    // Store the refresh token in database
    await connection.execute(
      "CALL sp_refreshToken_create(?, ?, ?, ?, ?, ?, ?, @out_response)",
      [
        userId,
        tokenHash,
        clientIp,
        clientIp,
        deviceName,
        expiresAt,
        null, // No rotation for initial login
      ],
    );

    const [tokenRows]: any = await connection.query(
      "SELECT @out_response as result",
    );
    const tokenResult = JSON.parse(tokenRows[0].result);

    if (!tokenResult || !tokenResult.success) {
      throw {
        code: tokenResult?.code || "TOKEN_CREATION_FAILED",
        message: tokenResult?.message || "Failed to create refresh token",
      };
    }

    return {
      success: true,
      data: {
        userId,
        email: email,
        accessToken,
        refreshToken,
      },
      error: null,
    };
  } finally {
    connection.release();
  }
}

export async function refreshService(req: any) {
  if (!req.body) {
    throw {
      code: "INVALID_REQUEST",
      message:
        "Request body is missing. Make sure Content-Type is application/json",
    };
  }

  const { refreshToken } = req.body;
  if (typeof refreshToken !== "string" || refreshToken.trim() === "") {
    throw {
      code: "MISSING_FIELDS",
      message: "refreshToken is required",
    };
  }

  const tokenHash = hashToken(refreshToken.trim());
  const connection = await pool.getConnection();

  try {
    // Look up the existing refresh token by its hash
    const [rows]: any = await connection.execute(
      "SELECT * FROM RefreshToken WHERE tokenHash = ?",
      [tokenHash],
    );

    if (!rows || rows.length === 0) {
      throw {
        code: "TOKEN_NOT_FOUND",
        message: "Refresh token not found",
      };
    }

    const token = rows[0];

    if (token.revokedAt) {
      throw {
        code: "TOKEN_REVOKED",
        message: "Refresh token has been revoked",
      };
    }

    if (new Date(token.expiresAt) < new Date()) {
      throw {
        code: "INVALID_TOKEN",
        message: "Expired refresh token",
      };
    }

    const userId = token.fk_appUser_refreshes;

    const newAccessToken = generateAccessToken({
      userId: userId,
    });

    const newRefreshToken = generateRefreshToken();
    const newHash = hashToken(newRefreshToken);

    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000); // 7 days in milliseconds

    const device = req.headers["user-agent"] || "unknown";
    const ip = req.ip || req.connection?.remoteAddress || "unknown";

    // Rotate the refresh token using the same stored procedure pattern
    await connection.execute(
      "CALL sp_refreshToken_create(?, ?, ?, ?, ?, ?, ?, @out_response)",
      [
        userId,
        newHash,
        ip,
        ip,
        device,
        expiresAt,
        token.pk_refreshToken,
      ],
    );

    const [tokenRows]: any = await connection.query(
      "SELECT @out_response as result",
    );

    const tokenResult = JSON.parse(tokenRows[0].result);
    if (!tokenResult || !tokenResult.success) {
      throw {
        code: tokenResult?.code || "TOKEN_CREATION_FAILED",
        message: tokenResult?.message || "Failed to create refresh token",
      };
    }

    await connection.execute("CALL sp_refreshToken_revoke(?,?, @out_response)", [
      tokenHash, userId,
    ]);
    
    const [revRows]: any = await connection.query(
      "SELECT @out_response as result",
    );
    const revResult = JSON.parse(revRows[0].result);
    if (!revResult || !revResult.success) {
      throw {
        code: revResult?.code || "TOKEN_REVOCATION_FAILED",
        message: revResult?.message || "Failed to revoke refresh token",
      };
    }

    return {
      success: true,
      data: {
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      },
      error: null,
    };
  } finally {
    connection.release();
  }
}

export async function logoutService(req: any) {
  if (!req.body) {
    throw {
      code: "INVALID_REQUEST",
      message:
        "Request body is missing. Make sure Content-Type is application/json",
    };
  }

  const { refreshToken } = req.body;
  if (typeof refreshToken !== "string" || refreshToken.trim() === "") {
    throw {
      code: "MISSING_FIELDS",
      message: "refreshToken is required",
    };
  }

  const tokenHash = hashToken(refreshToken.trim());
  const userId = (req as any).user.userId;
  const connection = await pool.getConnection();

  try {
    await connection.execute("CALL sp_refreshToken_revoke(?,?, @out_response)", [
      tokenHash, userId,
    ]);
    const [tokenRows]: any = await connection.query(
      "SELECT @out_response as result",
    );
    const tokenResult = JSON.parse(tokenRows[0].result);
    if (!tokenResult || !tokenResult.success) {
      throw {
        code: tokenResult?.code || "TOKEN_REVOCATION_FAILED",
        message: tokenResult?.message || "Failed to revoke refresh token",
      };
    }
    return {
      success: true,
      data: {
        message: "Refresh token revoked successfully",
      },
      error: null,
    };
  } catch (error) {
    throw {
      code: "INTERNAL_SERVER_ERROR",
      message: "An error occurred while revoking the refresh token",
    };
  } finally {
    connection.release();
  }
}

export async function activateService(req: any) {
  const { token } = req.body;
  const connection = await pool.getConnection();
  try {
    await connection.execute("CALL sp_user_activate(?, @out_response)", [
      token,
    ]);
    const [rows]: any = await connection.query(
      "SELECT @out_response as result",
    );
    const result = JSON.parse(rows[0].result);
    if (!result || !result.success) {
      throw {
        code: result?.code || "ACTIVATION_FAILED",
        message: result?.message || "Failed to activate account",
      };
    }
    return {
      success: true,
      data: result.data,
      error: null,
    };
  } finally {
    connection.release();
  }
}