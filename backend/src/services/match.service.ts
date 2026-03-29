import pool from "../config/db.config";
import crypto from "node:crypto";
import { sendMatchInviteEmail } from "../utils/email";

function createError(code: string, message: string) {
  const error = Object.create(null);
  error.code = code;
  error.message = message;
  return error;
}

const DB_FORMATS = [
  "Standard", "Modern", "Legacy", "Vintage", "Pioneer",
  "Pauper", "Draft", "Sealed", "Brawl", "Two-Headed Giant", "Commander", "Custom"
];

export async function createMatchService(req: any) {
  const userId = req.user?.userId;
  if (!userId) throw createError("UNAUTHORIZED", "User not authenticated");

  const { name, format, startingLife, isTeamMatch, commanderThreshold, counterThreshold } = req.body;

  if (!format) throw createError("MISSING_FIELDS", "Format is required");
  if (!DB_FORMATS.includes(format)) throw createError("INVALID_FORMAT", "Invalid match format");
  if (!startingLife || startingLife <= 0) throw createError("MISSING_FIELDS", "Starting life must be a positive integer");

  const startTime = new Date().toTimeString().slice(0, 8);
  const connection = await pool.getConnection();
  try {
    await connection.execute(
      "CALL sp_match_create(?, ?, ?, ?, ?, ?, ?, ?, ?, @out_response)",
      [name || null, null, format, startingLife, startTime, isTeamMatch ? 1 : 0,
       commanderThreshold || null, counterThreshold || null, userId]
    );
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "MATCH_CREATE_FAILED", result?.message || "Failed to create match");

    const matchId = result.data?.pk_match;
    if (!matchId) throw createError("MATCH_CREATE_FAILED", "Failed to retrieve match ID after creation");

    const inviteCode = crypto.randomBytes(4).toString("hex").toUpperCase();
    const expiresAt = new Date(Date.now() + 24 * 60 * 60 * 1000);
    await connection.execute(
      "CALL sp_inviteCode_create(?, ?, ?, @out_response)",
      [inviteCode, expiresAt, matchId]
    );
    const [inviteRows]: any = await connection.query("SELECT @out_response as result");
    const inviteResult = JSON.parse(inviteRows[0].result);
    if (!inviteResult?.success) throw createError("INVITE_CREATE_FAILED", inviteResult?.message || "Failed to create invite code");

    return { success: true, data: { matchId, inviteCode } };
  } finally {
    connection.release();
  }
}

export async function joinMatchService(req: any) {
  const userId = req.user?.userId;
  if (!userId) throw createError("UNAUTHORIZED", "User not authenticated");

  const { inviteCode: code } = req.body;
  if (!code) throw createError("MISSING_FIELDS", "Invite code is required");

  const connection = await pool.getConnection();
  try {
    const [codeRows]: any = await connection.execute(
      "SELECT pk_inviteCode, status, expiresAt, fk_match_connects FROM InviteCode WHERE code = ? LIMIT 1",
      [code]
    );
    if (!codeRows || codeRows.length === 0) throw createError("INVITE_NOT_FOUND", "Invite code not found");

    const invite = codeRows[0];
    if (invite.status === "expired" || new Date(invite.expiresAt) < new Date()) {
      throw createError("INVITE_EXPIRED", "This invite code has expired");
    }

    const matchId = invite.fk_match_connects;

    await connection.execute("CALL sp_match_get_by_id(?, @out_response)", [matchId]);
    const [matchRows]: any = await connection.query("SELECT @out_response as result");
    const matchResult = JSON.parse(matchRows[0].result);
    if (!matchResult?.success) throw createError("MATCH_NOT_FOUND", matchResult?.message || "Match not found");

    const match = matchResult.data;

    const [existingRows]: any = await connection.execute(
      "SELECT pk_player FROM Player WHERE fk_match_isPlayedIn = ? AND fk_appUser_participates = ?",
      [matchId, userId]
    );
    if (existingRows.length > 0) throw createError("ALREADY_IN_MATCH", "You are already in this match");

    const [countRows]: any = await connection.execute(
      "SELECT COUNT(*) as cnt FROM Player WHERE fk_match_isPlayedIn = ?",
      [matchId]
    );
    const placement = (countRows[0]?.cnt ?? 0) + 1;

    await connection.execute(
      "CALL sp_player_create(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, @out_response)",
      [match.startingLife, 0, null, placement, 0,
       match.counterThreshold !== null ? 0 : null, 2, 6, null, userId, null, matchId]
    );
    const [playerRows]: any = await connection.query("SELECT @out_response as result");
    const playerResult = JSON.parse(playerRows[0].result);
    if (!playerResult?.success) throw createError("PLAYER_CREATE_FAILED", playerResult?.message || "Failed to join match");

    return { success: true, data: { matchId, playerId: playerResult.playerId } };
  } finally {
    connection.release();
  }
}

export async function leaveMatchService(req: any) {
  const userId = req.user?.userId;
  if (!userId) throw createError("UNAUTHORIZED", "User not authenticated");

  const { matchId } = req.body;
  if (!matchId) throw createError("MISSING_FIELDS", "Match ID is required");

  const connection = await pool.getConnection();
  try {
    const [playerRows]: any = await connection.execute(
      "SELECT pk_player FROM Player WHERE fk_match_isPlayedIn = ? AND fk_appUser_participates = ?",
      [matchId, userId]
    );
    if (!playerRows || playerRows.length === 0) throw createError("PLAYER_NOT_FOUND", "You are not in this match");

    const playerId = playerRows[0].pk_player;
    await connection.execute("CALL sp_player_delete(?, @out_response)", [playerId]);
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "PLAYER_DELETE_FAILED", result?.message || "Failed to leave match");

    return { success: true, data: { message: "Left match successfully" } };
  } finally {
    connection.release();
  }
}

export async function getMatchByIdService(matchId: string) {
  if (!matchId) throw createError("MISSING_FIELDS", "Match ID is required");

  const connection = await pool.getConnection();
  try {
    await connection.execute("CALL sp_match_get_by_id(?, @out_response)", [matchId]);
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "MATCH_NOT_FOUND", result?.message || "Match not found");

    const [players]: any = await connection.execute(
      `SELECT p.*, au.username as userName, g.guestName
       FROM Player p
       LEFT JOIN AppUser au ON p.fk_appUser_participates = au.pk_appUser
       LEFT JOIN Guest g ON p.fk_guest_enters = g.pk_guest
       WHERE p.fk_match_isPlayedIn = ?
       ORDER BY p.placement`,
      [matchId]
    );

    return { success: true, data: { ...result.data, players } };
  } finally {
    connection.release();
  }
}

export async function updateMatchService(matchId: string, body: any) {
  if (!matchId) throw createError("MISSING_FIELDS", "Match ID is required");

  const { name, description, format, startingLife, startTime, endTime, isTeamMatch, commanderThreshold, counterThreshold } = body;
  const connection = await pool.getConnection();
  try {
    await connection.execute(
      "CALL sp_match_update(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, @out_response)",
      [matchId, name ?? null, description ?? null, format ?? null, startingLife ?? null,
       startTime ?? null, endTime ?? null, isTeamMatch !== undefined ? (isTeamMatch ? 1 : 0) : null,
       commanderThreshold ?? null, counterThreshold ?? null]
    );
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "MATCH_UPDATE_FAILED", result?.message || "Failed to update match");

    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}

export async function deleteMatchService(matchId: string, userId: string) {
  if (!matchId) throw createError("MISSING_FIELDS", "Match ID is required");

  const connection = await pool.getConnection();
  try {
    await connection.execute("CALL sp_match_delete(?, ?, @out_response)", [matchId, userId]);
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "MATCH_DELETE_FAILED", result?.message || "Failed to delete match");

    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}

export async function sendMatchInviteService(req: any) {
  const inviterId = req.user?.userId;
  const inviterUsername = req.user?.username;
  if (!inviterId) throw createError("UNAUTHORIZED", "User not authenticated");

  const { email, matchId, inviteCode } = req.body;
  if (!email) throw createError("MISSING_FIELDS", "Email is required");
  if (!matchId) throw createError("MISSING_FIELDS", "Match ID is required");
  if (!inviteCode) throw createError("MISSING_FIELDS", "Invite code is required");

  const connection = await pool.getConnection();
  try {
    // Verify the match and invite code belong to this host
    const [codeRows]: any = await connection.execute(
      "SELECT ic.code, m.name as matchName FROM InviteCode ic JOIN `Match` m ON ic.fk_match_connects = m.pk_match WHERE ic.code = ? AND ic.fk_match_connects = ? LIMIT 1",
      [inviteCode, matchId]
    );
    if (!codeRows || codeRows.length === 0) throw createError("INVITE_NOT_FOUND", "Invite code not found for this match");

    const frontendUrl = (process.env.FRONTEND_URL || "http://localhost:5173").split(',')[0].trim().replace(/\/$/, "");
    const joinUrl = `${frontendUrl}/match/join?code=${encodeURIComponent(inviteCode)}`;

    await sendMatchInviteEmail({
      to: email,
      inviterUsername: inviterUsername || "Someone",
      matchName: codeRows[0].matchName || "",
      inviteCode,
      joinUrl,
    });

    return { success: true };
  } finally {
    connection.release();
  }
}