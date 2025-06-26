#!/bin/bash

BASE_URL="http://localhost:3000"

echo "🔍 STRESS TESTING Entitlement Service"
echo "===================================="

# Get admin token
echo "Getting admin credentials..."
ADMIN_LOGIN=$(curl -s -X POST $BASE_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@test.com", "password": "dummy"}')

ADMIN_TOKEN=$(echo $ADMIN_LOGIN | jq -r '.token')

if [ "$ADMIN_TOKEN" = "null" ]; then
  echo "❌ Failed to get admin token"
  exit 1
fi

# Get user credentials
echo "Getting user credentials..."
USER_LOGIN=$(curl -s -X POST $BASE_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "user@test.com", "password": "dummy"}')

USER_ID=$(echo $USER_LOGIN | jq -r '.user.id')

if [ "$USER_ID" = "null" ]; then
  echo "❌ Failed to get user ID"
  exit 1
fi

echo "✅ Admin token: ${ADMIN_TOKEN:0:20}..."
echo "✅ User ID: $USER_ID"

echo -e "\nSetting up test data..."

# Create a test entitlement type
TYPE_RESPONSE=$(curl -s -X POST $BASE_URL/admin/entitlement-types \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "name": "Stress Test Coupon",
    "description": "For stress testing",
    "redemptionRules": {
      "timeWindows": [{"start": "12:00", "end": "13:00"}],
      "locations": [{"lat": 1.3521, "lng": 103.8198, "radius": 50}]
    }
  }')

TYPE_ID=$(echo $TYPE_RESPONSE | jq -r '.id')

if [ "$TYPE_ID" = "null" ]; then
  echo "❌ Failed to create test entitlement type"
  exit 1
fi

# Create a test entitlement instance
INSTANCE_RESPONSE=$(curl -s -X POST $BASE_URL/admin/entitlement-instances \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "userId": "'$USER_ID'",
    "entitlementTypeId": "'$TYPE_ID'"
  }')

QR_CODE=$(echo $INSTANCE_RESPONSE | jq -r '.qrCode')

if [ "$QR_CODE" = "null" ]; then
  echo "❌ Failed to create test entitlement instance"
  exit 1
fi

echo "✅ Test setup complete"
echo "✅ Test QR: $QR_CODE"

echo -e "\n1. Testing INVALID QR CODE..."
curl -s -X POST $BASE_URL/admin/redeem \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "qrCode": "INVALID_QR_CODE",
    "latitude": 1.3521,
    "longitude": 103.8198
  }' | jq

echo -e "\n2. Testing WRONG LOCATION (too far)..."
curl -s -X POST $BASE_URL/admin/redeem \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "qrCode": "'$QR_CODE'",
    "latitude": 1.4000,
    "longitude": 103.9000
  }' | jq

echo -e "\n3. Testing MISSING REQUIRED FIELDS..."
curl -s -X POST $BASE_URL/admin/redeem \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{}' | jq

echo -e "\n4. Testing INVALID USER ID for entitlement creation..."
curl -s -X POST $BASE_URL/admin/entitlement-instances \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "userId": "INVALID_USER_ID",
    "entitlementTypeId": "'$TYPE_ID'"
  }' | jq

echo -e "\n5. Testing INVALID ENTITLEMENT TYPE ID..."
curl -s -X POST $BASE_URL/admin/entitlement-instances \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "userId": "'$USER_ID'",
    "entitlementTypeId": "INVALID_TYPE_ID"
  }' | jq

echo -e "\n6. Testing UNAUTHORIZED ACCESS (no token)..."
curl -s -X POST $BASE_URL/admin/redeem \
  -H "Content-Type: application/json" \
  -d '{
    "qrCode": "'$QR_CODE'",
    "latitude": 1.3521,
    "longitude": 103.8198
  }' | jq

echo -e "\n7. Testing MALFORMED JSON..."
curl -s -X POST $BASE_URL/admin/redeem \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{invalid json}' | jq

echo -e "\n🔍 Stress test completed!"