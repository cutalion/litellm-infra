# LiteLLM AI API Gateway

A secure, modular, and observable infrastructure to manage access to multiple AI API providers (OpenAI, Anthropic, Ollama, etc.) for internal teams and services.

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose
- Domain name (for production) or localhost (for development)

### Development Setup

1. **Clone and configure environment:**
   ```bash
   # Copy environment template
   cp .env.example .env
   
   # Edit .env with your API keys
   nano .env
   ```

2. **Start development environment:**
   ```bash
   # Start services (uses docker-compose.override.yml automatically)
   docker-compose up -d
   
   # Check logs
   docker-compose logs -f
   ```

3. **Test the API:**
   ```bash
   # Health check
   curl http://localhost:8080/health
   
   # Test completion (replace with your master key)
   curl -X POST http://localhost:8080/chat/completions \
     -H "Authorization: Bearer dev-master-key-12345" \
     -H "Content-Type: application/json" \
     -d '{
       "model": "gpt-3.5-turbo",
       "messages": [{"role": "user", "content": "Hello!"}]
     }'
   ```

### Production Setup

1. **Configure domain and email:**
   ```bash
   # Edit Caddyfile with your domain
   sed -i 's/yourdomain.com/your-actual-domain.com/g' Caddyfile
   sed -i 's/your-email@example.com/your-actual-email@domain.com/g' Caddyfile
   ```

2. **Set production environment:**
   ```bash
   # Set strong master key and API keys in .env
   nano .env
   ```

3. **Deploy:**
   ```bash
   # Start production services
   docker-compose -f docker-compose.yml up -d
   
   # Monitor logs
   docker-compose logs -f
   ```

## 📖 API Usage

### Authentication

All requests require the `Authorization` header with your master key:
```bash
Authorization: Bearer your-master-key
```

### Supported Models

- **OpenAI**: `gpt-3.5-turbo`, `gpt-4`, `gpt-4-turbo`
- **Anthropic**: `claude-3-haiku`, `claude-3-sonnet`
- **Ollama**: (when enabled) `ollama/llama3`

### Example Requests

```bash
# Chat completion
curl -X POST https://your-domain.com/chat/completions \
  -H "Authorization: Bearer your-master-key" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-3.5-turbo",
    "messages": [
      {"role": "user", "content": "Explain quantum computing"}
    ]
  }'

# List available models
curl https://your-domain.com/models \
  -H "Authorization: Bearer your-master-key"
```

## 🔧 Configuration

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `LITELLM_MASTER_KEY` | Master key for API access | Yes |
| `OPENAI_API_KEY` | OpenAI API key | Optional |
| `ANTHROPIC_API_KEY` | Anthropic API key | Optional |
| `GROQ_API_KEY` | Groq API key | Optional |

### Adding New Models

Edit `litellm-config.yaml` (production) or `litellm-config.dev.yaml` (development):

```yaml
model_list:
  - model_name: new-model
    litellm_provider: provider-name
    api_key: os.environ/PROVIDER_API_KEY
    api_base: https://api.provider.com/v1  # if needed
```

## 🔌 Extensions

### Adding Ollama

1. **Add to docker-compose.yml:**
   ```yaml
   ollama:
     image: ollama/ollama
     container_name: ollama
     ports:
       - "11434:11434"
     volumes:
       - ollama_data:/root/.ollama
     restart: unless-stopped
     networks:
       - litellm-network
   ```

2. **Update LiteLLM config:**
   ```yaml
   - model_name: ollama/llama3
     litellm_provider: ollama
     api_base: http://ollama:11434
   ```

### Adding Database (Future)

Uncomment in docker-compose.yml:
```yaml
postgres:
  image: postgres:15
  environment:
    POSTGRES_DB: litellm
    POSTGRES_USER: litellm
    POSTGRES_PASSWORD: password
  volumes:
    - postgres_data:/var/lib/postgresql/data
```

## 🏗️ Architecture

```
Internet → Caddy (HTTPS/Auth) → LiteLLM → AI Providers
                                     ↓
                              Config & Routing
```

### Services

- **Caddy**: HTTPS termination, basic auth, rate limiting
- **LiteLLM**: Universal AI API proxy with routing
- **Ollama** (optional): Local LLM hosting
- **Postgres** (future): Persistence and analytics
- **Redis** (future): Caching and rate limiting

## 🔍 Monitoring

### Health Checks

- LiteLLM: `http://localhost:4000/health`
- Gateway: `http://localhost:8080/health` (dev) or `https://your-domain.com/health` (prod)

### Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f litellm
docker-compose logs -f caddy
```

### Service Status

```bash
# Check running services
docker-compose ps

# Restart a service
docker-compose restart litellm
```

## 🛠️ Development

### File Structure

```
├── docker-compose.yml          # Production services
├── docker-compose.override.yml # Development overrides
├── litellm-config.yaml         # Production LiteLLM config
├── litellm-config.dev.yaml     # Development LiteLLM config
├── Caddyfile                   # Production Caddy config
├── Caddyfile.dev              # Development Caddy config
├── .env                       # Environment variables
└── README.md                  # This file
```

### Commands

```bash
# Development
docker-compose up -d              # Start with dev overrides
docker-compose down               # Stop services
docker-compose restart litellm   # Restart specific service

# Production
docker-compose -f docker-compose.yml up -d

# Cleanup
docker-compose down -v           # Remove volumes
docker system prune -f           # Clean up Docker
```

## 🔐 Security Considerations

1. **Use strong master keys** in production
2. **Enable basic auth** in Caddy for additional security
3. **Set up proper firewall rules**
4. **Use HTTPS** in production (Caddy handles this automatically)
5. **Rotate API keys** regularly
6. **Monitor access logs**

## 📝 License

This project is licensed under the MIT License. 
