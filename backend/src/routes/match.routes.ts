import express from "express";
import asyncHandler from "../middleware/async.middleware";
import { authenticateToken } from "../middleware/auth.middleware";
import {
  createMatch,
  joinMatch,
  leaveMatch,
  getMatchById,
  updateMatch,
  deleteMatch,
  sendMatchInvite,
} from "../controllers/match.controller";

const router = express.Router();

router.post("/", authenticateToken, asyncHandler(createMatch));
router.post("/join", authenticateToken, asyncHandler(joinMatch));
router.post("/leave", authenticateToken, asyncHandler(leaveMatch));
router.post("/invite-email", authenticateToken, asyncHandler(sendMatchInvite));
router.get("/:id", authenticateToken, asyncHandler(getMatchById));
router.put("/:id", authenticateToken, asyncHandler(updateMatch));
router.delete("/:id", authenticateToken, asyncHandler(deleteMatch));

export default router;
