# DATEX 

## Qué es

Una web estática construida con React, TypeScripty Vite que responde ¿el clima está cambiando de verdad?" para cualquier punto del planeta. El repo trae las dos mitades: la web (raíz) y el servidor Python (`backend/`). La web funciona sola, con datos precalculados y la estadística en el navegador, y si el servidor está levantado lo usa.

## Stack

Interfaz: React 19 + TypeScript
Build y dev server: Vite 8
Globo 3D: MapLibre GL 5
Gráficas: Recharts 3
Lint: oxlint 
Estilos: Un solo CSS con variables
Tipografía: Satoshi, servida desde Fontshare
Despliegue: GitHub Pages con GitHub Actions

## Para correrlo

```bash
npm install
npm run dev      # http://localhost:5173
npm run build    # deja el sitio en dist/
npm run preview  # sirve dist/ para probar el build
npm run lint
```

Con el servidor Python (hace falta [uv](https://docs.astral.sh/uv/)):

```bash
cp .env.example .env   # y pon VITE_API_URL=http://localhost:8000
make setup             # instala servidor y web
make backend           # API en http://localhost:8000, documentación en /docs
make web               # en otra terminal
make test              # pruebas del motor estadístico
```

## Mapa del código

```
src/
  main.tsx           arranque
  App.tsx            estado de la app, navegación entre las 3 vistas, pie
  Briefing.tsx       vista Inicio
  GlobeSection.tsx   vista Planeta: globo + panel de lugar y variable
  Globe3D.tsx        el mapa en sí (MapLibre); se carga aparte con lazy()
  TrendView.tsx      Análisis › Veredicto
  ScanView.tsx       Análisis › Radar
  ComparePlaces.tsx  Análisis › Comparar
  SatelliteView.tsx  Análisis › Satélite
  DemographyView.tsx Análisis › Población
  RelateView.tsx     Análisis › Sociedad
  TrendChart.tsx, SeriesChart.tsx   gráficas reutilizadas
  Explain.tsx        botón "explicar en lenguaje sencillo"
  ui.tsx             piezas base: Button, Card, Kpi, Collapse, Disclosure, Switch, Loader, Shard
  api.ts             tipos + la única puerta de entrada a los datos
  staticFallback.ts  el "backend" que corre en el navegador
  i18n.ts            todos los textos, en español e inglés
  globeColors.ts     paletas del globo
  index.css          todos los estilos
public/
  static-api/        catalog.json, globe.json, bundle.json (datos precalculados, ~6 MB)
  logo.png, shard-*.png, favicon.png, boreal-labs.png
backend/
  app/main.py        la API (FastAPI): todas las rutas /api/...
  app/catalog.py     variables, regiones y casos de ejemplo
  app/config.py      lee las claves del .env de la raíz
  app/services/      trends.py (motor estadístico), forecast.py, relate.py, power.py (NASA POWER),
                     satellite.py, planetary.py, demography.py, worldbank.py, places.py, ai.py
  app/data/          muestras sin conexión y la malla del globo
  scripts/           build_globe.py, fetch_samples.py, export_static_api.py
  tests/             pruebas del motor y de la API
```

## De dónde salen los datos

Todo pasa por `api()` y `apiPost()` en `api.ts`. La regla es una sola:

- **Sin `VITE_API_URL`** (lo normal, y lo que corre en Pages): la llamada va a `staticFallback.ts`, que imita las rutas `/api/...` del backend.
- **Con `VITE_API_URL`**: la llamada va por `fetch` a ese servidor.

`hasBackend` dice en cuál de los dos casos estamos. Lo que solo funciona con servidor se oculta cuando no lo hay: hoy son el conteo de cobertura del suelo (Satélite) y la insignia del clima en vivo.

En modo estático, `staticFallback.ts` hace esto:

1. Si el punto y la variable están en `bundle.json`, responde con lo precalculado.
2. Si no, pide la serie mensual a NASA POWER desde el navegador y calcula la tendencia ahí mismo.
3. Para lo demás llama directo a servicios públicos: Banco Mundial, Our World in Data (población ONU), Planetary Computer (imágenes), Open-Meteo y BigDataCloud (buscar lugares).

El globo lee `globe.json`: una malla de 2.592 celdas de 5° con la tendencia ya calculada. Las imágenes de fondo son teselas de NASA GIBS (Blue Marble y Black Marble) y, al acercarse, de Esri World Imagery.

## La estadística

El motor original es Python y está en `backend/app/services/trends.py`. `staticFallback.ts` es su copia en TypeScript, para que el veredicto salga igual con o sin servidor:

- **Pendiente:** Theil-Sen, con intervalo del 95 %. No se deja arrastrar por años extremos.
- **Significancia:** Mann-Kendall sobre la serie preblanqueada, más una regresión con tamaño de muestra efectivo. Las dos corrigen la autocorrelación (la "memoria" del clima).
- **Veredicto:** solo es "significativo" si las dos pruebas coinciden. Si no, se calcula cuántos años de datos faltan.
- **Salto brusco:** prueba de Pettitt, para avisar cuando el cambio es un escalón y no una rampa.
- **Relaciones clima–sociedad:** correlación de Pearson y Spearman sobre las series sin tendencia, para no confundir "los dos suben" con "uno mueve al otro".

Los p-valores de la t se aproximan con Peizer-Pratt porque en el navegador no hay tablas.

## Modelo de crecimiento urbano

`backend/scripts/build_city_growth.py` genera los escenarios precalculados en `public/static-api/city/` (como `managua.json` e `index.json`). Toma la cobertura del suelo anual de 10 m (Impact Observatory/Esri, Planetary Computer), la reproyecta a celdas de ~100 m, ajusta una regresión logística sobre las transiciones 2017–2023 y reparte el área construida futura (2030–2050) siguiendo la población urbana de la ONU. Es un escenario de tendencia, no un pronóstico.

```bash
cd backend && PYTHONPATH=. uv run python -u scripts/build_city_growth.py managua
```

## Interfaz

- **Tema:** blanco de base, navy `#00023d` para texto y acciones, turquesa `#56e1e8` solo como acento. Los colores viven en variables al inicio de `index.css`.
- **Material translúcido** solo en lo que flota: barra superior, botones sobre el globo y tooltips. Las tarjetas son sólidas.
- **Logo como motivo:** las cuatro piezas del logo son PNG usados como máscara CSS (`Shard`), así el color se pone desde el CSS. Aparecen en la portada, el cargador y como adorno.
- **Desplegables:** `Collapse` anima la altura con `grid-template-rows: 0fr → 1fr`. No mide nada y se puede invertir a medio camino.

## Animaciones

Todo es CSS o API del navegador, sin dependencias:

- Cambio de vista y de pestaña con View Transitions (`withTransition` en `App.tsx`). Donde no existe la API, el cambio es instantáneo.
- Las secciones de Inicio aparecen al hacer scroll con `animation-timeline: view()`.
- Las piezas del logo siguen al puntero con variables CSS que se actualizan en `pointermove`.
- `prefers-reduced-motion`, `prefers-reduced-transparency` y `prefers-contrast` están atendidos al final de `index.css`.

La espera de 1 a 2,5 s antes de mostrar resultados es intencional (`paced()` en `api.ts`).

## Despliegue

`.github/workflows/deploy.yml` compila y publica `dist/` en GitHub Pages en cada push a `main`. `vite.config.ts` usa `base: './'`, así el sitio funciona en cualquier subcarpeta.

En Pages solo se publica la web; el servidor Python no corre ahí. Para tenerlo en línea hay que desplegar `backend/` en un servicio que ejecute Python y compilar la web con `VITE_API_URL` apuntando a él.

Las claves (NASA, Earthdata, Anthropic) van en `.env`, que está en `.gitignore` y solo lo lee el servidor. Nunca les pongas el prefijo `VITE_`: todo lo que lleva ese prefijo acaba público en el navegador. Sin claves el servidor arranca igual; la IA responde con plantillas.

## Cosas a saber

- `npm audit` marca una vulnerabilidad en MapLibre GL 5; el arreglo es subir a la versión 6 y volver a probar el globo.
- En modo estático dependemos de que NASA POWER y los demás servicios públicos respondan desde el navegador. Si uno cae, esa pestaña muestra su error y el resto sigue.
- `staticFallback.ts` es el archivo más largo (1.300 líneas). Si cambia la estadística en el backend, hay que cambiarla aquí también.
- Los textos nuevos van en `i18n.ts`, en los dos idiomas.
- `public/static-api/` se regenera con `make static` (y el globo con `make globe`, unos 15 minutos).
