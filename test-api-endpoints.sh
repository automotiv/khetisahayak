#!/bin/bash

# Kheti Sahayak API Testing Script
# Tests all new endpoints: Educational Content, Notifications, Weather, etc.
# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# API Base URL
API_URL="${API_URL:-http://localhost:8080}"

# Test counters
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Function to print colored output
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Function to test an endpoint
test_endpoint() {
    local method=$1
    local endpoint=$2
    local description=$3
    local data=$4
    local auth_token=$5
    local expected_status=${6:-200}
    
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    print_info "Testing: $description"
    
    # Build curl command
    local curl_cmd="curl -s -w '\n%{http_code}' -X $method"
    
    if [ ! -z "$data" ]; then
        curl_cmd="$curl_cmd -H 'Content-Type: application/json' -d '$data'"
    fi
    
    if [ ! -z "$auth_token" ]; then
        curl_cmd="$curl_cmd -H 'Authorization: Bearer $auth_token'"
    fi
    
    curl_cmd="$curl_cmd $API_URL$endpoint"
    
    # Execute request
    response=$(eval $curl_cmd)
    http_code=$(echo "$response" | tail -n 1)
    body=$(echo "$response" | sed '$d')
    
    # Check status code
    if [ "$http_code" == "$expected_status" ]; then
        print_success "$description - HTTP $http_code"
        PASSED_TESTS=$((PASSED_TESTS + 1))
        
        # Show response body snippet
        if [ ! -z "$body" ]; then
            echo "$body" | jq '.' 2>/dev/null | head -n 10 || echo "$body" | head -n 5
        fi
        return 0
    else
        print_error "$description - Expected HTTP $expected_status, got $http_code"
        FAILED_TESTS=$((FAILED_TESTS + 1))
        echo "Response: $body"
        return 1
    fi
}

# Print header
echo ""
echo "================================================================"
echo "   🌾 Kheti Sahayak API Testing Suite"
echo "   Testing Agricultural Platform Endpoints"
echo "================================================================"
echo ""
echo "API URL: $API_URL"
echo "Starting tests..."
echo ""

# ==================================================
# 1. HEALTH CHECK
# ==================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1️⃣  HEALTH CHECK"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
test_endpoint "GET" "/api/health" "Health check endpoint"
echo ""

# ==================================================
# 2. EDUCATIONAL CONTENT (Public Endpoints)
# ==================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "2️⃣  EDUCATIONAL CONTENT (Public Access)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Get all content
test_endpoint "GET" "/api/education/content?page=0&size=5" "Get all educational content"
echo ""

# Get featured content
test_endpoint "GET" "/api/education/content/featured" "Get featured educational content"
echo ""

# Get categories
test_endpoint "GET" "/api/education/categories" "Get content categories"
echo ""

# Search content
test_endpoint "GET" "/api/education/content/search?q=rice" "Search content for 'rice'"
echo ""

# Get popular content
test_endpoint "GET" "/api/education/content/popular?page=0&size=5" "Get popular content"
echo ""

# Get recent content
test_endpoint "GET" "/api/education/content/recent?page=0&size=5" "Get recent content"
echo ""

# Get content by category
test_endpoint "GET" "/api/education/content/category/CROP_MANAGEMENT?page=0&size=5" "Get CROP_MANAGEMENT content"
echo ""

# ==================================================
# 3. WEATHER SERVICE
# ==================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "3️⃣  WEATHER SERVICE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Get current weather (Nashik, Maharashtra)
test_endpoint "GET" "/api/weather?latitude=19.9975&longitude=73.7898" "Get current weather for Nashik"
echo ""

# Get weather forecast
test_endpoint "GET" "/api/weather/forecast?latitude=19.9975&longitude=73.7898" "Get 5-day weather forecast"
echo ""

# Get weather alerts
test_endpoint "GET" "/api/weather/alerts?latitude=19.9975&longitude=73.7898" "Get weather alerts"
echo ""

# ==================================================
# 4. AUTHENTICATION FLOW
# ==================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "4️⃣  AUTHENTICATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Generate random mobile number for testing
TEST_MOBILE="98765$(date +%s | tail -c 6)"

# Register user
register_data='{
  "mobileNumber": "'$TEST_MOBILE'",
  "fullName": "Test Farmer",
  "primaryCrop": "Rice",
  "state": "Maharashtra",
  "district": "Nashik",
  "farmSize": 2.5,
  "userType": "FARMER"
}'

print_info "Registering user with mobile: $TEST_MOBILE"
register_response=$(curl -s -X POST "$API_URL/api/auth/register" \
    -H "Content-Type: application/json" \
    -d "$register_data")

echo "$register_response" | jq '.' 2>/dev/null || echo "$register_response"

# Extract OTP from response or use default
OTP=$(echo "$register_response" | jq -r '.otp // "123456"' 2>/dev/null)
if [ -z "$OTP" ] || [ "$OTP" == "null" ]; then
    OTP="123456"
    print_warning "Using default OTP: $OTP"
fi

echo ""
print_info "Verifying OTP: $OTP"

# Verify OTP and get JWT token
verify_data='{
  "mobileNumber": "'$TEST_MOBILE'",
  "otp": "'$OTP'"
}'

verify_response=$(curl -s -X POST "$API_URL/api/auth/verify-otp" \
    -H "Content-Type: application/json" \
    -d "$verify_data")

echo "$verify_response" | jq '.' 2>/dev/null || echo "$verify_response"

# Extract JWT token
JWT_TOKEN=$(echo "$verify_response" | jq -r '.token // empty' 2>/dev/null)

if [ ! -z "$JWT_TOKEN" ] && [ "$JWT_TOKEN" != "null" ]; then
    print_success "Authentication successful! JWT token obtained."
    echo "Token: ${JWT_TOKEN:0:50}..."
else
    print_warning "Could not extract JWT token. Some authenticated tests will be skipped."
    JWT_TOKEN=""
fi

echo ""

# ==================================================
# 5. AUTHENTICATED EDUCATIONAL CONTENT
# ==================================================
if [ ! -z "$JWT_TOKEN" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "5️⃣  EDUCATIONAL CONTENT (Authenticated)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Get content ID from the first content item
    content_response=$(curl -s "$API_URL/api/education/content?page=0&size=1")
    CONTENT_ID=$(echo "$content_response" | jq -r '.data[0].id // empty' 2>/dev/null)
    
    if [ ! -z "$CONTENT_ID" ] && [ "$CONTENT_ID" != "null" ]; then
        print_info "Using content ID: $CONTENT_ID"
        
        # Like content
        test_endpoint "POST" "/api/education/content/$CONTENT_ID/like" \
            "Like educational content" "" "$JWT_TOKEN"
        echo ""
        
        # Unlike content
        test_endpoint "POST" "/api/education/content/$CONTENT_ID/unlike" \
            "Unlike educational content" "" "$JWT_TOKEN"
        echo ""
    else
        print_warning "No content found for like/unlike testing"
    fi
else
    print_warning "Skipping authenticated educational content tests (no JWT token)"
fi

# ==================================================
# 6. NOTIFICATIONS (Authenticated)
# ==================================================
if [ ! -z "$JWT_TOKEN" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "6️⃣  NOTIFICATIONS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Get all notifications
    test_endpoint "GET" "/api/notifications?page=0&size=10" \
        "Get all notifications" "" "$JWT_TOKEN"
    echo ""
    
    # Get unread notifications
    test_endpoint "GET" "/api/notifications/unread?page=0&size=10" \
        "Get unread notifications" "" "$JWT_TOKEN"
    echo ""
    
    # Get urgent notifications
    test_endpoint "GET" "/api/notifications/urgent" \
        "Get urgent notifications" "" "$JWT_TOKEN"
    echo ""
    
    # Get recent notifications
    test_endpoint "GET" "/api/notifications/recent" \
        "Get recent notifications (24h)" "" "$JWT_TOKEN"
    echo ""
    
    # Get notification statistics
    test_endpoint "GET" "/api/notifications/stats" \
        "Get notification statistics" "" "$JWT_TOKEN"
    echo ""
    
    # Get notifications by type
    test_endpoint "GET" "/api/notifications/type/WEATHER_ALERT?page=0&size=5" \
        "Get weather alert notifications" "" "$JWT_TOKEN"
    echo ""
    
    # Get notification ID for further testing
    notif_response=$(curl -s -H "Authorization: Bearer $JWT_TOKEN" \
        "$API_URL/api/notifications/unread?page=0&size=1")
    NOTIF_ID=$(echo "$notif_response" | jq -r '.data[0].id // empty' 2>/dev/null)
    
    if [ ! -z "$NOTIF_ID" ] && [ "$NOTIF_ID" != "null" ]; then
        print_info "Using notification ID: $NOTIF_ID"
        
        # Mark notification as read
        test_endpoint "POST" "/api/notifications/$NOTIF_ID/read" \
            "Mark notification as read" "" "$JWT_TOKEN"
        echo ""
    else
        print_warning "No unread notifications found for testing"
    fi
    
    # Mark all as read
    test_endpoint "POST" "/api/notifications/read-all" \
        "Mark all notifications as read" "" "$JWT_TOKEN"
    echo ""
else
    print_warning "Skipping notification tests (no JWT token)"
fi

# ==================================================
# 7. MARKETPLACE
# ==================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "7️⃣  MARKETPLACE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Get marketplace categories
test_endpoint "GET" "/api/marketplace/categories" "Get marketplace categories"
echo ""

# Search products
test_endpoint "GET" "/api/marketplace/products?page=0&size=5" "Get marketplace products"
echo ""

# ==================================================
# 8. SWAGGER DOCUMENTATION
# ==================================================
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "8️⃣  API DOCUMENTATION"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check Swagger UI
test_endpoint "GET" "/api-docs" "Check Swagger UI availability" "" "" "302"
echo ""

# Check OpenAPI JSON
test_endpoint "GET" "/v3/api-docs" "Check OpenAPI JSON specification"
echo ""

# ==================================================
# SUMMARY
# ==================================================
echo ""
echo "================================================================"
echo "   📊 TEST SUMMARY"
echo "================================================================"
echo ""
echo -e "Total Tests:  ${BLUE}$TOTAL_TESTS${NC}"
echo -e "Passed:       ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed:       ${RED}$FAILED_TESTS${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    print_success "🎉 ALL TESTS PASSED! The Kheti Sahayak API is working perfectly!"
else
    print_error "⚠️  Some tests failed. Please review the output above."
fi

echo ""
echo "================================================================"
echo "   📚 USEFUL LINKS"
echo "================================================================"
echo ""
echo "• Swagger UI:        $API_URL/api-docs"
echo "• Health Check:      $API_URL/api/health"
echo "• API Documentation: $API_URL/v3/api-docs"
echo ""
echo "================================================================"
echo ""

# Exit with appropriate code
if [ $FAILED_TESTS -eq 0 ]; then
    exit 0
else
    exit 1
fi

