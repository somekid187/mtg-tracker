import express from "express";
import asyncHandler from "../middleware/async.middleware";
import { authenticateToken } from "../middleware/auth.middleware";
import {
  createInviteCode,
  getInviteCodeById,
  getInviteCodeByCode,
  expireInviteCode,
  deleteInviteCode,
  getInviteCodesByMatch,
} from "../controllers/inviteCode.controller";

const router = express.Router();

router.post("/", authenticateToken, asyncHandler(createInviteCode));
router.get("/match/:matchId", authenticateToken, asyncHandler(getInviteCodesByMatch));
router.get("/code/:code", asyncHandler(getInviteCodeByCode));   // public — used for join link validation
router.get("/:id", authenticateToken, asyncHandler(getInviteCodeById));
router.put("/:id/expire", authenticateToken, asyncHandler(expireInviteCode));
router.delete("/:id", authenticateToken, asyncHandler(deleteInviteCode));

export default router;
