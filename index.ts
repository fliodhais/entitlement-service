import { app, prisma } from "./src/app";

const PORT = 3000;

app.listen(PORT, () => {
	console.log(`🚀 Server running on http://localhost:${PORT}`);
	console.log(`📚 API Documentation: http://localhost:${PORT}/api-docs`);
	console.log(`📄 OpenAPI Spec: http://localhost:${PORT}/api-docs.json`);
});

process.on("SIGINT", async () => {
	await prisma.$disconnect();
	process.exit(0);
});
