# Deploying Your app to Fly.io

This guide walks you through deploying your application to Fly.io.

## Prerequisites

1. **Install flyctl** (Fly.io CLI):

   ```bash
   curl -L https://fly.io/install.sh | sh
   ```

2. **Sign up / Log in to Fly.io**:

   ```bash
   flyctl auth signup  # or flyctl auth login
   ```

3. **Verify your account** via email if this is your first time.

## Initial Setup

### 1. Launch the App

From the project root, run:

```bash
flyctl launch
```

This will:

- Detect your Dockerfile automatically
- Create a `fly.toml` configuration file
- Prompt you to configure the app

**Important prompts:**

- **App name**: Choose a unique name (e.g., `phenom-prod`)
- **Region**: Choose the closest region to your users
- **PostgreSQL**: Say **YES** to create a Postgres cluster
  - Choose "Development" configuration (single node) or "Production" for HA
  - Note the connection string provided
- **Deploy now?**: Say **NO** - we need to set secrets first

### 2. Create PostgreSQL Database (if not created during launch)

If you skipped Postgres creation:

```bash
flyctl postgres create --name phenom-db
flyctl postgres attach phenom-db --app phenom-prod
```

This automatically sets the `DATABASE_URL` secret.

### 3. Set Environment Variables

Generate a secret key base:

```bash
mix phx.gen.secret
```

Set required secrets:

```bash
# Set the secret key base (replace with generated value)
flyctl secrets set SECRET_KEY_BASE=your_generated_secret_here

# Set the Phoenix host (use your fly.io app domain)
flyctl secrets set PHX_HOST=phenom-prod.fly.dev

# Enable the Phoenix server
flyctl secrets set PHX_SERVER=true

# Optional: Enable IPv6 for Ecto
flyctl secrets set ECTO_IPV6=true
```

### 4. Update fly.toml Configuration

Your `fly.toml` should look similar to this:

```toml
app = "phenom-prod"
primary_region = "sjc"

[build]

[env]
  PHX_HOST = "phenom-prod.fly.dev"

[http_service]
  internal_port = 4000
  force_https = true
  auto_stop_machines = "stop"
  auto_start_machines = true
  min_machines_running = 0
  processes = ["app"]

  [http_service.concurrency]
    type = "connections"
    hard_limit = 1000
    soft_limit = 1000

[[vm]]
  memory = "1gb"
  cpu_kind = "shared"
  cpus = 1

[checks]
  [checks.alive]
    grace_period = "30s"
    interval = "15s"
    method = "GET"
    timeout = "10s"
    path = "/"
```

### 5. Run Database Migrations

Create a release script for migrations. This is already available at `lib/phenom/release.ex`.

Add a `[deploy]` section to your `fly.toml`:

```toml
[deploy]
  release_command = "/app/bin/phenom eval Phenom.Release.migrate"
```

### 6. Deploy!

```bash
flyctl deploy
```

This will:

1. Build your Docker image
2. Push it to Fly.io
3. Run database migrations
4. Start your application

### 7. Verify Deployment

```bash
# Check app status
flyctl status

# View logs
flyctl logs

# Open app in browser
flyctl open
```

## Scaling

### Scale Vertically (more resources per machine)

```bash
flyctl scale vm shared-cpu-2x --memory 2048
```

### Scale Horizontally (more machines)

```bash
flyctl scale count 2  # Run 2 instances
```

### Auto-scaling

Edit `fly.toml` to configure auto-scaling:

```toml
[http_service]
  min_machines_running = 1
  max_machines_running = 5
  auto_start_machines = true
  auto_stop_machines = "stop"
```

## Database Management

### Connect to PostgreSQL

```bash
flyctl postgres connect -a phenom-db
```

### Run migrations manually

```bash
flyctl ssh console
/app/bin/phenom eval "Phenom.Release.migrate()"
```

### Backup database

```bash
flyctl postgres backup create -a phenom-db
flyctl postgres backup list -a phenom-db
```

## Monitoring & Debugging

### View application logs

```bash
flyctl logs
```

### SSH into the running machine

```bash
flyctl ssh console
```

### Open IEx console

```bash
flyctl ssh console -C "/app/bin/phenom remote"
```

### Check resource usage

```bash
flyctl status
flyctl metrics
```

## Environment-Specific Configuration

### Staging Environment

Create a staging app:

```bash
flyctl launch --name phenom-staging --copy-config --region sjc
flyctl postgres attach phenom-db --app phenom-staging
flyctl secrets set SECRET_KEY_BASE=staging_secret PHX_HOST=phenom-staging.fly.dev PHX_SERVER=true
flyctl deploy
```

## Troubleshooting

### App won't start

1. Check logs: `flyctl logs`
2. Verify secrets are set: `flyctl secrets list`
3. Check `DATABASE_URL` is properly configured
4. Ensure migrations ran successfully

### Database connection issues

```bash
# Check DATABASE_URL secret
flyctl secrets list

# Verify database is running
flyctl postgres list

# Check database connection from app
flyctl ssh console -C "/app/bin/phenom eval 'Phenom.Repo.query!(\"SELECT 1\")'"
```

### Memory issues

```bash
# Scale up memory
flyctl scale memory 2048
```

### Build failures

```bash
# Build locally first to debug
docker build -t phenom .

# Deploy specific Dockerfile
flyctl deploy --dockerfile Dockerfile
```

## Cost Optimization

- Use `auto_stop_machines = "stop"` for low-traffic apps
- Set `min_machines_running = 0` to scale to zero when idle
- Use "Development" Postgres for non-critical apps ($0 in free tier)
- Monitor usage: `flyctl dashboard`

## Additional Resources

- [Fly.io Elixir Documentation](https://fly.io/docs/elixir/)
- [Phoenix on Fly.io Guide](https://fly.io/docs/elixir/getting-started/)
- [Fly.io Postgres](https://fly.io/docs/postgres/)
- [Scaling on Fly.io](https://fly.io/docs/reference/scaling/)

## CI/CD with GitHub Actions

Create `.github/workflows/fly-deploy.yml`:

```yaml
name: Deploy to Fly.io

on:
  push:
    branches: [main]

jobs:
  deploy:
    name: Deploy app
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: superfly/flyctl-actions/setup-flyctl@master
      - run: flyctl deploy --remote-only
        env:
          FLY_API_TOKEN: ${{ secrets.FLY_API_TOKEN }}
```

Get your API token: `flyctl auth token` and add it to GitHub secrets.

## Quick Commands Reference

```bash
# Deploy
flyctl deploy

# View logs
flyctl logs

# SSH into machine
flyctl ssh console

# Open app
flyctl open

# Check status
flyctl status

# Scale
flyctl scale count 2
flyctl scale memory 2048

# Secrets
flyctl secrets list
flyctl secrets set KEY=value

# Database
flyctl postgres list
flyctl postgres connect -a phenom-db

# Regions
flyctl regions list
flyctl regions add sjc

# Restart app
flyctl apps restart
```
