# CLIMAX · Floods that stay

**▶ Interactive pitch deck:** `docs/index.html` (published via GitHub Pages: Settings → Pages → Branch `main`, folder `/docs`)

> Built at UAE Hackathon 2026 (CBUAE Challenge 1). Loans in this repo are synthetic.


**UAE Hackathon 2026 · Challenge #1 (CBUAE): climate risk for banks**

> Banks model how *deep* the water gets. April 2024 showed that in Dubai the damage is how *long* it stays.
> CLIMAX measures both from free satellite data, building by building, and turns them into PD and LGD.

MBZUAI (Salman Khan's group, May 2024) showed **which streets** flooded from Sentinel-2 + OpenStreetMap.
CLIMAX shows **which loans**, and adds the dimension nobody prices: **duration**.

---

## Quick start

```bash
# 1) ONE TIME, with internet (your own Terminal): real satellite data, ~5–15 min
sh RUN_PIPELINE_MAC_LINUX.sh          # Windows: RUN_PIPELINE_WINDOWS.bat

# 2) Any time, offline: start the app → http://127.0.0.1:5173
sh START_MAC_LINUX.sh                 # Windows: START_WINDOWS.bat
```

The zip ships with **TEST data**, so the app runs immediately. While test data is loaded you'll see a red
"TEST DATA" badge and watermark everywhere. Running step 1 replaces it with real data, and the badge turns
green: `REAL · SENTINEL-2 L2A`.

The app needs only Python 3.9+ (standard library). MapLibre and the fonts are bundled, so **no internet is needed at the venue**.
The pipeline needs `requirements-pipeline.txt`, and the script installs it into `.venv` for you.

**3D renderer.** With `CESIUM_ION_TOKEN` in `private/.env.local` (copy `private/.env.local.example` to `private/.env.local` and add your own token) the app uses **CesiumJS + Cesium ion**:
Bing aerial imagery and Cesium OSM Buildings for city context, with our analysed buildings and satellite layers on top. The
"3D" button switches to the offline MapLibre renderer, and the app switches automatically if Cesium can't start. Phones default to the offline renderer.
The token is sent to the browser (Cesium tokens are client-side by design), so restrict it to your domains in the ion dashboard before any public deployment.

**Government open data (judging criterion).** Download *Dubai Land Department → Transactions* from **data.dubai**
as CSV into `data/gov/`, then run `python3 -m pipeline.gov_data` (or the full pipeline). Collateral values then come from
real DLD median AED/m² for the same districts, and the memo cites the rows used.

Optional: put `ANTHROPIC_API_KEY=...` in `private/.env.local`, and Claude will plan the agent's tool calls.
Without a key, a transparent offline parser (English + Arabic) answers through the same tools.

## What is real, what is synthetic

| Layer | Source | Status |
|---|---|---|
| Flood extent per pass | Sentinel-2 L2A (Element 84 Earth Search), MNDWI + Otsu | **Measured** |
| How long water stayed | Last clear pass each pixel was seen wet (lower bound) | **Measured** |
| Depth | Simplified FwDET on Copernicus DEM GLO-30 (a surface model that includes buildings) | Indicative estimate |
| Terrain-only forecast + IoU | Priority-Flood depressions + TPI, calibrated west half / scored east half | Real validation |
| Buildings | OpenStreetMap footprints (ODbL) | **Real** |
| Collateral AED/m² | Dubai Land Department transactions (Data.Dubai), median by district | **Real government open data** (when the CSV is provided) |
| 3D context | Cesium ion: Bing aerial + Cesium OSM Buildings | Real basemap |
| Loans, PD, LGD, collateral, insurance | Seeded generator, assigned by building **type**, blind to flood results | **Synthetic** |

## The finance (shown in-app, memo and audit file)

```
interruption_days = days water was last seen around the OPERATING building × persist_mult
PD_stressed       = min(PD × cap, PD × (1 + β × interruption_days))         β default 0.10/day
damage            = JRC depth-damage(depth at COLLATERAL × depth_mult)       Huizinga et al. 2017
LGD_stressed      = min(100%, LGD + collateral × damage × (1 − insured) / EAD)
ΔEL               = EAD·PD_s·LGD_s − EAD·PD·LGD
```

This is a one-period expected-loss sensitivity for **triage**. It is not IFRS 9 ECL and not a capital figure.
CBUAE's own stress test models damage costs and **excludes foregone revenue** (Climate Forum Report 2025),
and CLIMAX's PD channel is exactly that missing piece.

## Demo controls

- **▶ PLAY STORY** runs a ~50 s guided sequence. Space skips ahead; press the button again to stop.
- **Timeline**: PRE → each real satellite pass. Use ← → keys, or ▶ DAYS to animate.
- **Layers**: WATER (per pass) · HOW LONG (persistence) · DEPTH · FORECAST vs REALITY (swipe) · LOANS.
- **Ask bar**: English or Arabic. Each answer shows its tool calls, and the map highlights the buildings and loans it names.
- **MEMO ↗** opens a printable risk-committee memo with scene ids, assumptions and limitations. **AUDIT ↓** downloads the full JSON.

## Structure

```
pipeline/            real data pipeline (run once, needs internet)
  config.py          areas, dates, thresholds: every assumption in one file
  fetch.py           Earth Search STAC, Copernicus DEM COG, Overpass
  core.py            MNDWI, Otsu, persistence, Priority-Flood, FwDET, IoU, damage curve
  analyze.py         per-area analysis → data/generated/<area>/
  loans.py           synthetic loan book on real footprints
  run_all.py         orchestrator + run log (replayed in the AGENT tab)
  make_test_data.py  labelled TEST data through the same analysis code
engine.py            finance engine
agent.py             tool-calling agent (Claude or offline EN/AR parser)
memo.py              risk-committee memo
server.py            stdlib HTTP server + API
index.html, assets/  MapLibre 3D app (vendored, offline)
tests/               unit tests, offline pipeline integration test, browser check
legacy/              v1 files kept for reference
```

## If something goes wrong

- *"not enough clear scenes"*: lower `MIN_AOI_VALID` in `pipeline/config.py` (e.g. 0.4) and rerun.
- *Overpass busy*: rerun later. The script tries 3 mirrors.
- *Re-analyse without internet*: `sh RUN_PIPELINE_MAC_LINUX.sh --offline` (uses `data/cache`).
- *Want test data back*: `python3 -m pipeline.make_test_data`.
