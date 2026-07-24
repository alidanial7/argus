# Argus (AI Stack)

Self-hosted AI stack with local LLMs, chat UI, workflows, vector search, metasearch, and a Caddy reverse proxy.

## Stack

| Service    | Image                              | Access                         | Role                 |
|------------|------------------------------------|--------------------------------|----------------------|
| Caddy      | `caddy:2.10-alpine`                | `:80` / `:443`                 | Reverse proxy / TLS  |
| Open WebUI | `open-webui:v0.6.31`               | `:3000` or `DOMAIN_WEBUI`      | Chat UI              |
| Ollama     | `ollama/ollama:0.11.6`             | `:11434`                       | Local LLM runtime    |
| n8n        | `n8nio/n8n:1.112.3`                | `:5678` or `DOMAIN_N8N`        | Workflow automation  |
| SearXNG    | `searxng/searxng`                  | `DOMAIN_SEARXNG`               | Private metasearch   |
| Qdrant     | `qdrant/qdrant:v1.15.4`            | `DOMAIN_QDRANT`                | Vector database      |
| PostgreSQL | `postgres:17.6-alpine`             | internal                       | n8n database         |
| Redis      | `redis:8.2-alpine`                 | internal                       | Cache                |

All services share the `ai` Docker network. Persistent data lives under `./data/`.

## Quick start

```bash
cp .env.example .env
# Edit .env — set strong secrets for POSTGRES_*, REDIS_PASSWORD,
# N8N_ENCRYPTION_KEY, WEBUI_SECRET_KEY, QDRANT__SERVICE__API_KEY

make up
# or: docker compose up -d
```

Also change `server.secret_key` in `searxng/settings.yml`.

Then open:

| App        | Direct              | Via Caddy (default)            |
|------------|---------------------|--------------------------------|
| Open WebUI | http://localhost:3000 | http://webui.localhost       |
| n8n        | http://localhost:5678 | http://n8n.localhost         |
| SearXNG    | —                   | http://search.localhost        |
| Qdrant     | —                   | http://qdrant.localhost        |
| Ollama API | http://localhost:11434 | —                           |

Pull a model:

```bash
make model MODEL=llama3.2
# or: docker exec -it ollama ollama pull llama3.2
```

## Project layout

```
ai-stack/
├── docker-compose.yml
├── .env.example
├── .gitignore
├── Makefile
├── README.md
├── caddy/
│   └── Caddyfile
├── searxng/
│   └── settings.yml
├── data/
│   ├── postgres/
│   ├── redis/
│   ├── ollama/
│   ├── open-webui/
│   ├── qdrant/
│   ├── n8n/
│   └── caddy/
└── scripts/
    ├── backup.sh
    ├── restore.sh
    └── update.sh
```

## Makefile

```bash
make help      # list targets
make up        # start stack
make down      # stop stack
make ps        # status
make logs      # follow all logs
make logs SERVICE=n8n
make backup    # archive data/ + Postgres dump → backups/
make restore ARCHIVE=backups/ai-stack-YYYYMMDD-HHMMSS.tar.gz
make update    # backup → pull images → recreate
make model MODEL=llama3.2
make shell SERVICE=ollama
```

## Environment

Copy `.env.example` → `.env` (gitignored). Important variables:

| Variable                 | Purpose                              |
|--------------------------|--------------------------------------|
| `TZ`                     | Container timezone                   |
| `DOMAIN_WEBUI`           | Caddy host for Open WebUI            |
| `DOMAIN_N8N`             | Caddy host for n8n                   |
| `DOMAIN_SEARXNG`         | Caddy host for SearXNG               |
| `DOMAIN_QDRANT`          | Caddy host for Qdrant                |
| `ACME_EMAIL`             | Let's Encrypt email (real domains)   |
| `POSTGRES_*`             | Postgres / n8n credentials           |
| `REDIS_PASSWORD`         | Redis auth                           |
| `N8N_ENCRYPTION_KEY`     | Encrypts n8n credentials at rest     |
| `WEBHOOK_URL`            | Public n8n webhook base URL          |
| `WEBUI_SECRET_KEY`       | Open WebUI session secret            |
| `QDRANT__SERVICE__API_KEY` | Qdrant API key                     |

For production, set real domains (e.g. `chat.example.com`) and `N8N_PROTOCOL=https` / `WEBHOOK_URL=https://…`. Caddy will obtain certificates automatically.

## Backup & restore

```bash
make backup
make restore ARCHIVE=backups/ai-stack-20260101-120000.tar.gz
```

Backups include `data/`, a Postgres dump (when the DB is running), plus `Caddyfile` and SearXNG settings. Archives are written to `./backups/` (gitignored).

## Update

```bash
make update
```

Runs a backup, pulls images, recreates containers, and prunes dangling images.

## Notes

- Open WebUI uses Ollama at `http://ollama:11434` and SearXNG at `http://searxng:8080`.
- n8n waits for Postgres to be healthy before starting.
- Ollama `mem_limit` is 10g — adjust in `docker-compose.yml` for your host.
- Runtime files under `data/` are gitignored; empty dirs are kept with `.gitkeep`.
- Change default passwords and secret keys before exposing the stack to a network.
