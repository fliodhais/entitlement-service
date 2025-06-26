#!/bin/bash

BASE_URL="http://localhost:3000"

echo "🧪 Testing Complete Entitlement Service Flow"
echo "============================================"

# Get admin token first
echo "0. Getting admin token..."
ADMIN_LOGIN=$(curl -s -X POST $BASE_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@test.com", "password": "dummy"}')

ADMIN_TOKEN=$(echo $ADMIN_LOGIN | jq -r '.token')

if [ "$ADMIN_TOKEN" = "null" ]; then
  echo "❌ Failed to get admin token. Response: $ADMIN_LOGIN"
  exit 1
fi

echo "✅ Got admin token: ${ADMIN_TOKEN:0:20}..."

# Get user token and ID
echo -e "\n0.5. Getting user credentials..."
USER_LOGIN=$(curl -s -X POST $BASE_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "user@test.com", "password": "dummy"}')

USER_TOKEN=$(echo $USER_LOGIN | jq -r '.token')
USER_ID=$(echo $USER_LOGIN | jq -r '.user.id')

if [ "$USER_TOKEN" = "null" ] || [ "$USER_ID" = "null" ]; then
  echo "❌ Failed to get user credentials. Response: $USER_LOGIN"
  exit 1
fi

echo "✅ Got user token: ${USER_TOKEN:0:20}..."
echo "✅ User ID: $USER_ID"

echo -e "\n1. Creating entitlement type..."
TYPE_RESPONSE=$(curl -s -X POST $BASE_URL/admin/entitlement-types \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "name": "Test Lunch Coupon",
    "description": "Test lunch at cafeteria",
    "redemptionRules": {
      "timeWindows": [{"start": "00:00", "end": "23:59"}],
      "locations": [{"lat": 1.3521, "lng": 103.8198, "radius": 100}]
    }
  }')

TYPE_ID=$(echo $TYPE_RESPONSE | jq -r '.id')

if [ "$TYPE_ID" = "null" ]; then
  echo "❌ Failed to create entitlement type. Response: $TYPE_RESPONSE"
  exit 1
fi

echo "✅ Created type: $TYPE_ID"

echo -e "\n2. Issuing entitlement to user..."
INSTANCE_RESPONSE=$(curl -s -X POST $BASE_URL/admin/entitlement-instances \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "userId": "'$USER_ID'",
    "entitlementTypeId": "'$TYPE_ID'"
  }')

QR_CODE=$(echo $INSTANCE_RESPONSE | jq -r '.qrCode')

if [ "$QR_CODE" = "null" ]; then
  echo "❌ Failed to create entitlement instance. Response: $INSTANCE_RESPONSE"
  exit 1
fi

echo "✅ Issued entitlement with QR: $QR_CODE"

echo -e "\n3. User checking their entitlements..."
USER_ENTITLEMENTS=$(curl -s "$BASE_URL/user/entitlements" \
  -H "Authorization: Bearer $USER_TOKEN")

echo $USER_ENTITLEMENTS | jq '.[0] | {id, status, qrCode, entitlementType: .entitlementType.name}'

echo -e "\n4. Admin redeeming entitlement..."
REDEEM_RESPONSE=$(curl -s -X POST $BASE_URL/admin/redeem \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "qrCode": "'$QR_CODE'",
    "latitude": 1.3521,
    "longitude": 103.8198
  }')

echo $REDEEM_RESPONSE | jq

echo -e "\n5. Checking entitlement status after redemption..."
curl -s "$BASE_URL/user/entitlements" \
  -H "Authorization: Bearer $USER_TOKEN" | jq '.[0] | {status, redemption}'

echo -e "\n6. Testing duplicate redemption (should fail)..."
curl -s -X POST $BASE_URL/admin/redeem \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "qrCode": "'$QR_CODE'",
    "latitude": 1.3521,
    "longitude": 103.8198
  }' | jq

echo -e "\n🎉 Complete flow test finished!"