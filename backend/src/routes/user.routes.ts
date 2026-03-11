import express from "express";
import asyncHandler from "../middleware/async.middleware";
import { authenticateToken } from "../middleware/auth.middleware";
import { getUserProfile } from "../controllers/user.controller";

const router = express.Router();

router.get("/profile", authenticateToken, getUserProfile);

export default router;