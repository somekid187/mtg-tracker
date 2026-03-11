import express from "express";
import asyncHandler from "../middleware/async.middleware";
import { register, login, token } from "../controllers/auth.controller";

const router = express.Router();

router.post("/register", asyncHandler(register));
router.post("/login", asyncHandler(login));
router.post("/token", asyncHandler(token));