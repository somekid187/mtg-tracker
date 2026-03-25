import express from "express";
import asyncHandler from "../middleware/async.middleware";
import { authenticateToken } from "../middleware/auth.middleware";
import {
  createGuest,
  getGuestById,
  updateGuest,
  deleteGuest,
} from "../controllers/guest.controller";

const router = express.Router();

// Guests can be created without auth (host creates them on behalf)
router.post("/", authenticateToken, asyncHandler(createGuest));
router.get("/:id", authenticateToken, asyncHandler(getGuestById));
router.put("/:id", authenticateToken, asyncHandler(updateGuest));
router.delete("/:id", authenticateToken, asyncHandler(deleteGuest));

export default router;
