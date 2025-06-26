#!/bin/bash

BASE_URL="http://localhost:3000"

echo "🎯 Testing Dynamic Redemption Rules"
echo "=================================="

# Get admin and user credentials
echo "Getting credentials..."
ADMIN_LOGIN=$(curl -s -X POST $BASE_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@test.com", "password": "dummy"}')

USER_LOGIN=$(curl -s -X POST $BASE_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "user@test.com", "password": "dummy"}')

ADMIN_TOKEN=$(echo $ADMIN_LOGIN | jq -r '.token')
USER_TOKEN=$(echo $USER_LOGIN | jq -r '.token')
USER_ID=$(echo $USER_LOGIN | jq -r '.user.id')

if [ "$ADMIN_TOKEN" = "null" ] || [ "$USER_ID" = "null" ]; then
  echo "❌ Failed to get credentials"
  exit 1
fi

echo "✅ Credentials obtained"

# Test 1: Time Window Restrictions
echo -e "\n🕐 TEST 1: Time Window Restrictions"
echo "=================================="

# Get current time in HH:MM format
CURRENT_TIME=$(date +"%H:%M")
CURRENT_HOUR=$(date +"%H")
CURRENT_MIN=$(date +"%M")

# Calculate a time window that's NOT current (for testing failure)
if [ "$CURRENT_HOUR" -lt 10 ]; then
  RESTRICTED_START="22:00"
  RESTRICTED_END="23:59"
else
  RESTRICTED_START="02:00"
  RESTRICTED_END="03:00"
fi

echo "Current time: $CURRENT_TIME"
echo "Testing restricted window: $RESTRICTED_START - $RESTRICTED_END"

# Create time-restricted entitlement
TIME_TYPE=$(curl -s -X POST $BASE_URL/admin/entitlement-types \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "name": "Time Restricted Lunch",
    "description": "Only available during specific hours",
    "redemptionRules": {
      "timeWindows": [
        {"start": "'$RESTRICTED_START'", "end": "'$RESTRICTED_END'"}
      ],
      "locations": [
        {"lat": 1.3521, "lng": 103.8198, "radius": 1000}
      ]
    }
  }' | jq -r '.id')

# Issue entitlement
TIME_QR=$(curl -s -X POST $BASE_URL/admin/entitlement-instances \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "userId": "'$USER_ID'",
    "entitlementTypeId": "'$TIME_TYPE'"
  }' | jq -r '.qrCode')

echo "✅ Created time-restricted entitlement: $TIME_QR"

# Try to redeem outside time window (should fail)
echo -e "\n🚫 Attempting redemption outside time window..."
curl -s -X POST $BASE_URL/admin/redeem \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "qrCode": "'$TIME_QR'",
    "latitude": 1.3521,
    "longitude": 103.8198
  }' | jq

# Test 2: Multiple Time Windows
echo -e "\n🕐 TEST 2: Multiple Time Windows"
echo "==============================="

MULTI_TIME_TYPE=$(curl -s -X POST $BASE_URL/admin/entitlement-types \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "name": "Multi-Window Coupon",
    "description": "Available during breakfast and lunch",
    "redemptionRules": {
      "timeWindows": [
        {"start": "07:00", "end": "09:00"},
        {"start": "11:30", "end": "14:00"},
        {"start": "00:00", "end": "23:59"}
      ],
      "locations": [
        {"lat": 1.3521, "lng": 103.8198, "radius": 100}
      ]
    }
  }' | jq -r '.id')

MULTI_TIME_QR=$(curl -s -X POST $BASE_URL/admin/entitlement-instances \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "userId": "'$USER_ID'",
    "entitlementTypeId": "'$MULTI_TIME_TYPE'"
  }' | jq -r '.qrCode')

echo "✅ Created multi-window entitlement: $MULTI_TIME_QR"

# This should succeed (has 00:00-23:59 window)
echo -e "\n✅ Attempting redemption within valid time window..."
curl -s -X POST $BASE_URL/admin/redeem \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "qrCode": "'$MULTI_TIME_QR'",
    "latitude": 1.3521,
    "longitude": 103.8198
  }' | jq

# Test 3: Location Restrictions
echo -e "\n📍 TEST 3: Location Restrictions"
echo "==============================="

LOCATION_TYPE=$(curl -s -X POST $BASE_URL/admin/entitlement-types \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "name": "Location Restricted Coupon",
    "description": "Only at Marina Bay Sands",
    "redemptionRules": {
      "timeWindows": [
        {"start": "00:00", "end": "23:59"}
      ],
      "locations": [
        {"lat": 1.2834, "lng": 103.8607, "radius": 50}
      ]
    }
  }' | jq -r '.id')

LOCATION_QR=$(curl -s -X POST $BASE_URL/admin/entitlement-instances \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "userId": "'$USER_ID'",
    "entitlementTypeId": "'$LOCATION_TYPE'"
  }' | jq -r '.qrCode')

echo "✅ Created location-restricted entitlement: $LOCATION_QR"

# Try to redeem at wrong location (should fail)
echo -e "\n🚫 Attempting redemption at wrong location (Orchard Road)..."
curl -s -X POST $BASE_URL/admin/redeem \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "qrCode": "'$LOCATION_QR'",
    "latitude": 1.3048,
    "longitude": 103.8318
  }' | jq

# Try to redeem at correct location (should succeed)
echo -e "\n✅ Attempting redemption at correct location (Marina Bay Sands)..."
curl -s -X POST $BASE_URL/admin/redeem \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "qrCode": "'$LOCATION_QR'",
    "latitude": 1.2834,
    "longitude": 103.8607
  }' | jq

# Test 4: Multiple Locations
echo -e "\n📍 TEST 4: Multiple Valid Locations"
echo "==================================="

MULTI_LOC_TYPE=$(curl -s -X POST $BASE_URL/admin/entitlement-types \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "name": "Multi-Location Coupon",
    "description": "Valid at multiple outlets",
    "redemptionRules": {
      "timeWindows": [
        {"start": "00:00", "end": "23:59"}
      ],
      "locations": [
        {"lat": 1.3521, "lng": 103.8198, "radius": 100},
        {"lat": 1.2834, "lng": 103.8607, "radius": 100},
        {"lat": 1.3048, "lng": 103.8318, "radius": 100}
      ]
    }
  }' | jq -r '.id')

MULTI_LOC_QR=$(curl -s -X POST $BASE_URL/admin/entitlement-instances \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "userId": "'$USER_ID'",
    "entitlementTypeId": "'$MULTI_LOC_TYPE'"
  }' | jq -r '.qrCode')

echo "✅ Created multi-location entitlement: $MULTI_LOC_QR"

# Test redemption at second valid location
echo -e "\n✅ Attempting redemption at second valid location (Marina Bay)..."
curl -s -X POST $BASE_URL/admin/redeem \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "qrCode": "'$MULTI_LOC_QR'",
    "latitude": 1.2834,
    "longitude": 103.8607
  }' | jq

# Test 5: No Restrictions (Flexible Coupon)
echo -e "\n🆓 TEST 5: No Restrictions"
echo "========================="

FLEXIBLE_TYPE=$(curl -s -X POST $BASE_URL/admin/entitlement-types \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "name": "Flexible Coupon",
    "description": "No time or location restrictions",
    "redemptionRules": null
  }' | jq -r '.id')

FLEXIBLE_QR=$(curl -s -X POST $BASE_URL/admin/entitlement-instances \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "userId": "'$USER_ID'",
    "entitlementTypeId": "'$FLEXIBLE_TYPE'"
  }' | jq -r '.qrCode')

echo "✅ Created flexible entitlement: $FLEXIBLE_QR"

# Should work anywhere, anytime
echo -e "\n✅ Attempting redemption anywhere (should succeed)..."
curl -s -X POST $BASE_URL/admin/redeem \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "qrCode": "'$FLEXIBLE_QR'",
    "latitude": 1.0000,
    "longitude": 100.0000
  }' | jq

# Test 6: Edge Cases
echo -e "\n🔍 TEST 6: Edge Cases"
echo "===================="

# Very small radius
TINY_RADIUS_TYPE=$(curl -s -X POST $BASE_URL/admin/entitlement-types \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "name": "Tiny Radius Coupon",
    "description": "1 meter radius only",
    "redemptionRules": {
      "timeWindows": [
        {"start": "00:00", "end": "23:59"}
      ],
      "locations": [
        {"lat": 1.3521, "lng": 103.8198, "radius": 1}
      ]
    }
  }' | jq -r '.id')

TINY_QR=$(curl -s -X POST $BASE_URL/admin/entitlement-instances \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "userId": "'$USER_ID'",
    "entitlementTypeId": "'$TINY_RADIUS_TYPE'"
  }' | jq -r '.qrCode')

echo "✅ Created tiny radius entitlement: $TINY_QR"

# Test exact location (should work)
echo -e "\n✅ Testing exact location match..."
curl -s -X POST $BASE_URL/admin/redeem \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "qrCode": "'$TINY_QR'",
    "latitude": 1.3521,
    "longitude": 103.8198
  }' | jq

# Test 7: Complex Rules Combination
echo -e "\n🎯 TEST 7: Complex Rules Combination"
echo "===================================="

COMPLEX_TYPE=$(curl -s -X POST $BASE_URL/admin/entitlement-types \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "name": "Complex Rules Coupon",
    "description": "Multiple time windows and locations",
    "redemptionRules": {
      "timeWindows": [
        {"start": "00:00", "end": "23:59"}
      ],
      "locations": [
        {"lat": 1.3521, "lng": 103.8198, "radius": 50},
        {"lat": 1.2834, "lng": 103.8607, "radius": 75}
      ]
    }
  }' | jq -r '.id')

COMPLEX_QR=$(curl -s -X POST $BASE_URL/admin/entitlement-instances \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "userId": "'$USER_ID'",
    "entitlementTypeId": "'$COMPLEX_TYPE'"
  }' | jq -r '.qrCode')

echo "✅ Created complex rules entitlement: $COMPLEX_QR"

# Test at boundary of first location
echo -e "\n🎯 Testing at boundary of first location..."
curl -s -X POST $BASE_URL/admin/redeem \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "qrCode": "'$COMPLEX_QR'",
    "latitude": 1.3525,
    "longitude": 103.8202
  }' | jq

echo -e "\n🎉 Dynamic Redemption Rules Testing Complete!"
echo "=============================================="

# Summary of all user's entitlements
echo -e "\n📊 Final User Entitlements Summary:"
curl -s "$BASE_URL/user/entitlements" \
  -H "Authorization: Bearer $USER_TOKEN" | \
  jq '[.[] | {
    name: .entitlementType.name,
    status: .status,
    qrCode: .qrCode,
    rules: .entitlementType.redemptionRules
  }]'