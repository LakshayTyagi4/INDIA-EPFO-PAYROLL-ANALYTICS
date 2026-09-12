# India EPFO Formal Workforce Analytics

A Power BI project analyzing India's monthly formal-workforce growth using EPFO's
official "Provisional Estimate of Payroll" data — tracking new, exiting, and
re-joined members by age band, month over month.

**Data source:** https://www.epfo.gov.in/data-hub/ (monthly PDF releases, Jan 2021–present),
extended back to 2019 via the Wayback Machine — see below.

## Data coverage

**66 monthly reports spanning July 2019 – September 2025** downloaded into `data/raw/`:
- Jan 2021 – Sep 2025: complete except **July 2024** has no standalone file (see
  below — the data itself was recovered anyway).
- Jul–Dec 2019 and Jan–Oct 2020: 10 additional months recovered from the Wayback
  Machine (the current site only goes back to Jan 2021) — each independently
  verified by reading the report's own "Date" line inside the PDF, not assumed from
  crawl metadata.
- The Power Query pipeline (Phase 2) combines all 66 raw PDFs and, since each
  report's Page 1 retroactively covers its whole fiscal year, ends up recovering
  **July 2024's actual figures anyway** via a later report's cumulative table —
  full explanation in `data/raw/README.md`.

Full methodology (exact source URLs, how the historical recovery works, the confirmed
gap, and a live-site data-quality bug we found along the way) is documented in
[`data/raw/README.md`](data/raw/README.md). Full per-file provenance is in
[`data/raw/download_log.csv`](data/raw/download_log.csv).

## Documentation

- [`data/raw/README.md`](data/raw/README.md) — data sourcing & methodology (how
  the 66 PDFs were acquired, the Wayback Machine recovery, known gaps)
- [`power-query/README.md`](power-query/README.md) — the PDF-to-fact-table
  pipeline in depth: every bug found along the way and why each fix works
- [`model/README.md`](model/README.md) — the star schema (fact table, Date
  dimension, relationship)
- [`dax/README.md`](dax/README.md) — the full DAX measure library
- [`wireframes/README.md`](wireframes/README.md) — the planned report layout,
  sketched before the Power BI build

## Folder structure

```
EPFO Project/
├── data/
│   ├── raw/            raw monthly PDFs from epfo.gov.in
│   └── processed/      cleaned CSV export of the combined table
├── power-query/        documented M code for the PDF ingestion pipeline
├── model/              star schema diagram / data model docs
├── dax/                documented DAX measure library
├── wireframes/         low-fidelity report page plan (drawn before the build)
├── screenshots/        report page exports for documentation
└── EPFO_Payroll_Analytics.pbix
```

## Future scope (not in progress)

The current model only extracts **Page 1** of each PDF. A structural deep-read
of 7 sample reports spanning 2019-2025 (not just one file) found four more
dimensions sitting untouched on the remaining ~92-97% of every report's pages
— **Age-Band Detail** (two table variants), **State-Wise**, **Industry-Wise**,
and **Gender-Wise** breakdowns — each with its own history, structure, and real
extraction risks (some of these tables show genuine numeric corruption in
`pdftotext` output that gets worse the more columns a report has accumulated).

Ranked easiest → hardest to eventually add: **Gender-Wise** (cheapest — mostly
clean data since ~May 2024, one confirmed absent-file gap to handle) →
**Age-Band Detail** (straightforward with one robust parsing rule) →
**State-Wise** (every sampled file shows some numeric corruption, worsening
with column count — recommend a table-aware extractor over `pdftotext`) →
**Industry-Wise** (hardest — a dynamic, non-exhaustive top-10-per-bucket list,
not a fixed dimension).

Full findings (per-dimension structure, exact failure modes found, and what a
future Power Query extension would need to handle) are in
[`data/raw/README.md`](data/raw/README.md#full-pdf-contents-future-scope-not-currently-parsed).
This is a deliberately scoped-out next step, not something underway — the
current build intentionally stays limited to Page 1 for now.

## Status

- [x] Phase 0 — sample PDFs downloaded, table structure confirmed
- [x] Phase 1 — bulk + historical data acquisition (66 months, Jul 2019–Sep 2025)
- [x] Phase 2a — Power Query pipeline: 66 PDFs → deduplicated, unpivoted fact table (456 rows)
- [x] Phase 2b — Date dimension (with fiscal-year columns) + relationship built
- [x] Phase 3 — DAX measures (time intelligence, rolling average, volatility, COVID-19 comparison)
- [ ] Phase 4 — report pages + AI-augmented visuals
- [ ] Phase 5 — polish (theme, tooltips, mobile layout)
- [ ] Phase 6 — final documentation and release
