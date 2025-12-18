# SSL Setup with Let's Encrypt for nginx-proxy

## Quick Setup

1. **Create required directories:**
   ```bash
   cd laravel-wegro-docker
   mkdir -p certs vhost.d html
   ```

2. **Update docker-compose.yml** (already done if you pulled latest)

3. **Start nginx-proxy with Let's Encrypt:**
   ```bash
   docker-compose up -d proxy-server letsencrypt
   ```

4. **Verify it's running:**
   ```bash
   docker ps | grep -E "proxy-server|letsencrypt"
   ```

## How It Works

When you start a container with these environment variables:
- `VIRTUAL_HOST=call-service.com`
- `LETSENCRYPT_HOST=call-service.com`
- `LETSENCRYPT_EMAIL=your-email@example.com`

The Let's Encrypt companion will:
1. Detect the new container
2. Request SSL certificate from Let's Encrypt
3. Configure nginx-proxy to use HTTPS
4. Auto-renew certificates before expiration

## Troubleshooting

### Certificate not generating?

1. **Check DNS:**
   ```bash
   dig call-service.com
   # Should return 138.68.55.52
   ```

2. **Check firewall:**
   ```bash
   sudo ufw status
   sudo ufw allow 80/tcp
   sudo ufw allow 443/tcp
   ```

3. **Check logs:**
   ```bash
   docker logs letsencrypt-companion
   docker logs proxy-server
   ```

### Container in "Created" state?

For sentinel or other containers:
```bash
docker-compose up -d sentinel
# Or rebuild if needed
docker-compose build sentinel
docker-compose up -d sentinel
```

