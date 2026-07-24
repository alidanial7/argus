# Argus (AI Stack)

Self-hosted AI stack with local LLMs, chat UI, workflows, vector search, metasearch, and an Nginx reverse proxy.

## Stack

| Service    | Image                                | Access                      | Role                |
|------------|--------------------------------------|-----------------------------|---------------------|
| Nginx      | `nginx:1.29.8-alpine`                | `:80` / `:443`              | Reverse proxy / TLS |
| Open WebUI | `open-webui/open-webui:v0.6.31`      | `:3000` or `DOMAIN_WEBUI`   | Chat UI             |
| Ollama     | `ollama/ollama:0.11.6`               | `:11434`                    | Local LLM runtime   |
| n8n        | `n8nio/n8n:1.112.3`                  | `:5678` or `DOMAIN_N8N`     | Workflow automation |
| SearXNG    | `searxng/searxng:2026.7.22-ef8f6470e`| `DOMAIN_SEARXNG`            | Private metasearch  |
| Qdrant     | `qdrant/qdrant:v1.15.4`              | `DOMAIN_QDRANT`             | Vector database     |
| PostgreSQL | `postgres:17.6-alpine`               | internal                    | n8n database        |
| Redis      | `redis:8.2-alpine`                   | internal                    | Cache               |

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

| App        | Direct                 | Via Nginx (default)         |
|------------|------------------------|-----------------------------|
| Open WebUI | http://localhost:3000  | http://webui.localhost      |
| n8n        | http://localhost:5678  | http://n8n.localhost        |
| SearXNG    | —                      | http://search.localhost     |
| Qdrant     | —                      | http://qdrant.localhost     |
| Ollama API | http://localhost:11434 | —                           |
| Nginx health | —                    | http://localhost/healthz    |

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
├── nginx/
│   ├── nginx.conf
│   ├── snippets/
│   │   ├── proxy-params.conf
│   │   └── ssl-params.conf
│   └── templates/
│       ├── default.conf.template
│       ├── webui.conf.template
│       ├── n8n.conf.template
│       ├── searxng.conf.template
│       ├── qdrant.conf.template
│       └── webui-ssl.conf.template.example
├── searxng/
│   └── settings.yml
├── data/
│   ├── postgres/
│   ├── redis/
│   ├── ollama/
│   ├── open-webui/
│   ├── qdrant/
│   ├── n8n/
│   └── nginx/
│       ├── certs/
│       └── logs/
└── scripts/
    ├── backup.sh
    ├── restore.sh
    ├── update.sh
    └── generate-certs.sh
```

Nginx hostnames come from `.env` (`DOMAIN_*`). The official image runs `envsubst` on `nginx/templates/*.template` at container start.

## Makefile

```bash
make help      # list targets
make up        # start stack
make down      # stop stack
make ps        # status
make logs      # follow all logs
make logs SERVICE=nginx
make backup    # archive data/ + Postgres dump → backups/
make restore ARCHIVE=backups/ai-stack-YYYYMMDD-HHMMSS.tar.gz
make update    # backup → pull images → recreate
make certs     # self-signed TLS into data/nginx/certs/
make model MODEL=llama3.2
make shell SERVICE=ollama
```

## Environment

Copy `.env.example` → `.env` (gitignored). Important variables:

| Variable                   | Purpose                           |
|----------------------------|-----------------------------------|
| `TZ`                       | Container timezone                |
| `DOMAIN_WEBUI`             | Nginx `server_name` for Open WebUI|
| `DOMAIN_N8N`               | Nginx host for n8n                |
| `DOMAIN_SEARXNG`           | Nginx host for SearXNG            |
| `DOMAIN_QDRANT`            | Nginx host for Qdrant             |
| `POSTGRES_*`               | Postgres / n8n credentials        |
| `REDIS_PASSWORD`           | Redis auth                        |
| `N8N_ENCRYPTION_KEY`       | Encrypts n8n credentials at rest  |
| `WEBHOOK_URL`              | Public n8n webhook base URL       |
| `WEBUI_SECRET_KEY`         | Open WebUI session secret         |
| `QDRANT__SERVICE__API_KEY` | Qdrant API key                    |

For production, set real domains and point DNS at the host. Place Let's Encrypt (or other) certs in `data/nginx/certs/` as `fullchain.pem` + `privkey.pem`, enable an SSL template (see `webui-ssl.conf.template.example`), then recreate Nginx. Set `N8N_PROTOCOL=https` and `WEBHOOK_URL` accordingly.

### Optional local HTTPS

```bash
make certs
# then enable SSL templates under nginx/templates/ and restart nginx
```

## Backup & restore

```bash
make backup
make restore ARCHIVE=backups/ai-stack-20260101-120000.tar.gz
```

Backups include `data/`, a Postgres dump (when the DB is running), plus Nginx and SearXNG config. Archives go to `./backups/` (gitignored).

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
