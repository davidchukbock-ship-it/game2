# Throne Clash

**English** · [Русский](README.md)

A casual browser MMO strategy game with a medieval setting: build a castle, train an army, send marches across a shared world map, join guilds and climb the league. Built for short sessions — everything you build or train keeps going while you are offline.

![Castle](docs/screenshots/castle-desktop.png)

| World map                                | Army                                       | Quests                                         |
| ---------------------------------------- | ------------------------------------------ | ---------------------------------------------- |
| ![Map](docs/screenshots/map-desktop.png) | ![Army](docs/screenshots/army-desktop.png) | ![Quests](docs/screenshots/quests-desktop.png) |

Adventures (single-player mini-games):

| Arena                                       | Fishing                                          | Runes                                        |
| ------------------------------------------- | ------------------------------------------------ | -------------------------------------------- |
| ![Arena](docs/screenshots/play-desktop.png) | ![Fishing](docs/screenshots/fishing-desktop.png) | ![Runes](docs/screenshots/runes-desktop.png) |

On a phone (375 px):

<img src="docs/screenshots/castle-mobile.png" alt="Castle on mobile" width="200"> <img src="docs/screenshots/map-mobile.png" alt="Map on mobile" width="200"> <img src="docs/screenshots/quests-mobile.png" alt="Quests on mobile" width="200">

More screens are in [`docs/screenshots/`](docs/screenshots).

**What's new:** a panel-free interface (the castle and the map fill the screen, everything lives in the gear menu), a city on the island's free tiles with roads, piers and ships, a minimap, a modern look for the world, and single-player "Adventures" (arena, fishing, runes) with animation and sound. See [`CHANGELOG.md`](CHANGELOG.md).

> This folder is a **separate project** inside the repository. Run every command from `throne-clash/`, not from the repository root (that holds a different, older game that also uses port 5173).

> The in-game UI is Russian and English. Most design documents in `docs/` are written in Russian.

## Features (MVP v0.1.0)

1. **Accounts**: sign-up, login, guest play, profile and crest; roles `PLAYER` / `ADMIN` / `OWNER`.
2. **Castle and resources**: gold, wood, stone, food; storage caps; production is computed lazily, no DB ticks.
3. **Buildings and build queue**, gem speed-ups, cancel with partial refund.
4. **Army**: training, healing wounded units, food economy.
5. **Academy**: research.
6. **Hero**: levels, skills, gear, paper-doll.
7. **World map**: one shared world, bandit camps, resource nodes, fog, march limit.
8. **Marches and battles**: deterministic server-side combat, forecast, reports.
9. **Guilds**: applications, ranks, build help.
10. **Chat**: world, guild, direct messages, reports; real time over WebSocket.
11. **Notifications** for finished buildings, returning marches and attacks — even while you are offline.
12. **Quests and daily login**, tutorial.
13. **Chests** with public odds, **boosters**, **shop** (payment is a `NullPaymentProvider` stub).
14. **Leagues**: weekly seasons, rewards for participants only.
15. **Admin panel and God Mode** ([`docs/GOD_MODE.md`](docs/GOD_MODE.md), Russian): owner only, password (+ TOTP), audit log, snapshots, balance constructor.
16. **Abuse protection**: rate limits, idempotency keys, optimistic locking, security log.

Also: RU/EN interface, responsive layout (375–1440 px), accessibility (axe checks in CI), animations honoring `prefers-reduced-motion`.

## How it works

```mermaid
flowchart LR
  B["Browser<br/>React 18 · Vite · Tailwind"] -->|REST + WebSocket| S["Server<br/>Fastify 5 · Zod · Prisma"]
  S --> P[("PostgreSQL 16")]
  S -.->|rate limits| R[("Redis 7")]
  B -. "shared formulas" .-> H[["packages/shared"]]
  S -. "shared formulas" .-> H
```

The server is authoritative: the client renders state and forecasts, and every action is confirmed by the server. See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md), [`docs/API.md`](docs/API.md) (Swagger at `/docs` in development) and [`docs/DECISIONS.md`](docs/DECISIONS.md).

## Quick start

Requirements: Node.js 20+, pnpm (`corepack enable`), Docker (for PostgreSQL and Redis).

```bash
cd throne-clash
pnpm install
pnpm db:up          # PostgreSQL :5432 and Redis :6379 in Docker
pnpm db:generate    # Prisma client
pnpm db:migrate     # create tables
pnpm dev            # server :3000, web :5173
```

Open **http://localhost:5173**. No `.env` is needed for this mode.

Other ways to run (details in the [Russian README](README.md)):

- **Everything in Docker**: `cp .env.example .env`, set `JWT_ACCESS_SECRET` (32+ random chars — the server refuses to start in production with the placeholder), then `docker compose up --build` → game at http://localhost:8080, API and Swagger at http://localhost:3000/docs.
- **No Docker** (Windows): `start-windows.bat` downloads portable Node.js and `cloudflared`, starts an embedded PostgreSQL (`pnpm db:embedded`) and prints a public link. On other systems use `pnpm db:embedded` with `REDIS_URL=none`.
- **GitHub Codespaces**: the `.devcontainer/` config sets up Node, PostgreSQL and Redis; run `pnpm dev` and make port 5173 public.
- **Temporary public URL**: `pnpm share` (Cloudflare quick tunnel) while `pnpm dev` runs — for demos only.

## Configuration

Every variable is documented in [`.env.example`](.env.example): `DATABASE_URL`, `REDIS_URL` (`none` = in-memory limits, dev only), `JWT_ACCESS_SECRET`, `CORS_ORIGIN`, `OWNER_EMAIL`, `GOD_MODE_ENABLED`, `GOD_MODE_PASSWORD_HASH`, `GOD_MODE_TOTP_SECRET`, `PAYMENTS_MODE` (`off` default; `test` grants crystals for free, dev only), `SEED_DEMO*`, rate-limit knobs. Secrets are never committed. Generate the God Mode password hash with `pnpm god:hash` and a TOTP secret with `pnpm god:totp`.

## Roles and God Mode

A role can never be set through a request body. Register in the game with the e-mail from `OWNER_EMAIL`, then on the server run:

```bash
pnpm owner:grant    # asks for that account's password (hidden input)
```

The owner then opens `/god` (or presses `Ctrl+Shift+G`) and enters the God Mode password (and a TOTP code if enabled). Regular players and admins get a 404 / redirect. Every action is written to the audit log in the same transaction; castles touched by God Mode are excluded from leagues and economy stats.

## Checks

```bash
pnpm lint && pnpm format:check && pnpm typecheck
TEST_DATABASE_URL=postgresql://throne:throne@localhost:5432/throne_test pnpm test:coverage
pnpm test:e2e       # Playwright at 375 and 1440 px; needs `pnpm exec playwright install chromium`
pnpm screenshots    # refresh docs/screenshots
```

Server tests wipe tables — use a dedicated database. CI runs lint, formatting, types, tests with coverage, build, e2e and Docker image builds.

## Verified vs. not verified

Verified automatically in the dev environment: unit and integration tests on in-memory and real PostgreSQL repositories, and Chromium e2e flows at 375 and 1440 px: sign-up and login, building and speed-ups, training, marches (scouting a neighbour), two players in separate browsers, WebSocket chat, notifications, quests/chests/shop, God Mode and audit, accessibility (axe), language switch.

**Not verified on real systems** — please check yourself: the full `docker compose up --build`, `start-windows.bat` on Windows, GitHub Codespaces, and the nginx config with its CSP header (currently Report-Only). With `REDIS_URL=none` rate limits live in process memory; multiple server instances need Redis.

## Project links

[`docs/`](docs) · [`ROADMAP.md`](ROADMAP.md) · [`CHANGELOG.md`](CHANGELOG.md) · [`CONTRIBUTING.md`](CONTRIBUTING.md) · [`SECURITY.md`](SECURITY.md) · [`CREDITS.md`](CREDITS.md) (asset licenses) · [`LICENSE`](LICENSE) (MIT)
