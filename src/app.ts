import express from "express";
import { PrismaClient } from "@prisma/client";
import authRoutes from "./routes/auth";
import adminRoutes from "./routes/admin";
import userRoutes from "./routes/user";
import { specs, swaggerUi } from "./docs/swagger";

const app = express();
const prisma = new PrismaClient();

app.use(express.json());

// Test DB connection
prisma
	.$connect()
	.then(() => console.log("✅ Database connected"))
	.catch((err) => console.error("❌ Database connection failed:", err));

// Swagger Documentation
app.use(
	"/api-docs",
	swaggerUi.serve,
	swaggerUi.setup(specs, {
		explorer: true,
		customCss: ".swagger-ui .topbar { display: none }",
		customSiteTitle: "Entitlement Service API",
		swaggerOptions: {
			persistAuthorization: true,
			displayRequestDuration: true,
			docExpansion: "none",
			filter: true,
			tryItOutEnabled: true,
		},
	}),
);

// Serve OpenAPI spec as JSON
app.get("/api-docs.json", (req, res) => {
	res.setHeader("Content-Type", "application/json");
	res.send(specs);
});

// Routes
app.use("/auth", authRoutes);
app.use("/admin", adminRoutes);
app.use("/user", userRoutes);

// Health and debug routes
app.get("/health", (req, res) => {
	res.json({ status: "ok", timestamp: new Date().toISOString() });
});

app.get("/db", async (req, res) => {
	try {
		const [users, entitlementTypes, entitlementInstances, redemptions] =
			await Promise.all([
				prisma.user.findMany(),
				prisma.entitlementType.findMany(),
				prisma.entitlementInstance.findMany({
					include: {
						user: true,
						entitlementType: true,
						redemption: true,
					},
				}),
				prisma.redemption.findMany({
					include: {
						entitlementInstance: true,
					},
				}),
			]);

		const formattedTypes = entitlementTypes.map((type) => ({
			...type,
			redemptionRules: type.redemptionRules
				? JSON.parse(type.redemptionRules)
				: null,
		}));

		const data = {
			users,
			entitlementTypes: formattedTypes,
			entitlementInstances,
			redemptions,
			counts: {
				users: users.length,
				entitlementTypes: entitlementTypes.length,
				entitlementInstances: entitlementInstances.length,
				redemptions: redemptions.length,
			},
		};

		res.set("Content-Type", "application/json");
		res.send(JSON.stringify(data, null, 2));
	} catch (error) {
		console.error("Error dumping database:", error);
		res.status(500).json({ error: "Failed to dump database" });
	}
});

app.get("/", (req, res) => {
	res.json({ message: "Welcome to the Entitlement Service!" });
});

export { app, prisma };
