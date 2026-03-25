import pool from "../config/db.config";

function createError(code: string, message: string) {
  const error = Object.create(null);
  error.code = code;
  error.message = message;
  return error;
}

export async function createGuestService(req: any) {
  const { guestName } = req.body;
  if (!guestName) throw createError("MISSING_FIELDS", "Guest name is required");

  const connection = await pool.getConnection();
  try {
    await connection.execute("CALL sp_guest_create(?, @out_response)", [guestName]);
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "GUEST_CREATE_FAILED", result?.message || "Failed to create guest");
    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}

export async function getGuestByIdService(id: string) {
  if (!id) throw createError("MISSING_FIELDS", "Guest ID is required");
  const connection = await pool.getConnection();
  try {
    await connection.execute("CALL sp_guest_get_by_id(?, @out_response)", [id]);
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "GUEST_NOT_FOUND", result?.message || "Guest not found");
    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}

export async function updateGuestService(id: string, body: any) {
  if (!id) throw createError("MISSING_FIELDS", "Guest ID is required");
  const { guestName } = body;
  if (!guestName) throw createError("MISSING_FIELDS", "Guest name is required");

  const connection = await pool.getConnection();
  try {
    await connection.execute("CALL sp_guest_update(?, ?, @out_response)", [id, guestName]);
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "GUEST_UPDATE_FAILED", result?.message || "Failed to update guest");
    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}

export async function deleteGuestService(id: string) {
  if (!id) throw createError("MISSING_FIELDS", "Guest ID is required");
  const connection = await pool.getConnection();
  try {
    await connection.execute("CALL sp_guest_delete(?, @out_response)", [id]);
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "GUEST_DELETE_FAILED", result?.message || "Failed to delete guest");
    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}
