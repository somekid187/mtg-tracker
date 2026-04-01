import pool from "../config/db.config";

function createError(code: string, message: string) {
  const error = Object.create(null);
  error.code = code;
  error.message = message;
  return error;
}

export async function sendInviteService(req: any) {
  const inviterId = req.user?.userId;
  if (!inviterId) throw createError("UNAUTHORIZED", "User not authenticated");

  const { fk_player_isInvited, fk_match_hosts } = req.body;
  if (!fk_player_isInvited || !fk_match_hosts)
    throw createError("MISSING_FIELDS", "Invitee ID and match ID are required");

  const connection = await pool.getConnection();
  try {
    await connection.execute(
      "CALL sp_invite_send(?, ?, ?, @out_response)",
      [inviterId, fk_player_isInvited, fk_match_hosts]
    );
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "INVITE_SEND_FAILED", result?.message || "Failed to send invite");
    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}

export async function acceptInviteService(req: any) {
  const userId = req.user?.userId;
  if (!userId) throw createError("UNAUTHORIZED", "User not authenticated");

  const { id } = req.params;
  if (!id) throw createError("MISSING_FIELDS", "Invite ID is required");

  const connection = await pool.getConnection();
  try {
    await connection.execute(
      "CALL sp_invite_accept(?, ?, @out_response)",
      [id, userId]
    );
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "INVITE_ACCEPT_FAILED", result?.message || "Failed to accept invite");
    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}

export async function declineInviteService(req: any) {
  const userId = req.user?.userId;
  if (!userId) throw createError("UNAUTHORIZED", "User not authenticated");

  const { id } = req.params;
  if (!id) throw createError("MISSING_FIELDS", "Invite ID is required");

  const connection = await pool.getConnection();
  try {
    await connection.execute(
      "CALL sp_invite_decline(?, ?, @out_response)",
      [id, userId]
    );
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "INVITE_DECLINE_FAILED", result?.message || "Failed to decline invite");
    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}

export async function cancelInviteService(req: any) {
  const userId = req.user?.userId;
  if (!userId) throw createError("UNAUTHORIZED", "User not authenticated");

  const { id } = req.params;
  if (!id) throw createError("MISSING_FIELDS", "Invite ID is required");

  const connection = await pool.getConnection();
  try {
    await connection.execute(
      "CALL sp_invite_cancel(?, ?, @out_response)",
      [id, userId]
    );
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "INVITE_CANCEL_FAILED", result?.message || "Failed to cancel invite");
    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}

export async function getPendingInvitesService(req: any) {
  const userId = req.user?.userId;
  if (!userId) throw createError("UNAUTHORIZED", "User not authenticated");

  const connection = await pool.getConnection();
  try {
    await connection.execute(
      "CALL sp_invites_get_pending(?, @out_response)",
      [userId]
    );
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "INVITE_FETCH_FAILED", result?.message || "Failed to fetch pending invites");
    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}

export async function getInvitesByMatchService(req: any) {
  const userId = req.user?.userId;
  if (!userId) throw createError("UNAUTHORIZED", "User not authenticated");

  const { matchId } = req.params;
  if (!matchId) throw createError("MISSING_FIELDS", "Match ID is required");

  const connection = await pool.getConnection();
  try {
    await connection.execute(
      "CALL sp_invites_get_by_match(?, ?, @out_response)",
      [matchId, userId]
    );
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "INVITE_FETCH_FAILED", result?.message || "Failed to fetch match invites");
    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}
