import { Response } from "express";
import { PrismaClient } from "@prisma/client";
import { AuthRequest } from "../middleware/auth";
import { EntitlementStatus } from "../utils/stateMachine";

const prisma = new PrismaClient();

export const getUserEntitlements = async (req: AuthRequest, res: Response) => {
	try {
		const entitlements = await prisma.entitlementInstance.findMany({
			where: { userId: req.user!.id },
			include: {
				entitlementType: {
					select: {
						id: true,
						name: true,
						description: true,
						redemptionRules: true,
					},
				},
				redemption: {
					select: {
						id: true,
						redeemedAt: true,
						redeemedBy: true,
					},
				},
			},
			orderBy: { issuedAt: "desc" },
		});

		// Auto-activate ISSUED entitlements on first view
		const toActivate = entitlements.filter(
			(e) => e.status === EntitlementStatus.ISSUED,
		);

		if (toActivate.length > 0) {
			await prisma.entitlementInstance.updateMany({
				where: {
					id: { in: toActivate.map((e) => e.id) },
					status: EntitlementStatus.ISSUED,
				},
				data: {
					status: EntitlementStatus.ACTIVE,
					activatedAt: new Date(),
				},
			});
		}

		// Refetch with updated statuses
		const updatedEntitlements = await prisma.entitlementInstance.findMany({
			where: { userId: req.user!.id },
			include: {
				entitlementType: {
					select: {
						id: true,
						name: true,
						description: true,
						redemptionRules: true,
					},
				},
				redemption: {
					select: {
						id: true,
						redeemedAt: true,
						redeemedBy: true,
					},
				},
			},
			orderBy: { issuedAt: "desc" },
		});

		// Parse redemption rules and format response
		const formatted = updatedEntitlements.map((ent) => ({
			...ent,
			entitlementType: {
				...ent.entitlementType,
				redemptionRules: ent.entitlementType.redemptionRules
					? JSON.parse(ent.entitlementType.redemptionRules)
					: null,
			},
		}));

		res.json(formatted);
	} catch (error) {
		console.error("Error fetching user entitlements:", error);
		res.status(500).json({ error: "Failed to fetch entitlements" });
	}
};
