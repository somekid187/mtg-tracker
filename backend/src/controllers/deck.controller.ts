import { Request, Response } from "express";
import {
  createDeckService,
  getDecksByUserService,
  getDeckByIdService,
  updateDeckService,
  deleteDeckService,
} from "../services/deck.service";

export const createDeck = async (req: Request, res: Response) => {
  const result = await createDeckService(req);
  res.status(201).json({ message: "Deck created successfully", data: result.data });
};

export const getMyDecks = async (req: Request, res: Response) => {
  const userId = (req as any).user?.userId;
  const result = await getDecksByUserService(userId);
  res.status(200).json({ message: "Decks retrieved successfully", data: result.data });
};

export const getDeckById = async (req: Request, res: Response) => {
  const result = await getDeckByIdService(req.params.id);
  res.status(200).json({ message: "Deck retrieved successfully", data: result.data });
};

export const updateDeck = async (req: Request, res: Response) => {
  const userId = (req as any).user?.userId;
  const result = await updateDeckService(req.params.id, userId, req.body);
  res.status(200).json({ message: "Deck updated successfully", data: result.data });
};

export const deleteDeck = async (req: Request, res: Response) => {
  const userId = (req as any).user?.userId;
  const result = await deleteDeckService(req.params.id, userId);
  res.status(200).json({ message: "Deck deleted successfully", data: result.data });
};
