.PHONY: help up down restart ps logs pull backup restore update model shell env
.DEFAULT_GOAL := help

COMPOSE ?= docker compose
MODEL ?= llama3.2

help: ## Show this help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

env: ## Copy .env.example to .env if missing
	@test -f .env || (cp .env.example .env && echo "Created .env — edit secrets before starting")
	@test -f .env && echo ".env ready"

up: env ## Start the stack
	$(COMPOSE) up -d

down: ## Stop the stack
	$(COMPOSE) down

restart: ## Restart all services
	$(COMPOSE) restart

ps: ## Show container status
	$(COMPOSE) ps

logs: ## Follow logs (SERVICE=name optional)
	$(COMPOSE) logs -f $(SERVICE)

pull: ## Pull images without recreating
	$(COMPOSE) pull

backup: ## Backup data/ + Postgres dump to backups/
	@bash scripts/backup.sh

restore: ## Restore from ARCHIVE=backups/ai-stack-....tar.gz
	@test -n "$(ARCHIVE)" || (echo "Usage: make restore ARCHIVE=backups/ai-stack-YYYYMMDD-HHMMSS.tar.gz" && exit 1)
	@bash scripts/restore.sh "$(ARCHIVE)"

update: ## Backup, pull images, recreate stack
	@bash scripts/update.sh

model: ## Pull an Ollama model (MODEL=llama3.2)
	docker exec -it ollama ollama pull $(MODEL)

shell: ## Shell into a service (SERVICE=ollama)
	@test -n "$(SERVICE)" || (echo "Usage: make shell SERVICE=ollama" && exit 1)
	docker exec -it $(SERVICE) sh
