import { Request, Response } from "express";
import jwt from "jsonwebtoken";
import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();
const JWT_SECRET = process.env.JWT_SECRET || "your-secret-key";

export const register = async (req: Request, res: Response) => {
	try {
		const { email, name, role = "USER" } = req.body;

		const existingUser = await prisma.user.findUnique({ where: { email } });

		if (existingUser) {
			return res.status(409).json({
				error: "User already exists",
				user: {
					id: existingUser.id,
					email: existingUser.email,
					name: existingUser.name,
					role: existingUser.role,
				},
			});
		}

		const user = await prisma.user.create({
			data: { email, name, role },
		});

		res.status(201).json({
			message: "User created",
			user: {
				id: user.id,
				email: user.email,
				name: user.name,
				role: user.role,
			},
		});
	} catch (error) {
		console.error("Registration error:", error);
		res.status(500).json({ error: "Registration failed" });
	}
};

export const login = async (req: Request, res: Response) => {
	try {
		const { email } = req.body;

		const user = await prisma.user.findUnique({ where: { email } });

		if (!user) {
			return res.status(401).json({ error: "Invalid credentials" });
		}

		const token = jwt.sign(
			{ userId: user.id, email: user.email, role: user.role },
			JWT_SECRET,
			{ expiresIn: "24h" },
		);

		res.json({
			token,
			user: {
				id: user.id,
				email: user.email,
				name: user.name,
				role: user.role,
			},
		});
	} catch (error) {
		console.error("Login error:", error);
		res.status(500).json({ error: "Login failed" });
	}
};
