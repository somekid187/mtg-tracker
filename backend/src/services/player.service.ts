import pool from "../config/db.config";

function createError(code: string, message: string) {
  const error = Object.create(null);
  error.code = code;
  error.message = message;
  return error;
}

export async function createPlayerService(req: any) {
  const {
    startingLife, isWinner, tax, placement, killCounter, poisonCounter,
    minPlayers, maxPlayers, fk_guest_enters, fk_appUser_participates,
    fk_team_isIncluded, fk_match_isPlayedIn, fk_deck_uses
  } = req.body;

  if (!startingLife) throw createError("MISSING_FIELDS", "Starting life is required");
  if (placement === undefined || placement === null) throw createError("MISSING_FIELDS", "Placement is required");
  if (!fk_match_isPlayedIn) throw createError("MISSING_FIELDS", "Match ID is required");

  const connection = await pool.getConnection();
  try {
    await connection.execute(
      "CALL sp_player_create(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, @out_response)",
      [startingLife, isWinner ?? 0, tax ?? null, placement, killCounter ?? 0,
       poisonCounter ?? null, minPlayers ?? 2, maxPlayers ?? 6,
       fk_guest_enters ?? null, fk_appUser_participates ?? null,
       fk_team_isIncluded ?? null, fk_match_isPlayedIn, fk_deck_uses ?? null]
    );
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "PLAYER_CREATE_FAILED", result?.message || "Failed to create player");
    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}

export async function getPlayerByIdService(id: string) {
  if (!id) throw createError("MISSING_FIELDS", "Player ID is required");
  const connection = await pool.getConnection();
  try {
    await connection.execute("CALL sp_player_get_by_id(?, @out_response)", [id]);
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "PLAYER_NOT_FOUND", result?.message || "Player not found");
    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}

export async function updatePlayerService(id: string, body: any) {
  if (!id) throw createError("MISSING_FIELDS", "Player ID is required");
  const {
    startingLife, finalLife, isWinner, tax, placement,
    killCounter, poisonCounter, minPlayers, maxPlayers, fk_team_isIncluded
  } = body;
  const connection = await pool.getConnection();
  try {
    await connection.execute(
      "CALL sp_player_update(?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, @out_response)",
      [id, startingLife ?? null, finalLife ?? null,
       isWinner !== undefined ? (isWinner ? 1 : 0) : null,
       tax ?? null, placement ?? null, killCounter ?? null,
       poisonCounter ?? null, minPlayers ?? null, maxPlayers ?? null,
       fk_team_isIncluded ?? null]
    );
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "PLAYER_UPDATE_FAILED", result?.message || "Failed to update player");
    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}

export async function deletePlayerService(id: string) {
  if (!id) throw createError("MISSING_FIELDS", "Player ID is required");
  const connection = await pool.getConnection();
  try {
    await connection.execute("CALL sp_player_delete(?, @out_response)", [id]);
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "PLAYER_DELETE_FAILED", result?.message || "Failed to delete player");
    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}

export async function getPlayersByMatchService(matchId: string) {
  if (!matchId) throw createError("MISSING_FIELDS", "Match ID is required");
  const connection = await pool.getConnection();
  try {
    const [rows]: any = await connection.execute(
      `SELECT p.*, au.username as userName, g.guestName
       FROM Player p
       LEFT JOIN AppUser au ON p.fk_appUser_participates = au.pk_appUser
       LEFT JOIN Guest g ON p.fk_guest_enters = g.pk_guest
       WHERE p.fk_match_isPlayedIn = ?
       ORDER BY p.placement`,
      [matchId]
    );
    return { success: true, data: rows };
  } finally {
    connection.release();
  }
}