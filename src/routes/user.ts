import { Router } from "express";
import { authenticateToken, requireUser } from "../middleware/auth";
import { getUserEntitlements } from "../controllers/userController";

const router = Router();

// All user routes require authentication
router.use(authenticateToken, requireUser);

router.get("/entitlements", getUserEntitlements);

export default router;
