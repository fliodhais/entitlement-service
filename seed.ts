import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

async function seed() {
	console.log("🌱 Seeding database...");

	// Create or find admin user
	let admin = await prisma.user.findUnique({
		where: { email: "admin@test.com" },
	});

	if (!admin) {
		admin = await prisma.user.create({
			data: {
				email: "admin@test.com",
				name: "Admin User",
				role: "ADMIN",
			},
		});
		console.log("✅ Created admin user");
	} else {
		console.log("ℹ️  Admin user already exists");
	}

	// Create or find test user
	let user = await prisma.user.findUnique({
		where: { email: "user@test.com" },
	});

	if (!user) {
		user = await prisma.user.create({
			data: {
				email: "user@test.com",
				name: "Test User",
				role: "USER",
			},
		});
		console.log("✅ Created test user");
	} else {
		console.log("ℹ️  Test user already exists");
	}

	// Create sample entitlement type if it doesn't exist
	const existingType = await prisma.entitlementType.findFirst({
		where: { name: "Lunch Coupon" },
	});

	if (!existingType) {
		const lunchType = await prisma.entitlementType.create({
			data: {
				name: "Lunch Coupon",
				description: "Free lunch at cafeteria",
				createdBy: admin.id,
				redemptionRules: JSON.stringify({
					timeWindows: [{ start: "11:00", end: "14:00" }],
					locations: [{ lat: 1.3521, lng: 103.8198, radius: 100 }],
				}),
			},
		});
		console.log("✅ Created lunch coupon type");
	} else {
		console.log("ℹ️  Lunch coupon type already exists");
	}

	console.log("🎉 Seed completed");
}

seed()
	.catch(console.error)
	.finally(() => prisma.$disconnect());
