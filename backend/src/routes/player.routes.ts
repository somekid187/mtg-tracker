import express from "express";
import asyncHandler from "../middleware/async.middleware";
import { authenticateToken } from "../middleware/auth.middleware";
import {
  createPlayer,
  getPlayerById,
  updatePlayer,
  deletePlayer,
  getPlayersByMatch,
} from "../controllers/player.controller";

const router = express.Router();

router.post("/", authenticateToken, asyncHandler(createPlayer));
router.get("/match/:matchId", authenticateToken, asyncHandler(getPlayersByMatch));
router.get("/:id", authenticateToken, asyncHandler(getPlayerById));
router.put("/:id", authenticateToken, asyncHandler(updatePlayer));
router.delete("/:id", authenticateToken, asyncHandler(deletePlayer));

export default router;
