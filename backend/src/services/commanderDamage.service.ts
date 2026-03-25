import pool from "../config/db.config";

function createError(code: string, message: string) {
  const error = Object.create(null);
  error.code = code;
  error.message = message;
  return error;
}

export async function createCommanderDamageService(req: any) {
  const { damageAmount, isLethal, fk_player_deals, fk_player_receives, fk_match_refersTo } = req.body;

  if (!fk_match_refersTo) throw createError("MISSING_FIELDS", "Match ID is required");
  if (fk_player_deals === undefined || fk_player_deals === null) throw createError("MISSING_FIELDS", "Dealing player ID is required");
  if (fk_player_receives === undefined || fk_player_receives === null) throw createError("MISSING_FIELDS", "Receiving player ID is required");

  const connection = await pool.getConnection();
  try {
    await connection.execute(
      "CALL sp_commanderDamage_create(?, ?, ?, ?, ?, @out_response)",
      [damageAmount ?? 0, isLethal ? 1 : 0, fk_player_deals, fk_player_receives, fk_match_refersTo]
    );
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "COMMANDER_DAMAGE_CREATE_FAILED", result?.message || "Failed to create commander damage");
    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}

export async function getCommanderDamageByIdService(id: string) {
  if (!id) throw createError("MISSING_FIELDS", "Commander damage ID is required");
  const connection = await pool.getConnection();
  try {
    await connection.execute("CALL sp_commanderDamage_get_by_id(?, @out_response)", [id]);
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "COMMANDER_DAMAGE_NOT_FOUND", result?.message || "Commander damage record not found");
    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}

export async function updateCommanderDamageService(id: string, body: any) {
  if (!id) throw createError("MISSING_FIELDS", "Commander damage ID is required");
  const { damageAmount, isLethal, fk_player_deals, fk_player_receives, fk_match_refersTo } = body;

  const connection = await pool.getConnection();
  try {
    await connection.execute(
      "CALL sp_commanderDamage_update(?, ?, ?, ?, ?, ?, @out_response)",
      [id, damageAmount ?? null, isLethal !== undefined ? (isLethal ? 1 : 0) : null,
       fk_player_deals ?? null, fk_player_receives ?? null, fk_match_refersTo ?? null]
    );
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "COMMANDER_DAMAGE_UPDATE_FAILED", result?.message || "Failed to update commander damage");
    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}

export async function deleteCommanderDamageService(id: string) {
  if (!id) throw createError("MISSING_FIELDS", "Commander damage ID is required");
  const connection = await pool.getConnection();
  try {
    await connection.execute("CALL sp_commanderDamage_delete(?, @out_response)", [id]);
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "COMMANDER_DAMAGE_DELETE_FAILED", result?.message || "Failed to delete commander damage");
    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}

export async function getCommanderDamageByMatchService(matchId: string) {
  if (!matchId) throw createError("MISSING_FIELDS", "Match ID is required");
  const connection = await pool.getConnection();
  try {
    const [rows]: any = await connection.execute(
      `SELECT cd.*,
        pd.fk_appUser_participates as dealerUserId, pd.fk_guest_enters as dealerGuestId,
        pr.fk_appUser_participates as receiverUserId, pr.fk_guest_enters as receiverGuestId
       FROM CommanderDamage cd
       LEFT JOIN Player pd ON cd.fk_player_deals = pd.pk_player
       LEFT JOIN Player pr ON cd.fk_player_receives = pr.pk_player
       WHERE cd.fk_match_refersTo = ?`,
      [matchId]
    );
    return { success: true, data: rows };
  } finally {
    connection.release();
  }
}
