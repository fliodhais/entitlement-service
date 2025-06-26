import swaggerJsdoc from "swagger-jsdoc";
import swaggerUi from "swagger-ui-express";
import { Prisma } from "@prisma/client"; // Import Prisma

const options = {
	definition: {
		openapi: "3.0.0",
		info: {
			title: "Entitlement Service API",
			version: "1.0.0",
			description: `
        A comprehensive entitlement management system with QR codes and dynamic redemption rules.
        
        ## Features
        - JWT Authentication with role-based access
        - Dynamic redemption rules (time & location)
        - QR code generation and validation
        - Rate limiting protection
        - Comprehensive error handling
        
        ## Getting Started
        1. Register/Login to get JWT token
        2. Use token in Authorization header: \`Bearer <token>\`
        3. Admin users can create entitlement types and redeem
        4. Regular users can view their entitlements
      `,
			contact: {
				name: "API Support",
				email: "support@example.com",
			},
		},
		servers: [
			{
				url: "http://localhost:3000",
				description: "Development server",
			},
		],
		components: {
			securitySchemes: {
				bearerAuth: {
					type: "http",
					scheme: "bearer",
					bearerFormat: "JWT",
					description: "Enter JWT token obtained from login endpoint",
				},
			},
			schemas: {
				User: {
					type: "object",
					properties: {
						id: {
							type: "string",
							example: "cmc08iz370000a7leds2fki68",
						},
						email: {
							type: "string",
							format: "email",
							example: "user@example.com",
						},
						name: { type: "string", example: "John Doe" },
						role: {
							type: "string",
							enum: ["USER", "ADMIN"],
							example: "USER",
						},
						createdAt: { type: "string", format: "date-time" },
					},
				},
				EntitlementType: {
					type: "object",
					properties: {
						id: {
							type: "string",
							example: "cmc08mnkk0000a73voiuehvvo",
						},
						name: { type: "string", example: "Lunch Coupon" },
						description: {
							type: "string",
							example: "Free lunch at cafeteria",
							nullable: true,
						},
						redemptionRules: {
							type: "string",
							example:
								'{"timeWindows": [{"start": "11:00", "end": "14:00"}], "locations": [{"lat": 1.3521, "lng": 103.8198, "radius": 100}]}',
							nullable: true,
						},
						isActive: { type: "boolean", example: true },
						createdAt: { type: "string", format: "date-time" },
						createdBy: {
							type: "string",
							example: "cmc08iz370000a7leds2fki68",
						},
					},
				},
				EntitlementInstance: {
					type: "object",
					properties: {
						id: {
							type: "string",
							example: "cmc08qvlw0005a73v7aqofdw9",
						},
						userId: {
							type: "string",
							example: "cmc08iz380001a7legmw50hly",
						},
						entitlementTypeId: {
							type: "string",
							example: "cmc08mnkk0000a73voiuehvvo",
						},
						status: {
							type: "string",
							enum: ["ACTIVE", "REDEEMED", "EXPIRED"],
							example: "ACTIVE",
						},
						qrCode: {
							type: "string",
							example: "ENT_1750147689092_imaytfsgw",
						},
						issuedAt: { type: "string", format: "date-time" },
						expiresAt: {
							type: "string",
							format: "date-time",
							nullable: true,
						},
					},
				},
				Redemption: {
					type: "object",
					properties: {
						id: { type: "string" },
						entitlementInstanceId: { type: "string" },
						redeemedAt: { type: "string", format: "date-time" },
						redeemedBy: { type: "string" },
						latitude: { type: "number", nullable: true },
						longitude: { type: "number", nullable: true },
					},
				},
				Error: {
					type: "object",
					properties: {
						error: { type: "string" },
						message: { type: "string" },
					},
				},
				ValidationError: {
					type: "object",
					properties: {
						error: { type: "string", example: "Validation failed" },
						details: {
							type: "array",
							items: {
								type: "object",
								properties: {
									field: { type: "string", example: "email" },
									message: {
										type: "string",
										example: "Invalid email format",
									},
								},
							},
						},
					},
				},
				RedemptionError: {
					type: "object",
					properties: {
						error: {
							type: "string",
							example: "Redemption not allowed at this time",
						},
						allowedTimes: {
							type: "array",
							items: {
								type: "object",
								properties: {
									start: { type: "string" },
									end: { type: "string" },
								},
							},
						},
						allowedLocations: {
							type: "array",
							items: {
								type: "object",
								properties: {
									lat: { type: "number" },
									lng: { type: "number" },
									radius: { type: "number" },
								},
							},
						},
					},
				},
			},
		},
		tags: [
			{
				name: "Authentication",
				description: "User registration and login",
			},
			{ name: "Admin", description: "Admin-only operations" },
			{ name: "User", description: "User operations" },
			{ name: "System", description: "Health and debug endpoints" },
		],
	},
	apis: ["./src/routes/*.ts", "./src/docs/*.ts"],
};

const specs = swaggerJsdoc(options);

export { specs, swaggerUi };
