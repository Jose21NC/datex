# DATEX

¿El clima está cambiando de verdad? DATEX separa el cambio real de las falsas alarmas con 40 años de datos de la NASA.

Hecho por Boreal Labs para el NASA Space Apps Challenge 2026. Demo: https://jose21nc.github.io/datex/

El repo trae todo el proyecto: la web (React, en la raíz) y el servidor (Python + FastAPI, en `backend/`).

## Solo la web

```bash
npm install
npm run dev
```

Abre http://localhost:5173. Sin servidor, la web usa los datos precalculados de `public/static-api` y calcula en el navegador.

## Web + servidor

Hace falta [uv](https://docs.astral.sh/uv/).

```bash
cp .env.example .env    # pon VITE_API_URL=http://localhost:8000; las claves son opcionales
make setup
make backend            # API en http://localhost:8000 (documentación en /docs)
make web                # en otra terminal
```

`make test` corre las pruebas del motor estadístico.

## Producción

```bash
npm run build
npm run preview
```

El sitio queda en `dist/` y es estático. Cada push a `main` lo publica en GitHub Pages.

Más detalle en [TECNICO.md](TECNICO.md).
