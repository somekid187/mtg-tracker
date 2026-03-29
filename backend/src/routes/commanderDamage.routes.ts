import express from "express";
import asyncHandler from "../middleware/async.middleware";
import { authenticateToken } from "../middleware/auth.middleware";
import {
  createCommanderDamage,
  getCommanderDamageById,
  updateCommanderDamage,
  deleteCommanderDamage,
  getCommanderDamageByMatch,
} from "../controllers/commanderDamage.controller";

const router = express.Router();

router.post("/", authenticateToken, asyncHandler(createCommanderDamage));
router.get("/match/:matchId", authenticateToken, asyncHandler(getCommanderDamageByMatch));
router.get("/:id", authenticateToken, asyncHandler(getCommanderDamageById));
router.put("/:id", authenticateToken, asyncHandler(updateCommanderDamage));
router.delete("/:id", authenticateToken, asyncHandler(deleteCommanderDamage));

export default router;
