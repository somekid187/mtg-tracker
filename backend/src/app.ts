import express from "express";
import helmet from "helmet";
import cors from "cors";
import cookieParser from "cookie-parser";
import authRoutes from "./routes/auth.routes";
import userRoutes from "./routes/user.routes";
import matchRoutes from "./routes/match.routes";
import playerRoutes from "./routes/player.routes";
import guestRoutes from "./routes/guest.routes";
import commanderDamageRoutes from "./routes/commanderDamage.routes";
import inviteCodeRoutes from "./routes/inviteCode.routes";
import errorHandler from "./middleware/error.middleware";

const app = express();

// Security Middleware
app.use(helmet());

// CORS Middleware
app.use(cors({ origin: process.env.FRONTEND_URL, credentials: true }));
console.log(`CORS configured to allow requests from: ${process.env.FRONTEND_URL}`);

// Body Parsing
app.use(express.json());
app.use(cookieParser());

// Routes
app.use("/auth", authRoutes);
app.use("/user", userRoutes);
app.use("/match", matchRoutes);
app.use("/player", playerRoutes);
app.use("/guest", guestRoutes);
app.use("/commander-damage", commanderDamageRoutes);
app.use("/invite-code", inviteCodeRoutes);

// Health Check Endpoint
app.get('/health', (_req, res) => {
  res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.use(errorHandler);

export default app;