import express from "express";
import helmet from "helmet";
import cors from "cors";
import cookieParser from "cookie-parser";
import authRoutes from "./routes/auth.routes";
import userRoutes from "./routes/user.routes";
import errorHandler from "./middleware/error.middleware";

const app = express();

// Security Middleware
// This prevents attacks from web vulnerabilities like XSS, CSRF by setting appropriate HTTP headers.
app.use(helmet());

// CORS Middleware
app.use(cors({ origin: process.env.FRONTEND_URL, credentials: true }));

// Body Parsing
app.use(express.json());
app.use(cookieParser());


// Routes
app.use("/auth", authRoutes);
app.use("/user", userRoutes);

// Health Check Endpoint
app.get('/health', (_req, res) => {
  res.status(200).json({ status: 'ok', timestamp: new Date().toISOString() });
});

app.use(errorHandler);

export default app;