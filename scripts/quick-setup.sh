#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 LiteLLM Infrastructure Quick Setup${NC}"
echo "===================================="
echo ""

# Check prerequisites
echo "Checking prerequisites..."

# Check Docker
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker is not installed${NC}"
    echo "Please install Docker from https://docs.docker.com/get-docker/"
    exit 1
else
    echo -e "${GREEN}✓ Docker is installed${NC}"
fi

# Check Docker Compose
if ! command -v docker-compose &> /dev/null; then
    # Try docker compose (v2)
    if docker compose version &> /dev/null; then
        echo -e "${GREEN}✓ Docker Compose (v2) is installed${NC}"
        alias docker-compose="docker compose"
    else
        echo -e "${RED}✗ Docker Compose is not installed${NC}"
        echo "Please install Docker Compose from https://docs.docker.com/compose/install/"
        exit 1
    fi
else
    echo -e "${GREEN}✓ Docker Compose is installed${NC}"
fi

# Check if .env exists
echo ""
if [ ! -f .env ]; then
    echo "Creating .env file from template..."
    cp env.template .env
    echo -e "${GREEN}✓ Created .env file${NC}"
    echo ""
    echo -e "${YELLOW}⚠️  Important: Edit .env file with your API keys before starting!${NC}"
    echo "   Required: LITELLM_MASTER_KEY"
    echo "   Optional: OPENAI_API_KEY, ANTHROPIC_API_KEY, etc."
    echo ""
    read -p "Would you like to edit .env now? (y/N) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ${EDITOR:-nano} .env
    fi
else
    echo -e "${GREEN}✓ .env file already exists${NC}"
fi

# Create necessary directories
echo ""
echo "Creating directories..."
mkdir -p logs
echo -e "${GREEN}✓ Created logs directory${NC}"

# Validate configuration
echo ""
echo "Validating Docker Compose configuration..."
if docker-compose config > /dev/null 2>&1; then
    echo -e "${GREEN}✓ Configuration is valid${NC}"
else
    echo -e "${RED}✗ Configuration validation failed${NC}"
    docker-compose config
    exit 1
fi

# Ask to start services
echo ""
echo -e "${BLUE}Setup complete!${NC}"
echo ""
read -p "Would you like to start the services now? (y/N) " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Starting services..."
    docker-compose up -d
    
    # Wait for services to start
    echo "Waiting for services to be ready..."
    sleep 5
    
    # Check status
    echo ""
    echo "Service status:"
    docker-compose ps
    
    echo ""
    echo -e "${GREEN}✓ Services started successfully!${NC}"
    echo ""
    echo "Access points:"
    echo "  - API Gateway: http://localhost:8080"
    echo "  - LiteLLM Direct: http://localhost:4000"
    echo ""
    echo "Next steps:"
    echo "  1. Test the API: ./scripts/test-api.sh"
    echo "  2. View logs: make logs-f"
    echo "  3. Check health: make health"
else
    echo ""
    echo "To start services later, run:"
    echo "  make up        # Development mode"
    echo "  make up-prod   # Production mode"
fi

echo ""
echo "For more information, see README.md" 
