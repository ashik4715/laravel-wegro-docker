# Fix Let's Encrypt Companion and Port 443 Connection Issues

## Issues Identified

1. **letsencrypt-companion crashing**: Can't find nginx-proxy container
2. **Port 443 connection refused**: Firewall or nginx configuration issue
3. **Firewall concern**: User worried about opening ports 80/443 affecting SSH

## Solutions Applied

### 1. Fixed letsencrypt-companion Configuration

**Problem**: The companion couldn't find the nginx-proxy container.

**Solution**:

- Added label `com.github.nginx-proxy.nginx` to proxy-server
- Added environment variable `NGINX_PROXY_CONTAINER=proxy-server` to letsencrypt-companion

### 2. Port 443 Connection Refused

**Possible causes**:

- Firewall blocking port 443
- Nginx not properly configured to listen on 443
- Custom config file not being loaded

**Solution**:

- Verify firewall allows ports 80/443
- Ensure custom SSL config is in place
- Restart proxy-server after changes

### 3. Firewall Safety (IMPORTANT)

**✅ SAFE TO OPEN PORTS 80/443**

**Why it's safe**:

- SSH uses port **22**, not 80/443
- Opening ports 80/443 will **NOT** affect your SSH connection
- Ports 80/443 are required for:
  - HTTP/HTTPS web traffic
  - Let's Encrypt certificate validation
  - Your website to be accessible

**What you need to do**:

```bash
# Open ports 80 and 443 (required for HTTPS)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp

# Verify SSH port is still open (should already be open)
sudo ufw status | grep 22
# Should show: 22/tcp ALLOW

# Reload firewall
sudo ufw reload
```

**Your SSH connection will remain unaffected** because:

- SSH uses port 22 (different from 80/443)
- UFW rules are additive (opening 80/443 doesn't close 22)
- You can verify with: `sudo ufw status`

## Deployment Steps

### Step 1: Pull Latest Changes

```bash
cd ~/laravel-wegro-docker
git pull origin main
```

### Step 2: Open Firewall Ports (Required)

```bash
# This is SAFE - won't affect SSH (port 22)
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw reload

# Verify ports are open
sudo ufw status
```

### Step 3: Restart Containers

```bash
# Restart proxy-server with new label
docker compose up -d proxy-server

# Restart letsencrypt-companion with new environment variable
docker compose up -d letsencrypt

# Verify both are running
docker ps | grep -E "proxy-server|letsencrypt"
```

### Step 4: Verify Configuration

```bash
# Check proxy-server logs
docker logs proxy-server --tail 50

# Check letsencrypt-companion logs (should no longer show errors)
docker logs letsencrypt-companion --tail 50

# Test HTTPS connection
curl -Iv https://callcircle.resilentsolutions.com
```

### Step 5: Verify SSL Certificate

```bash
# Check if certificates are accessible
ls -la /etc/letsencrypt/live/callcircle.resilentsolutions.com/

# Test SSL connection
openssl s_client -connect callcircle.resilentsolutions.com:443 -servername callcircle.resilentsolutions.com
```

## Troubleshooting

### If port 443 still refuses connection:

1. **Check if nginx is listening on 443**:

   ```bash
   docker exec proxy-server netstat -tlnp | grep 443
   # Should show: tcp 0 0 :::443 :::* LISTEN
   ```

2. **Check firewall status**:

   ```bash
   sudo ufw status verbose
   # Should show: 80/tcp ALLOW and 443/tcp ALLOW
   ```

3. **Check if custom config is loaded**:

   ```bash
   docker exec proxy-server nginx -t
   # Should show: configuration file test is successful

   docker exec proxy-server cat /etc/nginx/conf.d/callcircle-80-ssl.conf
   # Should show the SSL configuration
   ```

4. **Reload nginx configuration**:
   ```bash
   docker exec proxy-server nginx -s reload
   ```

### If letsencrypt-companion still crashes:

1. **Verify labels on proxy-server**:

   ```bash
   docker inspect proxy-server | grep -A 5 Labels
   # Should show: "com.github.nginx-proxy.nginx": ""
   ```

2. **Verify environment variable**:

   ```bash
   docker inspect letsencrypt-companion | grep -A 5 Env
   # Should show: "NGINX_PROXY_CONTAINER=proxy-server"
   ```

3. **Check container logs**:
   ```bash
   docker logs letsencrypt-companion --tail 100
   ```

## Important Notes

- **SSH will NOT be affected** by opening ports 80/443
- Port 22 (SSH) is completely separate from ports 80/443 (HTTP/HTTPS)
- You can always verify your SSH connection is still working
- If you're still concerned, you can test SSH connection in a separate terminal before reloading firewall

## Verification Checklist

- [ ] Firewall allows ports 80 and 443
- [ ] proxy-server is running with correct labels
- [ ] letsencrypt-companion is running without errors
- [ ] Custom SSL config file exists in nginx/conf.d/
- [ ] Port 443 is accessible (curl test succeeds)
- [ ] SSL certificate is valid
- [ ] SSH connection still works (port 22)
