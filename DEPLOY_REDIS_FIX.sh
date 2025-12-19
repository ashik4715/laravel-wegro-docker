#!/bin/bash
# Deployment script to fix Redis security vulnerability on DigitalOcean server
# Run this script after updating docker-compose.yml on the server

echo "=== Redis Security Fix Deployment ==="
echo ""

# Step 1: Backup current docker-compose.yml
echo "1. Creating backup of docker-compose.yml..."
cp docker-compose.yml docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)
echo "   Backup created ✓"
echo ""

# Step 2: Pull latest docker-compose.yml (if using git) or ensure it's updated
echo "2. Ensure docker-compose.yml is updated with the fix (no ports section in redis service)"
echo ""

# Step 3: Recreate containers with updated configuration
echo "3. Recreating containers to apply configuration changes..."
echo "   (Using 'down' and 'up -d' to ensure network configuration changes are applied)"
docker compose down
docker compose up -d
echo "   Containers recreated ✓"
echo ""

# Step 4: Verify Redis is no longer exposed
echo "4. Verifying Redis port is no longer exposed..."
REDIS_PORTS=$(docker ps | grep redis | grep -o "0\.0\.0\.0:6379->6379/tcp" || echo "")
if [ -z "$REDIS_PORTS" ]; then
    echo "   ✓ SUCCESS: Redis port 6379 is no longer exposed publicly"
else
    echo "   ✗ WARNING: Redis port is still exposed! Please check docker-compose.yml"
fi
echo ""

# Step 5: Test internal Redis access
echo "5. Testing internal Redis access (should work)..."
if docker exec laravel-wegro-docker-redis-1 redis-cli ping 2>/dev/null | grep -q "PONG"; then
    echo "   ✓ SUCCESS: Internal Redis access works (returns PONG)"
else
    echo "   ⚠ Note: Could not test internal access (container name might be different)"
fi
echo ""

# Step 6: Check container status
echo "6. Current Redis container status:"
docker ps | grep redis
echo ""

echo "=== Deployment Complete ==="
echo ""
echo "Next steps:"
echo "- Verify external access is blocked: telnet $(hostname -I | awk '{print $1}') 6379"
echo "- Or test from external machine: telnet 138.68.55.52 6379 (should fail)"
echo "- Monitor application logs to ensure Redis connections still work"
