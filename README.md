# Entitlement Service

The service is designed with production best practices in mind, including JWT authentication, rate limiting, input validation, and comprehensive testing. While it demonstrates a production-ready architecture and covers many core requirements, further enhancements would be needed for a real-world deployment, such as advanced security hardening, operational monitoring, and compliance measures.

## Overview

This service provides a complete solution for issuing, tracking, and redeeming digital entitlements. Administrators can define entitlement types (like "Lunch Coupon" or "Event Ticket"), issue them to users, and manage their lifecycle. Users can view their entitlements, and redemptions are performed securely via QR codes, with configurable validation for time windows and geofenced locations.

## Features

- **Entitlement Management:** Define types, issue to users, and track status.
- **QR Code Redemption:** Secure, one-time use with unique codes.
- **Time & Location Validation:** Flexible rules for when and where entitlements can be redeemed.
- **Duplicate Prevention:** Ensures each entitlement can only be redeemed once.
- **State Machine:** Clear lifecycle states (ISSUED, ACTIVE, REDEEMED, etc.).
- **Role-Based Access:** JWT authentication for admin and user roles.
- **Rate Limiting:** Prevents abuse of redemption endpoints.
- **Comprehensive Error Handling:** Clear status codes and messages.
- **Clean Architecture:** Modular codebase with controllers, routes, and middleware.
- **Persistent Storage:** SQLite database managed with Prisma ORM.
- **Automated Testing:** Includes flow, stress, and authentication tests.
- **API Documentation:** OpenAPI-style docs for all endpoints.
- **Security:** JWT and rate limiting

## Architecture

```bash
src/
├── controllers/   # Business logic
├── routes/        # HTTP routing
├── middleware/    # Auth, rate limiting, etc.
├── utils/         # Pure functions and helpers
└── app.ts         # Application entry point
```

## Tech Stack

- **Runtime:** Bun
- **Framework:** Express.js + TypeScript
- **Database:** SQLite + Prisma ORM
- **Authentication:** JWT
- **Geolocation:** geolib
- **Rate Limiting:** express-rate-limit
- **Testing:** Bash scripts with curl + jq

## Getting Started

### Prerequisites

- Bun installed
- jq installed (for testing)

### Setup

```bash
git clone <repo>
cd entitlement-service
bun install
bunx prisma db push
bun seed
bun dev
```

### Testing

```bash
bun test
bash test.sh        # Core flow
bash stress-test.sh # Edge cases
bash auth-test.sh   # Auth scenarios
```

## API Overview

### Authentication

- `POST /auth/register` – Register a new user
- `POST /auth/login` – Obtain JWT token

### Admin Endpoints (ADMIN role required)

- `GET /admin/entitlement-types` – List entitlement types
- `POST /admin/entitlement-types` – Create a new type
- `POST /admin/entitlement-instances` – Issue to user
- `POST /admin/redeem` – Redeem entitlement (rate limited)

### User Endpoints (USER role required)

- `GET /user/entitlements` – View user’s entitlements

### Utility

- `GET /health` – Health check
- `GET /db` – Database dump (debug)

## Redemption Rules

Redemption can be restricted by time windows and/or geofenced locations. Rules are defined in JSON and validated at redemption.

**Example:**

```json
{
	"redemptionRules": {
		"timeWindows": [{ "start": "11:00", "end": "14:00" }],
		"locations": [{ "lat": 1.3521, "lng": 103.8198, "radius": 100 }]
	}
}
```

- **Time Windows:** Supports multiple periods, 24-hour format, and overnight windows.
- **Location:** Latitude/longitude with radius in meters, supports multiple locations.

## State Machine

Entitlements follow a strict lifecycle:

```
ISSUED → ACTIVE → REDEEMED
   ↓        ↓
CANCELLED   EXPIRED
```

- **ISSUED → ACTIVE:** When user first views
- **ACTIVE → REDEEMED:** On successful redemption
- **ACTIVE → EXPIRED:** On expiration
- **ISSUED/ACTIVE → CANCELLED:** Manual cancellation

## Example Usage

**Create Entitlement Type:**

```bash
curl -X POST http://localhost:3000/admin/entitlement-types \
  -H "Authorization: Bearer <admin_token>" \
  -H "Content-Type: application/json" \
  -d '{ "name": "Lunch Coupon", "description": "Free lunch", "redemptionRules": { "timeWindows": [{ "start": "11:00", "end": "14:00" }], "locations": [{ "lat": 1.3521, "lng": 103.8198, "radius": 100 }] } }'
```

**Issue Entitlement:**

```bash
curl -X POST http://localhost:3000/admin/entitlement-instances \
  -H "Authorization: Bearer <admin_token>" \
  -H "Content-Type: application/json" \
  -d '{ "userId": "user_id", "entitlementTypeId": "type_id" }'
```

**User Views Entitlements:**

```bash
curl -H "Authorization: Bearer <user_token>" \
  http://localhost:3000/user/entitlements
```

**Admin Redeems Entitlement:**

```bash
curl -X POST http://localhost:3000/admin/redeem \
  -H "Authorization: Bearer <admin_token>" \
  -H "Content-Type: application/json" \
  -d '{ "qrCode": "ENT_1234567890_abc123", "latitude": 1.3521, "longitude": 103.8198 }'
```
