/**
 * @swagger
 * /auth/register:
 *   post:
 *     summary: Register a new user
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - name
 *               - role
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *                 example: "user@example.com"
 *               name:
 *                 type: string
 *                 example: "John Doe"
 *               role:
 *                 type: string
 *                 enum: [USER, ADMIN]
 *                 example: "USER"
 *     responses:
 *       201:
 *         description: User registered successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 message:
 *                   type: string
 *                   example: "User registered successfully"
 *                 user:
 *                   $ref: '#/components/schemas/User'
 *       400:
 *         description: User already exists or validation error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */

/**
 * @swagger
 * /auth/login:
 *   post:
 *     summary: Login user
 *     tags: [Authentication]
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - email
 *               - password
 *             properties:
 *               email:
 *                 type: string
 *                 format: email
 *                 example: "user@example.com"
 *               password:
 *                 type: string
 *                 example: "dummy"
 *                 description: "Currently accepts any password (development mode)"
 *     responses:
 *       200:
 *         description: Login successful
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 token:
 *                   type: string
 *                   example: "eyJhbGciOiJIUzI1NiIs..."
 *                 user:
 *                   $ref: '#/components/schemas/User'
 *       401:
 *         description: Invalid credentials
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/Error'
 */

/**
 * @swagger
 * /admin/entitlement-types:
 *   post:
 *     summary: Create a new entitlement type
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - name
 *               - description
 *             properties:
 *               name:
 *                 type: string
 *                 example: "Lunch Coupon"
 *               description:
 *                 type: string
 *                 example: "Free lunch at cafeteria"
 *               redemptionRules:
 *                 $ref: '#/components/schemas/RedemptionRules'
 *           examples:
 *             basic:
 *               summary: Basic coupon with time and location
 *               value:
 *                 name: "Lunch Coupon"
 *                 description: "Free lunch at cafeteria"
 *                 redemptionRules:
 *                   timeWindows:
 *                     - start: "11:00"
 *                       end: "14:00"
 *                   locations:
 *                     - lat: 1.3521
 *                       lng: 103.8198
 *                       radius: 100
 *             flexible:
 *               summary: Flexible coupon (no restrictions)
 *               value:
 *                 name: "Flexible Coupon"
 *                 description: "No restrictions"
 *                 redemptionRules: null
 *             timeOnly:
 *               summary: Time-only restriction
 *               value:
 *                 name: "Business Hours Coupon"
 *                 description: "Valid during business hours only"
 *                 redemptionRules:
 *                   timeWindows:
 *                     - start: "09:00"
 *                       end: "17:00"
 *             multiWindow:
 *               summary: Multiple time windows
 *               value:
 *                 name: "Meal Coupon"
 *                 description: "Valid during meal times"
 *                 redemptionRules:
 *                   timeWindows:
 *                     - start: "07:00"
 *                       end: "09:00"
 *                     - start: "11:30"
 *                       end: "14:00"
 *                     - start: "18:00"
 *                       end: "21:00"
 *                   locations:
 *                     - lat: 1.3521
 *                       lng: 103.8198
 *                       radius: 100
 *     responses:
 *       201:
 *         description: Entitlement type created successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/EntitlementType'
 *       400:
 *         description: Validation error
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/ValidationError'
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Admin access required
 */

/**
 * @swagger
 * /admin/entitlement-instances:
 *   post:
 *     summary: Issue an entitlement instance to a user
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - userId
 *               - entitlementTypeId
 *             properties:
 *               userId:
 *                 type: string
 *                 example: "cmc08iz380001a7legmw50hly"
 *               entitlementTypeId:
 *                 type: string
 *                 example: "cmc08mnkk0000a73voiuehvvo"
 *     responses:
 *       201:
 *         description: Entitlement instance created successfully
 *         content:
 *           application/json:
 *             schema:
 *               $ref: '#/components/schemas/EntitlementInstance'
 *       400:
 *         description: User not found or entitlement type not found
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Admin access required
 */

/**
 * @swagger
 * /admin/redeem:
 *   post:
 *     summary: Redeem an entitlement using QR code
 *     tags: [Admin]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - qrCode
 *               - latitude
 *               - longitude
 *             properties:
 *               qrCode:
 *                 type: string
 *                 example: "ENT_1750147689092_imaytfsgw"
 *               latitude:
 *                 type: number
 *                 minimum: -90
 *                 maximum: 90
 *                 example: 1.3521
 *               longitude:
 *                 type: number
 *                 minimum: -180
 *                 maximum: 180
 *                 example: 103.8198
 *     responses:
 *       200:
 *         description: Entitlement redeemed successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success:
 *                   type: boolean
 *                   example: true
 *                 redemption:
 *                   $ref: '#/components/schemas/Redemption'
 *                 message:
 *                   type: string
 *                   example: "Entitlement redeemed successfully"
 *       400:
 *         description: Redemption error (time/location/already redeemed)
 *         content:
 *           application/json:
 *             schema:
 *               oneOf:
 *                 - $ref: '#/components/schemas/RedemptionError'
 *                 - type: object
 *                   properties:
 *                     error:
 *                       type: string
 *                       example: "Invalid QR code"
 *                 - type: object
 *                   properties:
 *                     error:
 *                       type: string
 *                       example: "Entitlement already redeemed"
 *                     redeemedAt:
 *                       type: string
 *                       format: date-time
 *       401:
 *         description: Unauthorized
 *       403:
 *         description: Admin access required
 *       429:
 *         description: Rate limit exceeded
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 error:
 *                   type: string
 *                   example: "Too many redemption attempts, please try again later"
 *                 retryAfter:
 *                   type: string
 *                   example: "1 minute"
 */

/**
 * @swagger
 * /user/entitlements:
 *   get:
 *     summary: Get current user's entitlements
 *     tags: [User]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: List of user's entitlements
 *         content:
 *           application/json:
 *             schema:
 *               type: array
 *               items:
 *                 $ref: '#/components/schemas/EntitlementInstance'
 *       401:
 *         description: Unauthorized
 */

/**
 * @swagger
 * /debug/db-state:
 *   get:
 *     summary: Get current database state (development only)
 *     tags: [Debug]
 *     responses:
 *       200:
 *         description: Current database state
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 users:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/User'
 *                 entitlementTypes:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/EntitlementType'
 *                 entitlementInstances:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/EntitlementInstance'
 *                 redemptions:
 *                   type: array
 *                   items:
 *                     $ref: '#/components/schemas/Redemption'
 *                 counts:
 *                   type: object
 *                   properties:
 *                     users:
 *                       type: number
 *                     entitlementTypes:
 *                       type: number
 *                     entitlementInstances:
 *                       type: number
 *                     redemptions:
 *                       type: number
 */
