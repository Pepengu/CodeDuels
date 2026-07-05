# CodeDuels

Competitive programming tournament platform. Players solve algorithmic problems in timed Swiss-system rounds with head-to-head duels. Submissions are judged in a sandboxed Docker container.

## Tech

**Backend:** Elixir ~> 1.15, Phoenix ~> 1.8, LiveView, Ecto (PostgreSQL)  
**Frontend:** Tailwind CSS v4, daisyUI v5, esbuild, Heroicons  
**Judge:** Sandboxed Docker runner (C++17/23, Python/PyPy, Java, Go)  

## Prerequisites

- Elixir ~> 1.15, Erlang, PostgreSQL
- Docker (for judging submissions)
- Node.js / npm (for esbuild)

## Quick start

```bash
mix setup            # install deps, create DB, run migrations, seed
mix phx.server       # visit http://localhost:4000
```

Default admin credentials are printed at startup (set via `ADMIN_USERNAME` / `ADMIN_PASSWORD` in `.env`).

Build the judge container (required for submissions) — runner source: [Pepengu/Runner](https://github.com/Pepengu/Runner):

```bash
cd lib/code_duels/runner/Docker
docker build -t code-duels-runner .
```

## Importing problems

Place Polygon-format ZIP archives in `priv/uploads/problems/` (folder name = problem ID) or import programmatically:

```bash
mix run -e "CodeDuels.Problems.Importer.import_from_zip(\"path/to/problem.zip\")"
```

## Features

- Swiss-system tournaments with configurable rounds, timing, and scoring
- Head-to-head duels with real-time standings
- Polygon-format problem import (ZIP upload or URL)
- Asynchronous sandboxed code judging (Docker, resource-limited)
- Live updating submission status via PubSub
- Dark/light theme toggle

## Configuration

Key env vars — see `.env`:

| Variable | Description |
|---|---|
| `DATABASE_URL` | PostgreSQL connection string |
| `SECRET_KEY_BASE` | Phoenix signing key |
| `ADMIN_USERNAME` / `ADMIN_PASSWORD` | Default admin credentials |

## Project structure

```
lib/
  code_duels/               # Contexts (accounts, tournaments, problems, runner)
  code_duels_web/           # Web layer (LiveViews, controllers, components)
    live/                   # LiveView modules
    components/             # Layouts, core components
  code_duels/runner/Docker/ # Judge container (Rust + languages)
priv/
  repo/migrations/          # Ecto migrations
  repo/seeds.exs            # Sample data (admin, test users, tournament)
```

## License

MIT
