import pool from "../config/db.config";

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
