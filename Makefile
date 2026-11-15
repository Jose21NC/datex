.PHONY: setup backend web test lint build samples globe static

setup:    ## Instala servidor y web
	cd backend && uv sync
	npm install
	@test -f .env || cp .env.example .env

backend:  ## API en http://localhost:8000 (docs en /docs)
	cd backend && uv run uvicorn app.main:app --reload

web:      ## Web en http://localhost:5173
	npm run dev

test:
	cd backend && uv run pytest -q

lint:
	cd backend && uv run ruff check .
	npm run lint

build:
	npm run build

samples:  ## Vuelve a descargar las muestras de NASA POWER
	cd backend && PYTHONPATH=. uv run python -u scripts/fetch_samples.py

globe:    ## Recalcula la malla del globo (2.592 celdas; ~15 min)
	cd backend && PYTHONPATH=. uv run python -u scripts/build_globe.py

static:   ## Regenera public/static-api con los datos locales
	cd backend && PYTHONPATH=. uv run python -u scripts/export_static_api.py
