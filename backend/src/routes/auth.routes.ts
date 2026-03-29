import express from "express";
import asyncHandler from "../middleware/async.middleware";
import { register, login, refresh, logout, activate } from "../controllers/auth.controller";
import { authenticateToken } from "../middleware/auth.middleware";

const router = express.Router();

router.post("/register", asyncHandler(register));
router.post("/login", asyncHandler(login));
router.post("/refresh", asyncHandler(refresh));
router.post("/logout", authenticateToken, asyncHandler(logout));
router.put("/activate", asyncHandler(activate));
export default router;