import jwt from "jsonwebtoken";
import { Request, Response, NextFunction } from "express";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();
const JWT_SECRET = process.env.JWT_SECRET || "your-secret-key";

export interface AuthRequest extends Request {
	user?: {
		id: string;
		email: string;
		role: string;
	};
}

export const authenticateToken = async (
	req: AuthRequest,
	res: Response,
	next: NextFunction,
) => {
	const authHeader = req.headers["authorization"];
	const token = authHeader && authHeader.split(" ")[1]; // Bearer TOKEN

	if (!token) {
		return res.status(401).json({ error: "Access token required" });
	}

	try {
		const decoded = jwt.verify(token, JWT_SECRET) as any;

		// Verify user still exists
		const user = await prisma.user.findUnique({
			where: { id: decoded.userId },
		});

		if (!user) {
			return res.status(401).json({ error: "Invalid token" });
		}

		req.user = {
			id: user.id,
			email: user.email,
			role: user.role,
		};

		next();
	} catch (error) {
		return res.status(403).json({ error: "Invalid or expired token" });
	}
};

export const requireAdmin = (
	req: AuthRequest,
	res: Response,
	next: NextFunction,
) => {
	if (!req.user || req.user.role !== "ADMIN") {
		return res.status(403).json({ error: "Admin access required" });
	}
	next();
};

export const requireUser = (
	req: AuthRequest,
	res: Response,
	next: NextFunction,
) => {
	if (!req.user) {
		return res.status(401).json({ error: "Authentication required" });
	}
	next();
};
