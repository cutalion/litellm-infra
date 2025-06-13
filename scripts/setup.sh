#!/bin/bash

# LiteLLM AI Gateway Setup Script

set -e

echo "🚀 Setting up LiteLLM AI Gateway..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo "❌ Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "📝 Creating .env file..."
    cat > .env << EOF
# LiteLLM Configuration
LITELLM_MASTER_KEY=your-secure-master-key-here

# AI Provider API Keys
OPENAI_API_KEY=your-openai-api-key-here
ANTHROPIC_API_KEY=your-anthropic-api-key-here
GROQ_API_KEY=your-groq-api-key-here

# Optional: Add other provider keys as needed
# COHERE_API_KEY=your-cohere-api-key-here
# TOGETHER_API_KEY=your-together-api-key-here
# HUGGINGFACE_API_KEY=your-huggingface-api-key-here

# Database (for future use)
# DATABASE_URL=postgresql://user:password@localhost:5432/litellm

# Redis (for future use)
# REDIS_URL=redis://localhost:6379
EOF
    echo "✅ Created .env file. Please edit it with your API keys."
    echo "📝 Run: nano .env"
else
    echo "✅ .env file already exists."
fi

# Function to start development environment
start_dev() {
    echo "🔧 Starting development environment..."
    docker-compose up -d
    echo "✅ Development environment started!"
    echo "🌐 API available at: http://localhost:8080"
    echo "🔍 Health check: curl http://localhost:8080/health"
    echo "📋 View logs: docker-compose logs -f"
}

# Function to start production environment
start_prod() {
    echo "🏭 Starting production environment..."
    echo "⚠️  Make sure you've configured your domain in Caddyfile"
    read -p "Have you configured your domain and email in Caddyfile? (y/N): " confirm
    if [[ $confirm != [yY] ]]; then
        echo "📝 Please edit Caddyfile with your domain and email first."
        echo "   sed -i 's/yourdomain.com/your-actual-domain.com/g' Caddyfile"
        echo "   sed -i 's/your-email@example.com/your-actual-email@domain.com/g' Caddyfile"
        exit 1
    fi
    
    docker-compose -f docker-compose.yml up -d
    echo "✅ Production environment started!"
    echo "🌐 API available at: https://your-domain.com"
    echo "📋 View logs: docker-compose logs -f"
}

# Function to stop services
stop_services() {
    echo "🛑 Stopping services..."
    docker-compose down
    echo "✅ Services stopped."
}

# Function to show status
show_status() {
    echo "📊 Service Status:"
    docker-compose ps
    echo ""
    echo "📋 Recent logs:"
    docker-compose logs --tail=10
}

# Function to test API
test_api() {
    echo "🧪 Testing API..."
    
    # Test health endpoint
    echo "Testing health endpoint..."
    if curl -f http://localhost:8080/health > /dev/null 2>&1; then
        echo "✅ Health check passed"
    else
        echo "❌ Health check failed"
        return 1
    fi
    
    # Test with master key
    echo "Testing chat completion..."
    response=$(curl -s -X POST http://localhost:8080/chat/completions \
        -H "Authorization: Bearer dev-master-key-12345" \
        -H "Content-Type: application/json" \
        -d '{
            "model": "gpt-3.5-turbo",
            "messages": [{"role": "user", "content": "Hello! Respond with just \"API test successful\""}],
            "max_tokens": 10
        }' || echo "failed")
    
    if [[ $response == *"API test successful"* ]] || [[ $response == *"choices"* ]]; then
        echo "✅ API test passed"
    else
        echo "❌ API test failed or no valid API keys configured"
        echo "Response: $response"
    fi
}

# Parse command line arguments
case "${1:-help}" in
    "dev"|"development")
        start_dev
        ;;
    "prod"|"production")
        start_prod
        ;;
    "stop")
        stop_services
        ;;
    "status")
        show_status
        ;;
    "test")
        test_api
        ;;
    "logs")
        docker-compose logs -f
        ;;
    "restart")
        stop_services
        sleep 2
        start_dev
        ;;
    "help"|*)
        echo "Usage: $0 {dev|prod|stop|status|test|logs|restart|help}"
        echo ""
        echo "Commands:"
        echo "  dev         Start development environment"
        echo "  prod        Start production environment"
        echo "  stop        Stop all services"
        echo "  status      Show service status"
        echo "  test        Test API endpoints"
        echo "  logs        Show and follow logs"
        echo "  restart     Restart development environment"
        echo "  help        Show this help message"
        echo ""
        echo "Examples:"
        echo "  $0 dev      # Start development environment"
        echo "  $0 test     # Test the API"
        echo "  $0 logs     # View logs"
        echo "  $0 stop     # Stop services"
        ;;
esac 
