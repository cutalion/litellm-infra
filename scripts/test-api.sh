#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Default values
API_URL="${API_URL:-http://localhost:8080}"
API_KEY="${LITELLM_MASTER_KEY:-dev-master-key-123456789}"
MODEL="${MODEL:-gpt-3.5-turbo}"

echo "🧪 Testing LiteLLM API Gateway"
echo "=============================="
echo "API URL: $API_URL"
echo "Model: $MODEL"
echo ""

# Test 1: Health check
echo -n "1. Testing health endpoint... "
HEALTH_RESPONSE=$(curl -s -w "\n%{http_code}" "$API_URL/health")
HTTP_CODE=$(echo "$HEALTH_RESPONSE" | tail -n1)
BODY=$(echo "$HEALTH_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ Failed (HTTP $HTTP_CODE)${NC}"
    echo "Response: $BODY"
    exit 1
fi

# Test 2: Models endpoint
echo -n "2. Testing models endpoint... "
MODELS_RESPONSE=$(curl -s -w "\n%{http_code}" -H "Authorization: Bearer $API_KEY" "$API_URL/v1/models")
HTTP_CODE=$(echo "$MODELS_RESPONSE" | tail -n1)
BODY=$(echo "$MODELS_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ OK${NC}"
    echo "   Available models:"
    echo "$BODY" | jq -r '.data[].id' 2>/dev/null | sed 's/^/   - /' || echo "   (Could not parse models)"
else
    echo -e "${RED}✗ Failed (HTTP $HTTP_CODE)${NC}"
    echo "Response: $BODY"
fi

# Test 3: Chat completion
echo -n "3. Testing chat completion... "
CHAT_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/v1/chat/completions" \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
        \"model\": \"$MODEL\",
        \"messages\": [{\"role\": \"user\", \"content\": \"Say 'Hello from LiteLLM!' and nothing else.\"}],
        \"max_tokens\": 50
    }")

HTTP_CODE=$(echo "$CHAT_RESPONSE" | tail -n1)
BODY=$(echo "$CHAT_RESPONSE" | head -n-1)

if [ "$HTTP_CODE" = "200" ]; then
    echo -e "${GREEN}✓ OK${NC}"
    CONTENT=$(echo "$BODY" | jq -r '.choices[0].message.content' 2>/dev/null)
    if [ -n "$CONTENT" ]; then
        echo "   Response: $CONTENT"
    fi
else
    echo -e "${RED}✗ Failed (HTTP $HTTP_CODE)${NC}"
    echo "Response: $BODY"
    
    # Common error messages
    if [[ "$BODY" == *"api_key"* ]]; then
        echo -e "${YELLOW}Hint: Check your API keys in .env file${NC}"
    elif [[ "$BODY" == *"model"* ]]; then
        echo -e "${YELLOW}Hint: Model '$MODEL' might not be configured. Check litellm-config.yaml${NC}"
    fi
fi

# Test 4: Streaming
echo -n "4. Testing streaming... "
STREAM_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/v1/chat/completions" \
    -H "Authorization: Bearer $API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
        \"model\": \"$MODEL\",
        \"messages\": [{\"role\": \"user\", \"content\": \"Count to 3\"}],
        \"stream\": true,
        \"max_tokens\": 50
    }" | tail -n1)

if [ "$STREAM_RESPONSE" = "200" ]; then
    echo -e "${GREEN}✓ OK${NC}"
else
    echo -e "${RED}✗ Failed (HTTP $STREAM_RESPONSE)${NC}"
fi

echo ""
echo "Testing complete!" 
