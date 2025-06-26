#!/bin/bash

echo "🎯 Running All Redemption Rules Tests"
echo "====================================="

echo -e "\n📋 Step 1: Basic Redemption Rules"
./redemption-rules-test.sh

echo -e "\n📋 Step 2: Location Precision Tests"
./location-precision-test.sh

echo -e "\n📋 Step 3: Time Window Edge Cases"
./time-window-test.sh

echo -e "\n📊 Final Database State:"
curl -s "http://localhost:3000/debug/db-state" | jq '.counts'

echo -e "\n🎉 All redemption rules tests completed!"