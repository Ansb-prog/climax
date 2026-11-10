# Verification record (CLIMAX v2)

Run everything: `python3 -m unittest discover -s tests -p "test_*.py"` and `python3 tests/browser_check.py` (needs Playwright).

| Check | Result |
|---|---|
| Algorithm unit tests (MNDWI, Otsu, persistence, Priority-Flood, FwDET, IoU, damage curve, building join) | 10 / 10 pass |
| Engine + agent + memo tests (monotonicity, zero-β, limits, Arabic parsing, no invented loans, disclaimers) | 9 / 9 pass |
| **Offline pipeline integration**: the real `run_all.download()` path against local GeoTIFFs (UTM + geographic), mocked STAC + Overpass. Checks reprojection, mosaicking, Earth Search scale/offset, cloud-date selection, building parsing, cache reload | pass |
| DLD (Data.Dubai) loader: column detection, sales-only, date filter, area matching, loan re-pricing | 3 / 3 pass |
| CesiumJS renderer (headless, ion blocked): our imagery, 3D primitives, loan markers, native swipe; automatic fallback | renders, 0 JS errors |
| Headless Chromium: open, day scrub, persistence, evidence, swipe, Arabic question, loan drawer, story mode, mobile | 0 JS errors |
| Full ~50 s story run | completes, 0 JS errors |

## Not verified here (do this on your Mac)
- **Live downloads** from Earth Search / AWS / Overpass. The build environment's network blocks these hosts, so the network code is covered by the offline integration test only.
  Run `sh RUN_PIPELINE_MAC_LINUX.sh` once. If a host fails, the error says which one.
- **Cesium ion content** (Bing aerial, OSM Buildings): ion is blocked here, so only the offline fallback was seen. Check on your Mac with internet.
- **Claude-planned agent** (needs `ANTHROPIC_API_KEY`). The offline parser is fully tested.
- Which April–May 2024 Sentinel-2 dates are cloud-free enough over each area. The pipeline picks them automatically and logs every decision (AGENT tab).

## Honesty guards built in
- TEST data shows a watermark, a red badge, "[TEST]" in every log line, and warnings in agent answers and the memo.
- Loans are assigned to buildings by type with a fixed seed, **before** looking at flood results.
- Persistence is labelled a lower bound. Depth is labelled indicative. The forecast IoU is reported with a random baseline.
