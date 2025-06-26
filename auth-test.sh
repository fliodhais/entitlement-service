#!/bin/bash

BASE_URL="http://localhost:3000"

echo "🔐 Testing JWT Authentication Flow"
echo "================================="

# Test registration (might fail if users already exist - that's ok)
echo "1. Attempting to register admin user..."
ADMIN_REG=$(curl -s -X POST $BASE_URL/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@test.com",
    "name": "Test Admin",
    "role": "ADMIN"
  }')

echo $ADMIN_REG | jq

echo -e "\n2. Attempting to register regular user..."
USER_REG=$(curl -s -X POST $BASE_URL/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@test.com",
    "name": "Test User",
    "role": "USER"
  }')

echo $USER_REG | jq

# Login as admin
echo -e "\n3. Logging in as admin..."
ADMIN_LOGIN=$(curl -s -X POST $BASE_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@test.com",
    "password": "dummy"
  }')

ADMIN_TOKEN=$(echo $ADMIN_LOGIN | jq -r '.token')
ADMIN_ID=$(echo $ADMIN_LOGIN | jq -r '.user.id')

if [ "$ADMIN_TOKEN" = "null" ]; then
  echo "❌ Failed to get admin token"
  exit 1
fi

echo "✅ Admin token: ${ADMIN_TOKEN:0:20}..."
echo "✅ Admin ID: $ADMIN_ID"

# Login as user
echo -e "\n4. Logging in as user..."
USER_LOGIN=$(curl -s -X POST $BASE_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@test.com",
    "password": "dummy"
  }')

USER_TOKEN=$(echo $USER_LOGIN | jq -r '.token')
USER_ID=$(echo $USER_LOGIN | jq -r '.user.id')

if [ "$USER_TOKEN" = "null" ]; then
  echo "❌ Failed to get user token"
  exit 1
fi

echo "✅ User token: ${USER_TOKEN:0:20}..."
echo "✅ User ID: $USER_ID"

# Test protected admin route
echo -e "\n5. Creating entitlement type (admin only)..."
TYPE_RESPONSE=$(curl -s -X POST $BASE_URL/admin/entitlement-types \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "name": "JWT Test Coupon",
    "description": "Test with JWT auth"
  }')

echo $TYPE_RESPONSE | jq

echo -e "\n6. Testing user access to admin route (should fail)..."
curl -s -X POST $BASE_URL/admin/entitlement-types \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $USER_TOKEN" \
  -d '{
    "name": "Should Fail",
    "description": "User trying admin route"
  }' | jq

echo -e "\n7. Testing invalid token..."
curl -s -X POST $BASE_URL/admin/entitlement-types \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer INVALID_TOKEN" \
  -d '{
    "name": "Should Fail",
    "description": "Invalid token test"
  }' | jq

echo -e "\n8. Testing no authorization header..."
curl -s -X POST $BASE_URL/admin/entitlement-types \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Should Fail",
    "description": "No auth header test"
  }' | jq

echo -e "\n9. Testing user accessing their own entitlements..."
curl -s "$BASE_URL/user/entitlements" \
  -H "Authorization: Bearer $USER_TOKEN" | jq

echo -e "\n🎉 JWT Auth test complete!"