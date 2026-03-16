import express from "express";
import asyncHandler from "../middleware/async.middleware";
import { authenticateToken } from "../middleware/auth.middleware";
import { getUserProfile, updateUserProfile, deleteUserProfile, changePassword, requestPasswordReset } from "../controllers/user.controller";
import { request } from "node:http";

const router = express.Router();

router.get("/profile", authenticateToken, getUserProfile);
router.put("/profile", authenticateToken, updateUserProfile);
router.delete("/profile", authenticateToken, deleteUserProfile);
router.post("/password", changePassword);
router.post("/password/reset", requestPasswordReset);

export default router;