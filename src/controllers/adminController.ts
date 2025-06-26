import { Response } from "express";
import { PrismaClient } from "@prisma/client";
import { AuthRequest } from "../middleware/auth";
import {
	validateStatusTransition,
	EntitlementStatus,
} from "../utils/stateMachine";

const prisma = new PrismaClient();

export const getEntitlementTypes = async (req: AuthRequest, res: Response) => {
	try {
		const entitlementTypes = await prisma.entitlementType.findMany({
			where: { isActive: true },
			orderBy: { createdAt: "desc" },
		});

		const formatted = entitlementTypes.map((type) => ({
			...type,
			redemptionRules: type.redemptionRules
				? JSON.parse(type.redemptionRules)
				: null,
		}));

		res.json(formatted);
	} catch (error) {
		console.error("Error fetching entitlement types:", error);
		res.status(500).json({ error: "Failed to fetch entitlement types" });
	}
};

export const createEntitlementType = async (
	req: AuthRequest,
	res: Response,
) => {
	try {
		const { name, description, redemptionRules } = req.body;

		const entitlementType = await prisma.entitlementType.create({
			data: {
				name,
				description,
				redemptionRules: redemptionRules
					? JSON.stringify(redemptionRules)
					: null,
				createdBy: req.user!.id,
			},
		});

		res.status(201).json(entitlementType);
	} catch (error) {
		console.error("Error creating entitlement type:", error);
		res.status(500).json({ error: "Failed to create entitlement type" });
	}
};

export const issueEntitlementInstance = async (
	req: AuthRequest,
	res: Response,
) => {
	try {
		const { userId, entitlementTypeId, expiresAt } = req.body;

		// Verify entitlement type exists
		const entitlementType = await prisma.entitlementType.findUnique({
			where: { id: entitlementTypeId },
		});

		if (!entitlementType || !entitlementType.isActive) {
			return res
				.status(404)
				.json({ error: "Entitlement type not found or inactive" });
		}

		// Verify user exists
		const user = await prisma.user.findUnique({
			where: { id: userId },
		});

		if (!user) {
			return res.status(404).json({ error: "User not found" });
		}

		// Generate unique QR code
		const qrCode = `ENT_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

		const entitlementInstance = await prisma.entitlementInstance.create({
			data: {
				userId,
				entitlementTypeId,
				qrCode,
				expiresAt: expiresAt ? new Date(expiresAt) : null,
			},
			include: {
				user: { select: { id: true, name: true, email: true } },
				entitlementType: {
					select: { id: true, name: true, description: true },
				},
			},
		});

		res.status(201).json(entitlementInstance);
	} catch (error) {
		console.error("Error creating entitlement instance:", error);
		res.status(500).json({
			error: "Failed to create entitlement instance",
		});
	}
};

export const redeemEntitlement = async (req: AuthRequest, res: Response) => {
	try {
		const { qrCode, latitude, longitude } = req.body;

		if (!qrCode) {
			return res.status(400).json({ error: "qrCode is required" });
		}

		// Find entitlement by QR code
		const entitlement = await prisma.entitlementInstance.findUnique({
			where: { qrCode },
			include: {
				entitlementType: true,
				redemption: true,
			},
		});

		if (!entitlement) {
			return res.status(404).json({ error: "Invalid QR code" });
		}

		// Check if already redeemed
		if (entitlement.redemption) {
			return res.status(400).json({
				error: "Entitlement already redeemed",
				redeemedAt: entitlement.redemption.redeemedAt,
			});
		}

		// Check if expired
		if (entitlement.expiresAt && new Date() > entitlement.expiresAt) {
			// Auto-transition to expired if not already
			if (entitlement.status !== EntitlementStatus.EXPIRED) {
				await prisma.entitlementInstance.update({
					where: { id: entitlement.id },
					data: { status: EntitlementStatus.EXPIRED },
				});
			}
			return res.status(400).json({ error: "Entitlement has expired" });
		}

		// Validate state transition
		if (
			!validateStatusTransition(
				entitlement.status,
				EntitlementStatus.REDEEMED,
			)
		) {
			return res.status(400).json({
				error: `Cannot redeem entitlement in ${entitlement.status} status`,
			});
		}

		// Validate redemption rules
		if (entitlement.entitlementType.redemptionRules) {
			const rules = JSON.parse(
				entitlement.entitlementType.redemptionRules,
			);

			// Time validation
			if (rules.timeWindows) {
				const now = new Date();
				const currentTime = now.toTimeString().slice(0, 5); // HH:MM format

				const isValidTime = rules.timeWindows.some((window: any) => {
					return (
						currentTime >= window.start && currentTime <= window.end
					);
				});

				if (!isValidTime) {
					return res.status(400).json({
						error: "Redemption not allowed at this time",
						allowedTimes: rules.timeWindows,
					});
				}
			}

			// Location validation
			if (rules.locations && latitude && longitude) {
				const { getDistance } = await import("geolib");

				const isValidLocation = rules.locations.some(
					(location: any) => {
						const distance = getDistance(
							{ latitude, longitude },
							{ latitude: location.lat, longitude: location.lng },
						);
						return distance <= location.radius;
					},
				);

				if (!isValidLocation) {
					return res.status(400).json({
						error: "Redemption not allowed at this location",
						allowedLocations: rules.locations,
					});
				}
			}
		}

		// Create redemption record and update entitlement status
		const [redemption] = await prisma.$transaction([
			prisma.redemption.create({
				data: {
					entitlementInstanceId: entitlement.id,
					redeemedBy: req.user!.id,
					latitude,
					longitude,
				},
			}),
			prisma.entitlementInstance.update({
				where: { id: entitlement.id },
				data: { status: EntitlementStatus.REDEEMED },
			}),
		]);

		res.json({
			success: true,
			redemption,
			message: "Entitlement redeemed successfully",
		});
	} catch (error) {
		console.error("Error redeeming entitlement:", error);
		res.status(500).json({ error: "Failed to redeem entitlement" });
	}
};
