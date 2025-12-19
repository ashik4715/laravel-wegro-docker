# Redis Security Fix - Deployment Instructions

## What Was Fixed

The Redis service was exposing port 6379 to the public internet, which is a critical security vulnerability. The port mapping has been removed from `docker-compose.yml`. Redis will now only be accessible within the Docker network, which is the correct configuration.

## Files Changed

- ✅ `docker-compose.yml` - Removed port mapping from Redis service (lines 35-37)

## Deployment Steps on Server

### Step 1: Copy Updated docker-compose.yml to Server

Transfer the updated `docker-compose.yml` file to your DigitalOcean server:

```bash
# From your local machine, using SCP:
scp docker-compose.yml root@138.68.55.52:/path/to/laravel-wegro-docker/

# Or if using git:
# git pull on the server
```

### Step 2: SSH into Server

```bash
ssh root@138.68.55.52
```

### Step 3: Navigate to Directory

```bash
cd /path/to/laravel-wegro-docker
# (Adjust path to where your docker-compose.yml is located)
```

### Step 4: Backup Current Configuration

```bash
cp docker-compose.yml docker-compose.yml.backup.$(date +%Y%m%d_%H%M%S)
```

### Step 5: Verify docker-compose.yml is Updated

Check that the Redis service no longer has a `ports:` section:

```bash
grep -A 5 "^  redis:" docker-compose.yml
```

Should show:

```yaml
redis:
  image: redis:latest
  volumes:
    - redis_data:/data
  networks:
    - wegro_development_network
```

**NOT** this (which would be wrong):

```yaml
redis:
  image: redis:latest
  ports:
    - target: 6379
      published: 6379
```

### Step 6: Apply Configuration Changes

**Important:** Since we're changing network configuration (port mappings), we need to recreate the containers to ensure the changes take effect. A simple restart may not apply network configuration changes.

Recreate all containers with the updated configuration:

```bash
docker compose down
docker compose up -d
```

**Alternative (Redis only):** If you only want to recreate the Redis container:

```bash
docker compose up -d --force-recreate redis
```

However, using `down` and `up -d` is recommended to ensure all containers are in sync with the configuration file.

### Step 7: Verify the Fix

#### 7a. Check Redis Container Status

```bash
docker ps | grep redis
```

You should see the redis container **WITHOUT** the `0.0.0.0:6379->6379/tcp` port mapping. It should only show `6379/tcp` (internal port only).

**Before fix:**

```
e8a7611bb0a2   redis:latest   ...   0.0.0.0:6379->6379/tcp   laravel-wegro-docker-redis-1
```

**After fix:**

```
e8a7611bb0a2   redis:latest   ...   6379/tcp   laravel-wegro-docker-redis-1
```

#### 7b. Test External Access (Should Fail)

From the server or another machine:

```bash
telnet 138.68.55.52 6379
```

This should **fail** with "Connection refused" or timeout. If it connects, the fix hasn't been applied correctly.

#### 7c. Verify Internal Docker Network Access (Should Work)

```bash
docker exec laravel-wegro-docker-redis-1 redis-cli ping
```

Should return: `PONG`

This confirms Redis is still accessible to other containers via the Docker network.

### Step 8: Monitor Application Logs

Check that your applications (admin-portal, call-service) are still connecting to Redis successfully:

```bash
# Check application logs for any Redis connection errors
docker logs admin-portal --tail 50
docker logs call-service --tail 50
```

## Quick Deployment Script

Alternatively, you can use the provided script (make sure docker-compose.yml is updated first):

```bash
chmod +x DEPLOY_REDIS_FIX.sh
./DEPLOY_REDIS_FIX.sh
```

## Verification Checklist

- [ ] Redis container no longer shows `0.0.0.0:6379->6379/tcp` in `docker ps`
- [ ] External telnet test fails: `telnet 138.68.55.52 6379`
- [ ] Internal Redis access works: `docker exec laravel-wegro-docker-redis-1 redis-cli ping` returns PONG
- [ ] Application containers can still connect to Redis (check logs)
- [ ] No errors in application logs related to Redis

## Impact

- ✅ **No negative impact** - Applications will continue working because they connect via Docker network using the service name `redis`
- ✅ **Security improved** - Redis is no longer accessible from the public internet
- ✅ **Slave and Sentinel** - Already correctly configured (no ports exposed)

## Additional Security Recommendations

For defense in depth, consider adding a Redis password:

1. Add to `docker-compose.yml` redis service:

   ```yaml
   redis:
     image: redis:latest
     command: redis-server --requirepass your_strong_password_here
     volumes:
       - redis_data:/data
     networks:
       - wegro_development_network
   ```

2. Update application `.env` files:

   ```
   REDIS_PASSWORD=your_strong_password_here
   ```

3. Restart all services:
   ```bash
   docker compose down
   docker compose up -d
   ```
