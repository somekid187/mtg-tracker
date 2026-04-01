import pool from "../config/db.config";

function createError(code: string, message: string) {
  const error = Object.create(null);
  error.code = code;
  error.message = message;
  return error;
}

export async function createDeckService(req: any) {
  const userId = req.user?.userId;
  if (!userId) throw createError("UNAUTHORIZED", "User not authenticated");

  const { name, commander, description } = req.body;
  if (!name?.trim()) throw createError("MISSING_FIELDS", "Deck name is required");

  const connection = await pool.getConnection();
  try {
    await connection.execute("CALL sp_deck_create(?, ?, ?, ?, @out_response)", [
      name.trim(),
      commander?.trim() || null,
      description?.trim() || null,
      userId,
    ]);
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "DECK_CREATE_FAILED", result?.message || "Failed to create deck");
    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}

export async function getDecksByUserService(userId: string) {
  if (!userId) throw createError("MISSING_FIELDS", "User ID is required");

  const connection = await pool.getConnection();
  try {
    await connection.execute("CALL sp_decks_get_by_user(?, @out_response)", [userId]);
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "INTERNAL_SERVER_ERROR", result?.message || "Failed to fetch decks");
    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}

export async function getDeckByIdService(deckId: string) {
  if (!deckId) throw createError("MISSING_FIELDS", "Deck ID is required");

  const connection = await pool.getConnection();
  try {
    await connection.execute("CALL sp_deck_get_by_id(?, @out_response)", [deckId]);
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "DECK_NOT_FOUND", result?.message || "Deck not found");
    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}

export async function updateDeckService(deckId: string, userId: string, body: any) {
  if (!deckId) throw createError("MISSING_FIELDS", "Deck ID is required");

  const { name, commander, description } = body;
  const connection = await pool.getConnection();
  try {
    await connection.execute("CALL sp_deck_update(?, ?, ?, ?, ?, @out_response)", [
      deckId,
      name?.trim() || null,
      commander?.trim() ?? null,
      description?.trim() ?? null,
      userId,
    ]);
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "DECK_UPDATE_FAILED", result?.message || "Failed to update deck");
    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}

export async function deleteDeckService(deckId: string, userId: string) {
  if (!deckId) throw createError("MISSING_FIELDS", "Deck ID is required");

  const connection = await pool.getConnection();
  try {
    await connection.execute("CALL sp_deck_delete(?, ?, @out_response)", [deckId, userId]);
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "DECK_DELETE_FAILED", result?.message || "Failed to delete deck");
    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}
