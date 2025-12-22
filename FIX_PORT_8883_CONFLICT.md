# Fix Port 8883 Conflict and SSL Configuration

## Problem Summary

1. **Port Conflict**: Both `proxy-server` (nginx-proxy) and `call-service` are trying to bind to port 8883
2. **SSL Error**: SSL handshake fails with "wrong version number" - nginx-proxy isn't properly handling SSL on port 8883
3. **Configuration Issue**: call-service should NOT expose port 8883 directly - it should only expose port 80 internally

## Root Cause

The `call-service` container is configured with `PORT=8883` which creates a port mapping `8883:80`. This conflicts with `proxy-server` which needs to bind to port 8883 to handle SSL termination.

## Solution

### Step 1: Fix call-service Configuration

The `call-service` should NOT expose port 8883. It should only expose port 80 internally so nginx-proxy can proxy to it.

**Option A: Use production-style compose file (Recommended)**

If using `docker-compose.prod.yml`, it already uses `expose: - "80"` which is correct. Ensure your `.env` file does NOT set `PORT=8883`.

**Option B: Modify the compose file being used**

If you're using `docker-compose.local.yml` or `docker-compose.dev.yml`, change:

```yaml
# BEFORE (WRONG - causes port conflict):
ports:
  - ${PORT}:80

# AFTER (CORRECT - only expose internally):
expose:
  - "80"
```

And remove or comment out `PORT=8883` from your `.env` file in `Final_project/call-circle-docker/.env`.

### Step 2: Ensure nginx-proxy Includes Custom Config

The custom config file `nginx/conf.d/callcircle-8883.conf` should be automatically included by nginx-proxy. However, we need to ensure it's properly formatted and nginx-proxy can read it.

Verify the config file exists and is correct:

```bash
cat nginx/conf.d/callcircle-8883.conf
```

### Step 3: Restart Services in Correct Order

1. **Stop call-service** (if running with port 8883):

   ```bash
   docker stop call-service
   docker rm call-service
   ```

2. **Update call-service configuration** (remove PORT=8883 or use expose instead of ports)

3. **Restart proxy-server** to reload nginx config:

   ```bash
   cd ~/laravel-wegro-docker
   docker compose restart proxy-server
   ```

4. **Start call-service** (without port 8883):
   ```bash
   cd ~/Final_project/call-circle-docker
   # Use the correct compose file (prod.yml uses expose, which is correct)
   docker compose -f docker/composes/docker-compose.prod.yml up -d
   ```

### Step 4: Verify Configuration

1. **Check proxy-server is listening on 8883**:

   ```bash
   docker ps | grep proxy-server
   # Should show: 0.0.0.0:8883->8883/tcp
   ```

2. **Check call-service is NOT exposing 8883**:

   ```bash
   docker ps | grep call-service
   # Should show: 80/tcp (NOT 0.0.0.0:8883->80/tcp)
   ```

3. **Test SSL connection**:

   ```bash
   curl -Iv https://callcircle.resilentsolutions.com:8883/api/me
   # Should show successful SSL handshake
   ```

4. **Check nginx-proxy logs**:
   ```bash
   docker logs proxy-server --tail 50
   # Look for any errors about port 8883 or SSL
   ```

## Quick Fix Script

Run this on your server:

```bash
#!/bin/bash
# Fix port 8883 conflict

echo "1. Stopping call-service..."
docker stop call-service 2>/dev/null || true

echo "2. Removing call-service container..."
docker rm call-service 2>/dev/null || true

echo "3. Checking call-service .env file..."
cd ~/Final_project/call-circle-docker
if grep -q "PORT=8883" .env 2>/dev/null; then
    echo "   WARNING: PORT=8883 found in .env - this should be removed or changed"
    echo "   Edit .env and remove/change PORT=8883"
    read -p "   Press Enter after you've updated .env..."
fi

echo "4. Restarting proxy-server..."
cd ~/laravel-wegro-docker
docker compose restart proxy-server

echo "5. Starting call-service with correct config..."
cd ~/Final_project/call-circle-docker
# Use prod.yml which has expose instead of ports
docker compose -f docker/composes/docker-compose.prod.yml up -d call-service

echo "6. Verifying configuration..."
echo "   Proxy-server ports:"
docker ps | grep proxy-server | grep -o "0\.0\.0\.0:8883->8883/tcp" && echo "   ✓ Port 8883 exposed" || echo "   ✗ Port 8883 NOT exposed"
echo "   Call-service ports:"
docker ps | grep call-service | grep -o "0\.0\.0\.0:8883" && echo "   ✗ Port 8883 still exposed (WRONG!)" || echo "   ✓ Port 8883 NOT exposed (CORRECT!)"

echo ""
echo "Done! Test with: curl -Iv https://callcircle.resilentsolutions.com:8883/api/me"
```

## Alternative: Use Standard Port 443

If you don't specifically need port 8883, you can use the standard HTTPS port 443:

1. Remove port 8883 from proxy-server ports in `docker-compose.yml`
2. Remove `nginx/conf.d/callcircle-8883.conf`
3. Configure call-service with `VIRTUAL_HOST=callcircle.resilentsolutions.com` and let nginx-proxy handle SSL on port 443 automatically
4. Access via: `https://callcircle.resilentsolutions.com` (no port needed)

## Troubleshooting

### SSL Error: "wrong version number"

This usually means:

- The connection is going to the wrong service (call-service instead of proxy-server)
- nginx-proxy isn't properly configured for SSL on port 8883
- The custom config file isn't being included

**Fix**: Ensure call-service doesn't expose port 8883, and verify the nginx config is correct.

### Port Already Allocated Error

This means something is still using port 8883:

```bash
# Check what's using port 8883
sudo lsof -i :8883
# Or
sudo netstat -tulpn | grep 8883

# Kill the process if needed, or stop the conflicting container
```

### call-service Can't Connect to Redis/Database

This is normal - call-service should connect via Docker network, not via exposed ports. Ensure:

- call-service is on `wegro_development_network`
- Redis/database containers are on the same network
- No firewall rules blocking internal Docker network communication
