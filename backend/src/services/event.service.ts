import pool from "../config/db.config";
import crypto from "node:crypto";

function createError(code: string, message: string) {
  const error = Object.create(null);
  error.code = code;
  error.message = message;
  return error;
}

export async function createEventService(req: any) {
  const userId = req.user?.userId;
  if (!userId) throw createError("UNAUTHORIZED", "User not authenticated");

  const { name, description } = req.body;
  if (!name || !name.trim()) throw createError("MISSING_FIELDS", "Event name is required");

  const connection = await pool.getConnection();
  try {
    await connection.execute("CALL sp_event_create(?, ?, ?, @out_response)", [
      name.trim(),
      description ?? null,
      userId,
    ]);
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "EVENT_CREATE_FAILED", result?.message || "Failed to create event");
    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}

export async function getEventByIdService(eventId: string, userId: string) {
  if (!eventId) throw createError("MISSING_FIELDS", "Event ID is required");

  const connection = await pool.getConnection();
  try {
    await connection.execute("CALL sp_event_get_by_id(?, @out_response)", [eventId]);
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "EVENT_NOT_FOUND", result?.message || "Event not found");

    // Fetch matches linked to this event
    const [matches]: any = await connection.execute(
      `SELECT
         m.pk_match      AS matchId,
         m.name          AS matchName,
         m.format,
         m.startingLife,
         m.startTime,
         m.endTime,
         m.isTeamMatch,
         m.fk_appUser_creates AS createdBy
       FROM EventMatch em
       JOIN \`Match\` m ON em.fk_match_inEvent = m.pk_match
       WHERE em.fk_event_contains = ?
       ORDER BY m.startTime DESC`,
      [eventId]
    );

    return { success: true, data: { ...result.data, matches } };
  } finally {
    connection.release();
  }
}

export async function getEventsByUserService(userId: string) {
  if (!userId) throw createError("MISSING_FIELDS", "User ID is required");

  const connection = await pool.getConnection();
  try {
    await connection.execute("CALL sp_events_get_by_user(?, @out_response)", [userId]);
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "INTERNAL_SERVER_ERROR", result?.message || "Failed to fetch events");
    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}

export async function updateEventService(eventId: string, userId: string, body: any) {
  if (!eventId) throw createError("MISSING_FIELDS", "Event ID is required");

  const { name, description } = body;
  const connection = await pool.getConnection();
  try {
    await connection.execute("CALL sp_event_update(?, ?, ?, ?, @out_response)", [
      eventId,
      name ?? null,
      description ?? null,
      userId,
    ]);
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "EVENT_UPDATE_FAILED", result?.message || "Failed to update event");
    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}

export async function deleteEventService(eventId: string, userId: string) {
  if (!eventId) throw createError("MISSING_FIELDS", "Event ID is required");

  const connection = await pool.getConnection();
  try {
    await connection.execute("CALL sp_event_delete(?, ?, @out_response)", [eventId, userId]);
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "EVENT_DELETE_FAILED", result?.message || "Failed to delete event");
    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}

export async function addMatchToEventService(eventId: string, matchId: string, userId: string) {
  if (!eventId) throw createError("MISSING_FIELDS", "Event ID is required");
  if (!matchId) throw createError("MISSING_FIELDS", "Match ID is required");

  const connection = await pool.getConnection();
  try {
    await connection.execute("CALL sp_event_match_add(?, ?, ?, @out_response)", [eventId, matchId, userId]);
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "EVENT_MATCH_ADD_FAILED", result?.message || "Failed to add match to event");
    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}

export async function removeMatchFromEventService(eventId: string, matchId: string, userId: string) {
  if (!eventId) throw createError("MISSING_FIELDS", "Event ID is required");
  if (!matchId) throw createError("MISSING_FIELDS", "Match ID is required");

  const connection = await pool.getConnection();
  try {
    await connection.execute("CALL sp_event_match_remove(?, ?, ?, @out_response)", [eventId, matchId, userId]);
    const [rows]: any = await connection.query("SELECT @out_response as result");
    const result = JSON.parse(rows[0].result);
    if (!result?.success) throw createError(result?.code || "EVENT_MATCH_REMOVE_FAILED", result?.message || "Failed to remove match from event");
    return { success: true, data: result.data };
  } finally {
    connection.release();
  }
}

export async function getEventStatsService(eventId: string) {
  if (!eventId) throw createError("MISSING_FIELDS", "Event ID is required");

  const connection = await pool.getConnection();
  try {
    // Fetch all players from all matches in this event, with join to get username
    const [rows]: any = await connection.execute(
      `SELECT
         p.fk_appUser_participates  AS userId,
         au.username,
         COUNT(*)                   AS gamesPlayed,
         SUM(p.isWinner = 1 AND p.finalLife IS NOT NULL) AS wins,
         SUM(p.isWinner = 0 AND p.finalLife IS NOT NULL) AS losses,
         ROUND(AVG(p.placement), 2)                      AS avgPlacement,
         ROUND(AVG(p.finalLife), 2)                      AS avgFinalLife
       FROM EventMatch em
       JOIN Player p ON p.fk_match_isPlayedIn = em.fk_match_inEvent
       LEFT JOIN AppUser au ON au.pk_appUser = p.fk_appUser_participates
       WHERE em.fk_event_contains = ?
         AND p.fk_appUser_participates IS NOT NULL
       GROUP BY p.fk_appUser_participates, au.username
       ORDER BY wins DESC, avgPlacement ASC`,
      [eventId]
    );

    return { success: true, data: rows };
  } finally {
    connection.release();
  }
}
