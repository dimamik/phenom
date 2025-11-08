# Deploying Your App to Hetzner VPS with Docker Compose

This guide provides step-by-step instructions for deploying your Phoenix application to a Hetzner VPS (Virtual Private Server) using Docker Compose with Nginx as a reverse proxy.

## Table of Contents

1. [Server Setup](#server-setup)
2. [Initial Configuration](#initial-configuration)
3. [Docker Installation](#docker-installation)
4. [Nginx Reverse Proxy Setup](#nginx-reverse-proxy-setup)
5. [SSL/TLS with Let's Encrypt](#ssltls-with-lets-encrypt)
6. [Application Deployment](#application-deployment)
7. [Monitoring & Maintenance](#monitoring--maintenance)
8. [Troubleshooting](#troubleshooting)

## Server Setup

### 1. Create a Hetzner VPS

1. Go to [Hetzner Cloud Console](https://console.hetzner.cloud/)
2. Create a new project
3. Click **"Add Server"**
4. Choose your configuration:

   - **Location**: Choose closest to your users (e.g., `Nuremberg`, `Helsinki`, `Ashburn`)
   - **Image**: Ubuntu 24.04 LTS (recommended)
   - **Type**: CX22 or higher (2 vCPU, 4GB RAM minimum for production)
   - **Volume**: Optional backup volume
   - **SSH Key**: Add your SSH public key
   - **Firewall**: We'll configure this next

5. Create the server and note the IP address

### 2. Configure Firewall

Create a firewall in Hetzner Cloud:

- **SSH**: Port 22 (from your IP only, if possible)
- **HTTP**: Port 80 (0.0.0.0/0)
- **HTTPS**: Port 443 (0.0.0.0/0)

Or via CLI:

```bash
# Install hcloud CLI
brew install hcloud  # macOS
# or: go install github.com/hetznercloud/cli/cmd/hcloud@latest

# Login
hcloud context create your_app

# Create firewall
hcloud firewall create --name your_app-fw

# Add rules
hcloud firewall add-rule your_app-fw --direction in --protocol tcp --port 22 --source-ips 0.0.0.0/0
hcloud firewall add-rule your_app-fw --direction in --protocol tcp --port 80 --source-ips 0.0.0.0/0
hcloud firewall add-rule your_app-fw --direction in --protocol tcp --port 443 --source-ips 0.0.0.0/0

# Apply to server
hcloud firewall apply-to-resource your_app-fw --type server --server <server-name>
```

### 3. Initial Server Access

```bash
ssh root@<your-server-ip>
```

## Initial Configuration

### 1. Update System

```bash
apt update && apt upgrade -y
```

### 2. Create Non-Root User

````bash
```sh
adduser your_app
````

```sh
usermod -aG sudo your_app
```

```sh
usermod -aG docker your_app
```

```sh
rsync --archive --chown=your_app:your_app ~/.ssh /home/your_app
```

### 3. Configure SSH Security

Edit SSH config:

```bash
nano /etc/ssh/sshd_config
```

Recommended settings:

```
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
```

Restart SSH:

```bash
systemctl restart sshd
```

### 4. Set Up UFW Firewall (optional, if not using Hetzner Firewall)

```bash
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable
```

## Docker Installation

### 1. Install Docker

```bash
# Add Docker's official GPG key
apt-get update
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

# Add Docker repository
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### 2. Verify Installation

```bash
docker --version
docker compose version
```

### 3. Enable Docker on Boot

```bash
systemctl enable docker
systemctl start docker
```

## Nginx Reverse Proxy Setup

We'll use Nginx Proxy Manager as a reverse proxy with a web UI to route traffic to your Phoenix app and manage SSL certificates.

### 1. Create Nginx Proxy Network

```bash
docker network create nginx_network
```

### 2. Set Up Nginx Proxy Manager

Create a directory for Nginx Proxy Manager:

```bash
mkdir -p /opt/nginx-proxy-manager
cd /opt/nginx-proxy-manager
```

Create `docker-compose.yml`:

```yaml
version: "3.8"
services:
  nginx:
    image: "jc21/nginx-proxy-manager:latest"
    container_name: nginx
    restart: unless-stopped
    ports:
      - 80:80
      - 81:81 # Admin UI (can be commented out after initial setup)
      - 443:443
    networks:
      - nginx_network
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt

networks:
  nginx_network:
    name: nginx_network
    external: true
```

### 3. Start Nginx Proxy Manager

```bash
docker compose up -d
```

### 4. Access Admin Panel

1. Open your browser and navigate to `http://<your-server-ip>:81`
2. Log in with default credentials:
   - **Email**: `admin@example.com`
   - **Password**: `changeme`
3. You'll be prompted to change these credentials immediately
4. Set your new admin email and password

### 5. Verify Nginx is Running

```bash
docker ps | grep nginx
curl http://localhost
```

**Security Note**: After initial setup, you can comment out port `81:81` in the docker-compose.yml to hide the admin panel from external access. You can still access it via SSH tunnel:

```bash
# On your local machine
ssh -L 8081:localhost:81 your_app@<your-server-ip>

# Then access admin panel at http://localhost:8081
```

## SSL/TLS with Let's Encrypt

SSL certificates are automatically provisioned through Nginx Proxy Manager's web interface.

### 1. Point Your Domain to Server

Create DNS A records:

```
your-domain.com      -> <your-server-ip>
www.your-domain.com  -> <your-server-ip>
```

Wait for DNS propagation (check with `nslookup your-domain.com`).

### 2. Configure Proxy Host in Nginx Proxy Manager

After deploying your application (next section), configure the proxy host:

1. Log into Nginx Proxy Manager admin panel (`http://<your-server-ip>:81`)
2. Go to **Hosts** → **Proxy Hosts** → **Add Proxy Host**
3. In the **Details** tab:
   - **Domain Names**: `your-domain.com`, `www.your-domain.com`
   - **Scheme**: `http`
   - **Forward Hostname / IP**: `your_app` (the container name)
   - **Forward Port**: `4000`
   - Enable: **Cache Assets**, **Block Common Exploits**, **Websockets Support**
4. In the **SSL** tab:
   - Select **Request a new SSL Certificate**
   - Enable **Force SSL**
   - Enable **HTTP/2 Support**
   - Enable **HSTS Enabled**
   - **Email Address**: your-email@example.com
   - Agree to Let's Encrypt Terms of Service
5. Click **Save**

The SSL certificate will be automatically issued and renewed.

## Application Deployment

### 1. Set Up Application Directory

```bash
# Switch to your_app user
su - your_app

# Create application directory
mkdir -p ~/your_app
cd ~/your_app
```

### 2. Create Environment File

```bash
nano .env
```

Add your environment variables:

```bash
# Database
DATABASE_URL=ecto://your_app_user:secure_password_here@your_app_postgres/your_app_prod
POSTGRES_USER=your_app_user
POSTGRES_DB=your_app_prod
POSTGRES_PASSWORD=secure_password_here

# Phoenix
SECRET_KEY_BASE=generate_with_mix_phx_gen_secret
PHX_HOST=your-domain.com
PHX_SERVER=true
PORT=4000

# Optional
ECTO_IPV6=false
POOL_SIZE=10
```

Generate `SECRET_KEY_BASE`:

```bash
# On your local machine (with Elixir installed)
mix phx.gen.secret

# Or use openssl
openssl rand -base64 64
```

**Important**: Set secure passwords and keep `.env` file permissions restricted:

```bash
chmod 600 .env
```

### 3. Create Docker Compose File

```bash
nano docker-compose.yml
```

Use the following configuration:

```yaml
services:
  your_app_postgres:
    image: pgvector/pgvector:pg17
    container_name: your_app_postgres
    restart: always
    environment:
      - POSTGRES_USER
      - POSTGRES_PASSWORD
      - POSTGRES_DB
    networks:
      - your_app_network
    expose:
      - 5432
    volumes:
      - your_app_db:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U $$POSTGRES_USER -d $$POSTGRES_DB"]
      interval: 5s
      timeout: 2s
      retries: 10

  your_app:
    image: index.docker.io/your_dockerhub_username/your_app:latest
    container_name: your_app
    restart: always
    networks:
      - nginx_network
      - your_app_network
    expose:
      - 4000
    depends_on:
      your_app_postgres:
        condition: service_healthy
    env_file:
      - ${PWD}/.env
    labels:
      - "com.centurylinklabs.watchtower.scope=your_app"

  your_app_watchtower:
    image: containrrr/watchtower
    container_name: your_app_watchtower
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - /home/your_app/.docker/config.json:/config.json
    command: --interval 300 --cleanup --scope your_app
    depends_on:
      - your_app
    restart: unless-stopped

volumes:
  your_app_db:
    driver: local

networks:
  nginx_network:
    name: nginx_network
    external: true
  your_app_network:
    name: your_app_network
    driver: bridge
```

**Note**: With Nginx Proxy Manager, you don't need `VIRTUAL_HOST` or `LETSENCRYPT_HOST` environment variables. The routing and SSL are configured through the web UI.

**Replace**:

- `your-domain.com` with your actual domain
- `your-email@example.com` with your email

### 4. Deploy Application

```bash
# Pull and start services
docker compose up -d

# View logs
docker compose logs -f

# Check status
docker compose ps
```

### 5. Run Database Migrations

````bash
# Run migrations
```sh
docker compose exec your_app /app/bin/your_app eval "YourApp.Release.migrate()"
````

### 6. Verify Deployment

```bash
# Check if containers are running
docker compose ps

# Check app logs
docker compose logs your_app

# Test HTTP
curl http://your-domain.com

# Test HTTPS (after certificate is issued, ~2 minutes)
curl https://your-domain.com
```

## Automatic Deployments with Watchtower

Watchtower automatically updates your app when a new image is pushed to Docker Hub.

### 1. Build and Push Image

On your local machine:

```bash
# Build image
docker build -t index.docker.io/your_dockerhub_username/your_app:latest .

# Login to Docker Hub
docker login

# Push image
docker push index.docker.io/your_dockerhub_username/your_app:latest
```

### 2. Watchtower Auto-Update

Watchtower (already configured in docker-compose.yml) checks every 5 minutes for new images and automatically:

- Pulls the new image
- Stops the old container
- Starts a new container
- Cleans up old images

**To disable auto-updates**, remove the `your_app_watchtower` service from docker-compose.yml.

## Monitoring & Maintenance

### View Logs

````bash
# All logs
docker compose logs

# Follow logs
docker compose logs -f

# Specific service
```sh
docker compose logs your_app
docker compose logs your_app_postgres

# Last 100 lines
docker compose logs --tail=100
````

### Application Management

```bash
# Restart app
docker compose restart your_app

# Restart all services
docker compose restart

# Stop services
docker compose stop

# Start services
docker compose start

# Rebuild and restart
docker compose up -d --build
```

### Database Management

```bash
# Connect to PostgreSQL
docker compose exec your_app_postgres psql -U your_app_user -d your_app_prod

# Backup database
docker compose exec your_app_postgres pg_dump -U your_app_user your_app_prod > backup_$(date +%Y%m%d).sql

# Restore database
docker compose exec -T your_app_postgres psql -U your_app_user -d your_app_prod < backup_20231108.sql

# View database size
docker compose exec your_app_postgres psql -U your_app_user -d your_app_prod -c "SELECT pg_size_pretty(pg_database_size('your_app_prod'));"
```

### System Resources

```bash
# Container stats
docker stats

# Disk usage
docker system df

# Clean up unused resources
docker system prune -a

# View volumes
docker volume ls
```

### Update System Packages

```bash
# Update packages
sudo apt update && sudo apt upgrade -y

# Reboot if kernel updated
sudo reboot
```

## Backup Strategy

### 1. Automated Database Backups

Create a backup script:

```bash
sudo nano /usr/local/bin/backup-your_app-db.sh
```

```bash
#!/bin/bash
BACKUP_DIR="/home/your_app/backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_FILE="$BACKUP_DIR/your_app_backup_$DATE.sql.gz"

mkdir -p $BACKUP_DIR

docker compose -f /home/your_app/your_app/docker-compose.yml exec -T your_app_postgres \
  pg_dump -U your_app_user your_app_prod | gzip > $BACKUP_FILE

# Keep only last 7 days of backups
find $BACKUP_DIR -name "your_app_backup_*.sql.gz" -mtime +7 -delete

echo "Backup completed: $BACKUP_FILE"
```

Make executable:

```bash
sudo chmod +x /usr/local/bin/backup-your_app-db.sh
```

### 2. Schedule with Cron

```bash
sudo crontab -e
```

Add daily backup at 2 AM:

```
0 2 * * * /usr/local/bin/backup-your_app-db.sh >> /var/log/your_app-backup.log 2>&1
```

### 3. Off-site Backups (Optional)

Use `rclone` to sync backups to cloud storage:

```bash
# Install rclone
curl https://rclone.org/install.sh | sudo bash

# Configure remote (e.g., AWS S3, Backblaze B2)
rclone config

# Sync backups
rclone sync /home/your_app/backups remote:your_app-backups
```

## Security Best Practices

### 1. Keep Docker Updated

```bash
sudo apt update
sudo apt upgrade docker-ce docker-ce-cli containerd.io
```

### 2. Use Docker Secrets (Optional)

For enhanced security, consider using Docker Swarm secrets or external secret management.

### 3. Regular Security Audits

```bash
# Check for vulnerable images
docker scout cves index.docker.io/dimamik/your_app:latest

# Update base images regularly
docker pull pgvector/pgvector:pg17
docker compose up -d
```

### 4. Restrict SSH Access

```bash
# Edit SSH config
sudo nano /etc/ssh/sshd_config

# Set specific users only
AllowUsers your_app

# Restart SSH
sudo systemctl restart sshd
```

### 5. Enable Automatic Security Updates

```bash
sudo apt install unattended-upgrades
sudo dpkg-reconfigure --priority=low unattended-upgrades
```

## Troubleshooting

### App Won't Start

```bash
# Check logs
docker compose logs your_app

# Common issues:
# 1. Database not ready - wait for healthcheck
# 2. Missing environment variables - check .env file
# 3. Port conflicts - ensure port 4000 is available internally
```

### Database Connection Issues

```bash
# Check if postgres is running
docker compose ps your_app_postgres

# Check postgres logs
docker compose logs your_app_postgres

# Test connection from app container
docker compose exec your_app /app/bin/your_app eval "Phenom.Repo.query!(\"SELECT 1\")"

# Check network
docker network inspect your_app_network
```

### SSL Certificate Issues

```bash
# Check Nginx Proxy Manager logs
docker logs nginx

# Verify DNS
nslookup your-domain.com

# Check SSL certificate status in Nginx Proxy Manager
# Log into admin panel at http://<your-server-ip>:81
# Go to SSL Certificates to see status and renew if needed

# Restart Nginx Proxy Manager
docker compose -f /opt/nginx-proxy-manager/docker-compose.yml restart
```

### High Memory Usage

```bash
# Check container stats
docker stats

# Restart specific service
docker compose restart your_app

# Scale down database pool
# Edit .env: POOL_SIZE=5
docker compose up -d
```

### Disk Space Issues

```bash
# Check disk usage
df -h

# Clean Docker resources
docker system prune -a --volumes

# Clean old logs
sudo journalctl --vacuum-time=7d
```

### Container Won't Stop

```bash
# Force stop
docker compose kill your_app

# Remove container
docker compose rm -f your_app

# Restart
docker compose up -d your_app
```

## Performance Tuning

### 1. Optimize PostgreSQL

Edit docker-compose.yml to add postgres configuration:

```yaml
your_app_postgres:
  command: postgres -c shared_buffers=256MB -c max_connections=100
```

### 2. Increase Pool Size

Edit `.env`:

```bash
POOL_SIZE=20
```

### 3. Add HTTP/2 Support

Nginx proxy already supports HTTP/2 over HTTPS automatically.

## Cost Estimation

**Hetzner VPS Costs** (as of 2025):

- **CX22** (2 vCPU, 4GB RAM): ~€5.83/month
- **CX32** (4 vCPU, 8GB RAM): ~€11.66/month
- **CX42** (8 vCPU, 16GB RAM): ~€23.33/month

**Additional Costs**:

- Backups (20% of server cost): Optional
- Volume storage: €0.045/GB/month
- Traffic: Free (20TB included)

## Scaling

### Vertical Scaling (More Resources)

1. Go to Hetzner Console
2. Power off server
3. Resize server (upgrade plan)
4. Power on server

Or via CLI:

```bash
hcloud server poweroff <server-name>
hcloud server change-type <server-name> cx32
hcloud server poweron <server-name>
```

### Horizontal Scaling (Multiple Servers)

For high availability, consider:

- Multiple app servers behind a load balancer
- Managed PostgreSQL (Hetzner Cloud SQL or external)
- Redis for session storage
- Object storage for uploads (Hetzner Cloud Storage)

## Useful Commands Cheat Sheet

```bash
# Docker Compose
docker compose up -d              # Start services
docker compose down               # Stop and remove services
docker compose restart            # Restart services
docker compose logs -f            # Follow logs
docker compose ps                 # List services
docker compose pull               # Pull latest images

# Application
docker compose exec your_app /app/bin/your_app remote  # IEx console
docker compose exec your_app /app/bin/your_app eval "code"  # Run Elixir code

# Database
docker compose exec your_app_postgres psql -U your_app_user -d your_app_prod
docker compose exec your_app_postgres pg_dump -U your_app_user your_app_prod > backup.sql

# System
docker ps                         # List containers
docker stats                      # Resource usage
docker system df                  # Disk usage
docker system prune -a            # Clean up

# Logs
journalctl -u docker -f           # Docker service logs
tail -f /var/log/nginx/error.log  # Nginx errors (if installed)
```

## Additional Resources

- [Hetzner Cloud Docs](https://docs.hetzner.com/cloud/)
- [Docker Compose Documentation](https://docs.docker.com/compose/)
- [Nginx Proxy Manager](https://nginxproxymanager.com/)
- [Let's Encrypt](https://letsencrypt.org/docs/)
- [Phoenix Deployment Guide](https://hexdocs.pm/phoenix/deployment.html)

## Support

For issues specific to:

- **Hetzner**: https://docs.hetzner.com/
- **Docker**: https://docs.docker.com/
- **Phoenix**: https://hexdocs.pm/phoenix/
- **This app**: Create an issue in the repository
