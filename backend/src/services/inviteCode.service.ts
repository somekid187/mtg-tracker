import pool from "../config/db.config";
import crypto from "node:crypto";

function createError(code: string, message: string) {
  const error = Object.create(null);
  error.code = code;
  error.message = message;
  return error;
}

export async function createInviteCodeService(req: any) {
  const userId = req.user?.userId;
  if (!userId) throw createError("UNAUTHORIZED", "User not authenticated");

  const { fk_match_connects, expiresInHours } = req.body;
  if (!fk_match_connects) throw createError("MISSING_FIELDS", "Match ID is required");

  const code = crypto.randomBytes(4).toString("hex").toUpperCase();
  const hours = expiresInHours ?? 24;
  const expiresAt = new Date(Date.now() + hours * 60 * 60 * 1000);

  const connection = await pool.getConnection();
  try {
    await connection.execute(
      "CALL sp_inviteCode_create(?, ?, ?, @out_response)",
      [code, expiresAt, fk_match_connects]
    );
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "INVITE_CREATE_FAILED", result?.message || "Failed to create invite code");
    return { success: true, data: { ...result.data, code, expiresAt } };
  } finally {
    connection.release();
  }
}

export async function getInviteCodeByIdService(id: string) {
  if (!id) throw createError("MISSING_FIELDS", "Invite code ID is required");
  const connection = await pool.getConnection();
  try {
    await connection.execute("CALL sp_inviteCode_get_by_id(?, @out_response)", [id]);
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "INVITE_NOT_FOUND", result?.message || "Invite code not found");
    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}

export async function getInviteCodeByCodeService(code: string) {
  if (!code) throw createError("MISSING_FIELDS", "Code is required");
  const connection = await pool.getConnection();
  try {
    const [rows]: any = await connection.execute(
      "SELECT pk_inviteCode, code, status, createdAt, expiresAt, fk_match_connects FROM InviteCode WHERE code = ? LIMIT 1",
      [code]
    );
    if (!rows || rows.length === 0) throw createError("INVITE_NOT_FOUND", "Invite code not found");
    const invite = rows[0];
    if (invite.status === "expired" || new Date(invite.expiresAt) < new Date()) {
      throw createError("INVITE_EXPIRED", "This invite code has expired");
    }
    return { success: true, data: invite };
  } finally {
    connection.release();
  }
}

export async function expireInviteCodeService(id: string) {
  if (!id) throw createError("MISSING_FIELDS", "Invite code ID is required");
  const connection = await pool.getConnection();
  try {
    await connection.execute(
      "CALL sp_inviteCode_update(?, ?, ?, ?, @out_response)",
      [id, null, "expired", null]
    );
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "INVITE_UPDATE_FAILED", result?.message || "Failed to expire invite code");
    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}

export async function deleteInviteCodeService(id: string) {
  if (!id) throw createError("MISSING_FIELDS", "Invite code ID is required");
  const connection = await pool.getConnection();
  try {
    await connection.execute("CALL sp_inviteCode_delete(?, @out_response)", [id]);
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "INVITE_DELETE_FAILED", result?.message || "Failed to delete invite code");
    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}

export async function getInviteCodesByMatchService(matchId: string) {
  if (!matchId) throw createError("MISSING_FIELDS", "Match ID is required");
  const connection = await pool.getConnection();
  try {
    const [rows]: any = await connection.execute(
      "SELECT * FROM InviteCode WHERE fk_match_connects = ? ORDER BY createdAt DESC",
      [matchId]
    );
    return { success: true, data: rows };
  } finally {
    connection.release();
  }
}
