#!/bin/bash

BASE_URL="http://localhost:3000"

echo "🕐 Testing Time Window Edge Cases"
echo "================================"

# Get credentials
ADMIN_TOKEN=$(curl -s -X POST $BASE_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@test.com", "password": "dummy"}' | jq -r '.token')

USER_ID=$(curl -s -X POST $BASE_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "user@test.com", "password": "dummy"}' | jq -r '.user.id')

# Test 1: Midnight crossing
echo -e "\n🌙 TEST 1: Midnight Crossing Window"
MIDNIGHT_TYPE=$(curl -s -X POST $BASE_URL/admin/entitlement-types \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "name": "Midnight Crossing",
    "description": "23:30 to 01:30",
    "redemptionRules": {
      "timeWindows": [{"start": "23:30", "end": "01:30"}],
      "locations": [{"lat": 1.3521, "lng": 103.8198, "radius": 100}]
    }
  }' | jq -r '.id')

# Test 2: Very narrow window
echo -e "\n⏰ TEST 2: Very Narrow Window (1 minute)"
NARROW_TYPE=$(curl -s -X POST $BASE_URL/admin/entitlement-types \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "name": "One Minute Window",
    "description": "12:00 to 12:01",
    "redemptionRules": {
      "timeWindows": [{"start": "12:00", "end": "12:01"}],
      "locations": [{"lat": 1.3521, "lng": 103.8198, "radius": 100}]
    }
  }' | jq -r '.id')

# Test 3: Overlapping windows
echo -e "\n🔄 TEST 3: Overlapping Time Windows"
OVERLAP_TYPE=$(curl -s -X POST $BASE_URL/admin/entitlement-types \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "name": "Overlapping Windows",
    "description": "Multiple overlapping time periods",
    "redemptionRules": {
      "timeWindows": [
        {"start": "10:00", "end": "12:00"},
        {"start": "11:30", "end": "13:30"},
        {"start": "13:00", "end": "15:00"}
      ],
      "locations": [{"lat": 1.3521, "lng": 103.8198, "radius": 100}]
    }
  }' | jq -r '.id')

# Test current time against each
CURRENT_TIME=$(date +"%H:%M")
echo -e "\n⏰ Current time: $CURRENT_TIME"

for TYPE_ID in $MIDNIGHT_TYPE $NARROW_TYPE $OVERLAP_TYPE; do
  QR_CODE=$(curl -s -X POST $BASE_URL/admin/entitlement-instances \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -d '{
      "userId": "'$USER_ID'",
      "entitlementTypeId": "'$TYPE_ID'"
    }' | jq -r '.qrCode')
  
  echo -e "\n🎯 Testing entitlement: $QR_CODE"
  curl -s -X POST $BASE_URL/admin/redeem \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -d '{
      "qrCode": "'$QR_CODE'",
      "latitude": 1.3521,
      "longitude": 103.8198
    }' | jq
done

echo -e "\n🕐 Time Window Testing Complete!"