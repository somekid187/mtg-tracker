import { hashPassword, verifyPassword, encrypt, decrypt } from "../utils/passwordUtil";
import pool from "../config/db.config";
import crypto from "node:crypto";
import jwt from "jsonwebtoken";
import { generateAccessToken } from "../middleware/auth.middleware";

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
      message: "Request body is missing. Make sure Content-Type is application/json" 
    };
  }

  const { username, email, password } = req.body;
  
  // Validate required fields
  if (!username || !email || !password) {
    throw { 
      code: "MISSING_FIELDS", 
      message: "Username, email, and password are required" 
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

    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    
    if (!result || !result.success) { 
      throw { code: result?.code || "INTERNAL_SERVER_ERROR", message: result?.message || "An error occurred" }; 
    }
    
    return {
      success: true,
      data: result.data,
      error: null
    }
  } finally {
    connection.release();
  }
}

export async function loginService(req: any) {
  // Validate that req.body exists
  if (!req.body) {
    throw { 
      code: "INVALID_REQUEST", 
      message: "Request body is missing. Make sure Content-Type is application/json" 
    };
  }

  const { email, password } = req.body;
  
  // Validate required fields
  if (!email || !password) {
    throw { 
      code: "MISSING_FIELDS", 
      message: "Email and password are required" 
    };
  }

  const emailValidation = validateEmail(email);

  if (!emailValidation.isValid) {
    throw { code: "INVALID_EMAIL", message: emailValidation.message };
  }

  const connection = await pool.getConnection();
  try {
    await connection.execute("CALL sp_user_get_password(?, @out_response)", [email]);
    
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);

    if (!result || !result.success) {
      throw { 
        code: result?.code || "INVALID_CREDENTIALS", 
        message: result?.message || "Invalid email or password" 
      };
    }

    const passwordHash = decrypt(result.data.passwordHash);
    const passwordMatch = await verifyPassword(passwordHash, password);
    if (!passwordMatch) {
      throw { code: "INVALID_CREDENTIALS", message: "Invalid email or password" };
    }

    const accessToken = generateAccessToken({ userId: result.data.userId, email: email });
    const refreshToken = jwt.sign({ userId: result.data.userId, email: email }, process.env.REFRESH_TOKEN_SECRET as string, { expiresIn: '7d' });

    return {
      success: true,
      data: { ...result.data, accessToken, refreshToken },
      error: null
    };
  }finally{
    connection.release();
  }
}

export async function tokenService(req: any){
  const refreshToken = req.body.token;
  if(refreshToken == null) return res.sendStatus(401);
  
}