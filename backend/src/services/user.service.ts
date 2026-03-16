import pool from "../config/db.config";
import crypto from "node:crypto";
import { sendPasswordResetEmail } from "../utils/email";
import { hashPassword, encrypt } from "../utils/passwordUtil";

export async function getUserProfileService(userId: string) {
  const connection = await pool.getConnection();
  try {
    await connection.execute("CALL sp_user_get_by_id(?, @out_response)", [
      userId,
    ]);
    const [rows]: any = await connection.query(
      "SELECT @out_response as result",
    );
    const result = JSON.parse(rows[0].result);
    if (!result || !result.success) {
      throw {
        code: result?.code || "USER_NOT_FOUND",
        message: result?.message || "User not found",
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

export async function updateUserProfileService(userId: string, data: any) {
  const connection = await pool.getConnection();
  try {
    await connection.execute("CALL sp_user_update(?, ?, ?, @out_response)", [
      userId,
      data.username,
      data.email,
    ]);
    const [rows]: any = await connection.query(
      "SELECT @out_response as result",
    );
    const result = JSON.parse(rows[0].result);
    if (!result || !result.success) {
      throw {
        code: result?.code || "INTERNAL_SERVER_ERROR",
        message: result?.message || "An error occurred while updating the user",
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

export async function deleteUserService(userId: string) {
  const connection = await pool.getConnection();
  try {
    await connection.execute("CALL sp_user_delete(?, @out_response)", [
      userId,
    ]);
    const [rows]: any = await connection.query(
      "SELECT @out_response as result",
    );
    const result = JSON.parse(rows[0].result);
    if (!result || !result.success) {
      throw {
        code: result?.code || "INTERNAL_SERVER_ERROR",
        message: result?.message || "An error occurred while deleting the user",
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

export async function requestPasswordResetService(req: any) {
  const email = req.body.email;
  const resetToken = crypto.randomBytes(32).toString("hex");
  const connection = await pool.getConnection();
  try {
    await connection.execute("UPDATE AppUser SET resetToken = ?, tokenExpiresAt = ? WHERE email = ?", [
      resetToken,
      new Date(Date.now() + 1000 * 60 * 60 * 24),
      email,
    ]);
    await sendPasswordResetEmail({
      to: email,
      username: email,
      resetToken,
    });
    return {
      success: true,
      data: { resetToken },
      error: null,
    };
  } catch (error: any) {
    throw {
      code: "INTERNAL_SERVER_ERROR",
      message: "An error occurred while requesting the password reset",
    };
  } finally {
    connection.release();
  }
}

export async function changePasswordService(req: any) {
  const connection = await pool.getConnection();
  try {
    if(!req.token) {
      throw {
        code: "INVALID_REQUEST",
        message: "Reset token is required",
      };
    }
    if(!req.password) {
      throw {
        code: "INVALID_REQUEST",
        message: "New password is required",
      };
    }
    const passwordHash = await hashPassword(req.password);
    const encryptedPassword = encrypt(passwordHash);
    await connection.execute("CALL sp_user_change_password(?, ?, @out_response)", [
      req.token,
      encryptedPassword,
    ]);
    const [rows]: any = await connection.query(
      "SELECT @out_response as result",
    );
    const result = JSON.parse(rows[0].result);
    if (!result || !result.success) {
      throw {
        code: result?.code || "INTERNAL_SERVER_ERROR",
        message: result?.message || "An error occurred while changing the password",
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
