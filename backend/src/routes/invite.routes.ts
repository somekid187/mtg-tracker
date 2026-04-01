import express from "express";
import asyncHandler from "../middleware/async.middleware";
import { authenticateToken } from "../middleware/auth.middleware";
import {
  sendInvite,
  acceptInvite,
  declineInvite,
  cancelInvite,
  getPendingInvites,
  getInvitesByMatch,
} from "../controllers/invite.controller";

const router = express.Router();

router.post("/", authenticateToken, asyncHandler(sendInvite));
router.get("/pending", authenticateToken, asyncHandler(getPendingInvites));
router.get("/match/:matchId", authenticateToken, asyncHandler(getInvitesByMatch));
router.put("/:id/accept", authenticateToken, asyncHandler(acceptInvite));
router.put("/:id/decline", authenticateToken, asyncHandler(declineInvite));
router.delete("/:id", authenticateToken, asyncHandler(cancelInvite));

export default router;
