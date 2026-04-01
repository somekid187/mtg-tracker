import { Router } from "express";
import { authenticateToken } from "../middleware/auth.middleware";
import asyncHandler from "../middleware/async.middleware";
import { createDeck, getMyDecks, getDeckById, updateDeck, deleteDeck } from "../controllers/deck.controller";

const router = Router();

router.post("/", authenticateToken, asyncHandler(createDeck));
router.get("/", authenticateToken, asyncHandler(getMyDecks));
router.get("/:id", authenticateToken, asyncHandler(getDeckById));
router.put("/:id", authenticateToken, asyncHandler(updateDeck));
router.delete("/:id", authenticateToken, asyncHandler(deleteDeck));

export default router;
