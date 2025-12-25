# Phenom ⚡

[![Deploy to Fly](https://img.shields.io/badge/Deploy%20to-Fly-blueviolet?style=for-the-badge&logo=fly.io)](deployment/fly/README.md)
[![Deploy on VPS](https://img.shields.io/badge/Deploy%20on-VPS-blue?style=for-the-badge&logo=docker)](deployment/vps/README.md)

An opinionated Phoenix starter that lets you ship faster: start from a strong, production-ready baseline and focus on your idea instead of re-doing the same setup every time. Your AI agents will thank you.

## Getting started

```bash
# 1. Install the generator as a Mix archive (if not already)
mix archive.install github dimamik/phenom --force

# 2. Generate a new app
mix phenom.new my_new_app

# 3. Set it up and run it
cd my_new_app
mix setup
mix phx.server
```

## What's included

1. Web - [Phoenix](https://www.phoenixframework.org/) with [LiveView](https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html)
1. Database - [Ecto](https://hexdocs.pm/ecto/Ecto.html) with [Postgres](https://www.postgresql.org/)
1. Jobs - [Oban](https://hexdocs.pm/oban/Oban.html) and [Oban Web (dashboard)](https://hexdocs.pm/oban_web/installation.html)
1. HTTP Requests - [Req](https://hexdocs.pm/req/Req.html)
1. Code Analysis - [Credo](https://hexdocs.pm/credo/overview.html) and [Sobelow](https://hexdocs.pm/sobelow/Sobelow.html)
1. CI/CD - [GitHub Actions](https://docs.github.com/actions) and [Fly.io](https://fly.io/docs/) or your own VPS (e.g. [Hetzner](https://www.hetzner.com/cloud/)) with [GHCR](https://docs.github.com/packages/working-with-a-github-packages-registry/working-with-the-container-registry) docker images (included)

## What **will** be included in the future

1. Safer default CSP settings (so we don't need to skip them in Sobelow)
1. Live Debugger
1. Authorization framework
1. Better LLM instructions and pre-defined tooling
1. Improved favicons for better branding
1. And many, many more

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
