#!/bin/bash
# Quick fix script for port 8883 conflict
# Run this on your DigitalOcean server

set -e

echo "=== Fixing Port 8883 Conflict ==="
echo ""

# Step 1: Stop call-service
echo "1. Stopping call-service..."
docker stop call-service 2>/dev/null || echo "   call-service not running"
docker rm call-service 2>/dev/null || echo "   call-service container not found"
echo ""

# Step 2: Check and warn about PORT in .env
echo "2. Checking call-service configuration..."
if [ -f ~/Final_project/call-circle-docker/.env ]; then
    if grep -q "PORT=8883" ~/Final_project/call-circle-docker/.env; then
        echo "   ⚠ WARNING: PORT=8883 found in .env"
        echo "   This will cause a port conflict!"
        echo "   Please edit ~/Final_project/call-circle-docker/.env and:"
        echo "   - Remove PORT=8883, OR"
        echo "   - Change it to a different port (e.g., PORT=8080) for local access only"
        echo ""
        read -p "   Press Enter after you've updated .env, or Ctrl+C to cancel..."
    else
        echo "   ✓ No PORT=8883 found in .env"
    fi
else
    echo "   ⚠ .env file not found at ~/Final_project/call-circle-docker/.env"
fi
echo ""

# Step 3: Restart proxy-server
echo "3. Restarting proxy-server to reload nginx config..."
cd ~/laravel-wegro-docker
docker compose restart proxy-server
sleep 2
echo "   ✓ proxy-server restarted"
echo ""

# Step 4: Verify proxy-server has port 8883
echo "4. Verifying proxy-server configuration..."
PROXY_8883=$(docker ps | grep proxy-server | grep -o "0\.0\.0\.0:8883->8883/tcp" || echo "")
if [ -n "$PROXY_8883" ]; then
    echo "   ✓ proxy-server is listening on port 8883"
else
    echo "   ✗ proxy-server is NOT listening on port 8883"
    echo "   Check docker-compose.yml - port 8883 should be in proxy-server ports"
fi
echo ""

# Step 5: Start call-service (user needs to do this manually with correct config)
echo "5. Next steps to start call-service:"
echo "   cd ~/Final_project/call-circle-docker"
echo "   # Use docker-compose.prod.yml which uses 'expose' instead of 'ports'"
echo "   docker compose -f docker/composes/docker-compose.prod.yml up -d call-service"
echo ""
echo "   OR if using a different compose file, ensure it uses 'expose: - 80' not 'ports: - 8883:80'"
echo ""

# Step 6: Final verification
echo "6. After starting call-service, verify:"
echo "   docker ps | grep call-service"
echo "   # Should show: 80/tcp (NOT 0.0.0.0:8883->80/tcp)"
echo ""
echo "   Test SSL:"
echo "   curl -Iv https://callcircle.resilentsolutions.com:8883/api/me"
echo ""

echo "=== Fix Complete ==="
