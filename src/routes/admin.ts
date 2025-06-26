import { Router } from "express";
import { authenticateToken, requireAdmin } from "../middleware/auth";
import { redemptionRateLimit } from "../middleware/rateLimiter";
import {
	getEntitlementTypes,
	createEntitlementType,
	issueEntitlementInstance,
	redeemEntitlement,
} from "../controllers/adminController";

const router = Router();

// All admin routes require authentication and admin role
router.use(authenticateToken, requireAdmin);

router.get("/entitlement-types", getEntitlementTypes);
router.post("/entitlement-types", createEntitlementType);
router.post("/entitlement-instances", issueEntitlementInstance);
router.post("/redeem", redemptionRateLimit, redeemEntitlement);

export default router;
