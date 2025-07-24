# LiteLLM AI API Gateway Infrastructure

A secure, modular, and observable infrastructure to manage access to multiple AI API providers (OpenAI, Anthropic, Ollama, etc.) using LiteLLM as a universal proxy.

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose installed
- API keys for your preferred AI providers (OpenAI, Anthropic, etc.)
- A domain name (for production deployment)

### Setup

1. **Clone this repository**
   ```bash
   git clone <your-repo-url>
   cd litellm-infra
   ```

2. **Create environment file**
   ```bash
   cp env.template .env
   # Edit .env with your API keys and configuration
   ```

3. **Start in development mode**
   ```bash
   docker-compose up -d
   ```

4. **Access the API**
   - Development: `http://localhost:8080`
   - Direct LiteLLM: `http://localhost:4000`

## 📋 Configuration

### Environment Variables

Edit `.env` file with your configuration:

```env
# Required
LITELLM_MASTER_KEY=your-secure-master-key-here

# API Keys (add what you need)
OPENAI_API_KEY=sk-...
ANTHROPIC_API_KEY=sk-ant-...

# Optional
DATABASE_URL=postgresql://user:password@localhost:5432/litellm
REDIS_HOST=redis
REDIS_PORT=6379
```

### Model Configuration

Edit `litellm-config.yaml` to configure available models:

```yaml
model_list:
  - model_name: gpt-4
    litellm_params:
      model: gpt-4
      api_key: ${OPENAI_API_KEY}
```

## 🔧 Usage

### Basic API Call

```bash
curl -X POST http://localhost:8080/v1/chat/completions \
  -H "Authorization: Bearer $LITELLM_MASTER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "gpt-4",
    "messages": [{"role": "user", "content": "Hello, how are you?"}]
  }'
```

### Using with OpenAI Python SDK

```python
from openai import OpenAI

client = OpenAI(
    base_url="http://localhost:8080/v1",
    api_key="your-litellm-master-key"
)

response = client.chat.completions.create(
    model="gpt-4",
    messages=[{"role": "user", "content": "Hello!"}]
)
```

## 🚀 Production Deployment

1. **Update Caddyfile**
   - Replace `api.yourdomain.com` with your actual domain
   - Configure authentication if needed

2. **Use production compose file**
   ```bash
   docker-compose -f docker-compose.yml up -d
   ```

3. **Enable HTTPS**
   - Caddy will automatically obtain SSL certificates
   - Ensure ports 80 and 443 are open

## 📊 Expanding the Stack

### Add Ollama

1. **Update docker-compose.yml**:
   ```yaml
   ollama:
     image: ollama/ollama
     ports: ["11434:11434"]
     volumes: ["ollama_data:/root/.ollama"]
   ```

2. **Update litellm-config.yaml**:
   ```yaml
   - model_name: llama3
     litellm_params:
       model: ollama/llama3
       api_base: http://ollama:11434
   ```

3. **Pull models**:
   ```bash
   docker-compose exec ollama ollama pull llama3
   ```

### Add PostgreSQL Database

1. **Update docker-compose.yml**:
   ```yaml
   postgres:
     image: postgres:15-alpine
     environment:
       POSTGRES_DB: litellm
       POSTGRES_USER: litellm
       POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
     volumes:
       - postgres_data:/var/lib/postgresql/data
   ```

2. **Update .env**:
   ```env
   DATABASE_URL=postgresql://litellm:password@postgres:5432/litellm
   ```

### Add Redis for Rate Limiting

1. **Update docker-compose.yml**:
   ```yaml
   redis:
     image: redis:7-alpine
     command: redis-server --requirepass ${REDIS_PASSWORD}
     volumes:
       - redis_data:/data
   ```

2. **Configure in .env**:
   ```env
   REDIS_HOST=redis
   REDIS_PORT=6379
   REDIS_PASSWORD=your-redis-password
   ```

## 🔐 Security

### Basic Authentication

Uncomment and configure in `Caddyfile`:

```caddyfile
basicauth /v1/* {
    admin $2a$14$Zkx19XLiW6VYouLHR5NmfOFU0z2GTNmpkT/5qqR7hx4IjWJPDhjvG
}
```

Generate password hash:
```bash
docker-compose exec caddy caddy hash-password
```

### API Keys

LiteLLM supports multiple authentication methods:
- Master key (full access)
- User-specific keys
- Team-based access

## 📊 Monitoring

### View Logs

```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f litellm
```

### Health Check

```bash
curl http://localhost:8080/health
```

## 🛠️ Troubleshooting

### Common Issues

1. **Port conflicts**
   - Change ports in `docker-compose.override.yml`

2. **API key errors**
   - Verify keys in `.env` file
   - Check model configuration in `litellm-config.yaml`

3. **Connection refused**
   - Ensure services are running: `docker-compose ps`
   - Check service logs: `docker-compose logs <service>`

## 📚 Resources

- [LiteLLM Documentation](https://docs.litellm.ai/)
- [Caddy Documentation](https://caddyserver.com/docs/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)

## 📄 License

[Your License Here] 
