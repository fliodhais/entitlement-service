import rateLimit from "express-rate-limit";
import type { AuthRequest } from "./auth";

export const redemptionRateLimit = rateLimit({
	windowMs: 60 * 1000, // 1 minute
	max: 100, // 5 attempts per minute
	message: {
		error: "Too many redemption attempts, please try again later",
		retryAfter: "1 minute",
	},
	standardHeaders: true,
	legacyHeaders: false,
	keyGenerator: (req: AuthRequest) => {
		// Rate limit per user (from JWT token)
		return req.user?.id || req.ip;
	},
});
