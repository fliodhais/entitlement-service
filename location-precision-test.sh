#!/bin/bash

BASE_URL="http://localhost:3000"

echo "📍 Testing Location Precision & Distance Calculations"
echo "===================================================="

# Get credentials
ADMIN_TOKEN=$(curl -s -X POST $BASE_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "admin@test.com", "password": "dummy"}' | jq -r '.token')

USER_ID=$(curl -s -X POST $BASE_URL/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "user@test.com", "password": "dummy"}' | jq -r '.user.id')

# Create precision test entitlement (100m radius at Raffles Place)
PRECISION_TYPE=$(curl -s -X POST $BASE_URL/admin/entitlement-types \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{
    "name": "Precision Test Coupon",
    "description": "Testing distance calculations",
    "redemptionRules": {
      "timeWindows": [{"start": "00:00", "end": "23:59"}],
      "locations": [{"lat": 1.2834, "lng": 103.8607, "radius": 100}]
    }
  }' | jq -r '.id')

echo "✅ Created precision test entitlement type"

# Test various distances
declare -a test_locations=(
  "1.2834,103.8607,0,Exact center"
  "1.2844,103.8607,111,~111m north"
  "1.2824,103.8607,111,~111m south"
  "1.2834,103.8617,87,~87m east"
  "1.2834,103.8597,87,~87m west"
  "1.2840,103.8613,95,~95m northeast"
  "1.2828,103.8601,95,~95m southwest"
  "1.2850,103.8607,178,~178m north (too far)"
  "1.2834,103.8630,200,~200m east (too far)"
)

for location in "${test_locations[@]}"; do
  IFS=',' read -r lat lng expected_dist description <<< "$location"
  
  # Create new entitlement for each test
  QR_CODE=$(curl -s -X POST $BASE_URL/admin/entitlement-instances \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -d '{
      "userId": "'$USER_ID'",
      "entitlementTypeId": "'$PRECISION_TYPE'"
    }' | jq -r '.qrCode')
  
  echo -e "\n🎯 Testing: $description (Expected: ${expected_dist}m)"
  echo "   Location: $lat, $lng"
  
  RESULT=$(curl -s -X POST $BASE_URL/admin/redeem \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $ADMIN_TOKEN" \
    -d '{
      "qrCode": "'$QR_CODE'",
      "latitude": '$lat',
      "longitude": '$lng'
    }')
  
  echo "   Result: $(echo $RESULT | jq -c '.')"
done

echo -e "\n📍 Location Precision Testing Complete!"