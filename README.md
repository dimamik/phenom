# Phenom ⚡

An opinionated template for your new Phoenix project

## What's Included

### Core Stack

- **Phoenix 1.8** - Latest Phoenix with LiveView
- **PostgreSQL** - With `pgvector` support for vector operations
- **Tailwind CSS 4** - Modern utility-first CSS (no `tailwind.config.js` needed)
- **esbuild** - Fast JavaScript bundler
- **Heroicons** - Beautiful hand-crafted SVG icons

### Background Jobs & Scheduling

- **Oban** - Robust job processing and scheduling

### Development Tools

- **Credo** - Static code analysis for code quality
- **Phoenix LiveDashboard** - Real-time performance monitoring
- **Live Reload** - Automatic browser refresh on file changes
- **Dotenvy** - Environment variable management

### HTTP & APIs

- **Req** - Modern HTTP client (preferred over HTTPoison/Tesla)
- **Swoosh** - Email delivery

### Deployment Ready

- **Fly.io** - Streamlined deployment with remote builds
- **VPS/Docker** - GHCR-based deployments with Watchtower auto-updates
- **GitHub Actions** - Unified CI/CD with automatic deployments

### Monitoring & Observability

- **Telemetry** - Built-in metrics and instrumentation
- **Ecto PSQLExtras** - PostgreSQL performance insights

## Quick Start

### First Time Setup

1. **Clone and customize:**

   ```bash
   git clone https://github.com/dimamik/phenom.git my_app
   cd my_app
   ./setup
   ```

   This will prompt you to rename the app and set your GitHub handle.

2. **Install dependencies:**

   ```bash
   mix setup
   ```

3. **Start the server:**
   ```bash
   mix phx.server
   ```

Visit [`localhost:4000`](http://localhost:4000) 🚀

### Environment Configuration

Update `.env` file in the project root with your database credentials and other secrets.

You can generate PHX_SECRET_KEY_BASE using:

```bash
mix phx.gen.secret
```

## Development

### Useful Commands

```bash
# Run tests
mix test

# Format code
mix format

# Run static analysis
mix credo

# Check for compilation warnings
mix compile --warnings-as-errors

# Run all pre-commit checks
mix precommit

# Database operations
mix ecto.create     # Create database
mix ecto.migrate    # Run migrations
mix ecto.rollback   # Rollback last migration
mix ecto.reset      # Drop, create, and migrate database
```

## Deployment

Phenom includes two deployment strategies:

### 1. Fly.io (Recommended for Getting Started)

Quick, managed platform with excellent Phoenix support.

**Setup:**

```bash
fly launch
fly deploy
```

📖 [Full Fly.io deployment guide](deployment/fly/README.md)

### 2. VPS with Docker & GHCR

Self-hosted option using GitHub Container Registry and Docker Compose.

**Features:**

- Automatic deployments via GitHub Actions
- Watchtower for updates
- Nginx reverse proxy with automatic HTTPS
- Full control over infrastructure

📖 [Full VPS deployment guide](deployment/vps/README.md)

### Unified CI/CD

The repository includes a unified GitHub Actions workflow (`.github/workflows/test-deploy.yml`) that:

- ✅ Runs tests on all branches
- ✅ Deploys to Fly.io (if `FLY_API_TOKEN` secret exists)
- ✅ Builds and pushes Docker images to GHCR (if no Fly.io token)
- ✅ Shows all status checks on commits

**To enable Fly.io deployment:**
Add the `FLY_API_TOKEN` secret to your GitHub repository.

**To enable VPS/Docker deployment:**
If you're not deploying to Fly.io, images will automatically be pushed to GHCR.

## Project Structure

```
phenom/
├── lib/
│   ├── phenom/          # Business logic & contexts
│   ├── phenom_web/      # Web interface (controllers, live views, components)
│   └── phenom_web.ex    # Web-related imports & definitions
├── priv/
│   ├── repo/migrations/ # Database migrations
│   ├── repo/seeds.exs   # Seed data
│   └── static/          # Static assets
├── assets/
│   ├── js/              # JavaScript code
│   ├── css/             # CSS stylesheets
│   └── vendor/          # Third-party JS libraries
├── deployment/
│   ├── fly/             # Fly.io deployment guides
│   └── vps/             # VPS/Docker deployment guides
└── test/                # Test files
```

## Design Decisions

### Why These Libraries?

- **Req over HTTPoison/Tesla** - Modern, well-maintained HTTP client with better ergonomics
- **Oban** - Battle-tested job processing with persistence and retries
- **Credo** - Consistent code style across the team
- **Dotenvy** - Simple `.env` file support for local development

### Phoenix 1.8 Conventions

- Uses function components (`def component(assigns)`) over legacy `Phoenix.View`
- LiveView-first approach with server-rendered HTML
- Collocated CSS/JS in `assets/` directory
- Unified testing with `Phoenix.LiveViewTest` and `LazyHTML`

## Contributing

Feel free to open an issue or submit a pull request if you find bugs or want to contribute improvements!

## Learn More

- **Phoenix Framework:** https://www.phoenixframework.org/
- **Phoenix Guides:** https://hexdocs.pm/phoenix/overview.html
- **Phoenix Docs:** https://hexdocs.pm/phoenix
- **Elixir Forum:** https://elixirforum.com/c/phoenix-forum
- **Phoenix Source:** https://github.com/phoenixframework/phoenix

## License

MIT
