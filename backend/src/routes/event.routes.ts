import express from "express";
import asyncHandler from "../middleware/async.middleware";
import { authenticateToken } from "../middleware/auth.middleware";
import {
  createEvent,
  getEventById,
  getMyEvents,
  updateEvent,
  deleteEvent,
  addMatchToEvent,
  removeMatchFromEvent,
  getEventStats,
} from "../controllers/event.controller";

const router = express.Router();

router.post("/", authenticateToken, asyncHandler(createEvent));
router.get("/", authenticateToken, asyncHandler(getMyEvents));
router.get("/:id", authenticateToken, asyncHandler(getEventById));
router.put("/:id", authenticateToken, asyncHandler(updateEvent));
router.delete("/:id", authenticateToken, asyncHandler(deleteEvent));
router.post("/:id/match", authenticateToken, asyncHandler(addMatchToEvent));
router.delete("/:id/match/:matchId", authenticateToken, asyncHandler(removeMatchFromEvent));
router.get("/:id/stats", authenticateToken, asyncHandler(getEventStats));

export default router;
