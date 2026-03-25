import express from "express";
import asyncHandler from "../middleware/async.middleware";
import { authenticateToken } from "../middleware/auth.middleware";
import {
  getUserProfile, updateUserProfile, deleteUserProfile,
  changePassword, requestPasswordReset,
  sendFriendRequest, acceptFriendRequest, rejectFriendRequest,
  removeFriend, getFriends, getFriendRequests,
} from "../controllers/user.controller";

const router = express.Router();

router.get("/profile", authenticateToken, getUserProfile);
router.put("/profile", authenticateToken, updateUserProfile);
router.delete("/profile", authenticateToken, deleteUserProfile);
router.post("/password", changePassword);
router.post("/password/reset", requestPasswordReset);

// Friends
router.get("/friends", authenticateToken, asyncHandler(getFriends));
router.get("/friends/requests", authenticateToken, asyncHandler(getFriendRequests));
router.post("/friends/request", authenticateToken, asyncHandler(sendFriendRequest));
router.post("/friends/:id/accept", authenticateToken, asyncHandler(acceptFriendRequest));
router.post("/friends/:id/reject", authenticateToken, asyncHandler(rejectFriendRequest));
router.delete("/friends/:id", authenticateToken, asyncHandler(removeFriend));

export default router;