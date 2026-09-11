# India EPFO Formal Workforce Analytics

A Power BI project analyzing India's monthly formal-workforce growth using EPFO's
official "Provisional Estimate of Payroll" data — tracking new, exiting, and
re-joined members by age band, month over month.

**Data source:** https://www.epfo.gov.in/data-hub/ (monthly PDF releases, Jan 2021–present),
extended back to 2019 via the Wayback Machine — see below.

## Data coverage

**66 monthly reports spanning July 2019 – September 2025** downloaded into `data/raw/`:
- Jan 2021 – Sep 2025: complete except **July 2024**, confirmed unrecoverable from
  every source tried (live site 403s; the only Wayback capture is the origin's WAF
  error page, not the real document).
- Jul–Dec 2019 and Jan–Oct 2020: 10 additional months recovered from the Wayback
  Machine (the current site only goes back to Jan 2021) — each independently
  verified by reading the report's own "Date" line inside the PDF, not assumed from
  crawl metadata.

Full methodology (exact source URLs, how the historical recovery works, the confirmed
gap, and a live-site data-quality bug we found along the way) is documented in
[`data/raw/README.md`](data/raw/README.md). Full per-file provenance is in
[`data/raw/download_log.csv`](data/raw/download_log.csv).

## Folder structure

```
EPFO Project/
├── data/
│   ├── raw/            raw monthly PDFs from epfo.gov.in
│   └── processed/      cleaned CSV export of the combined table
├── power-query/        documented M code for the PDF ingestion pipeline
├── model/              star schema diagram / data model docs
├── dax/                documented DAX measure library
├── screenshots/        report page exports (README + LinkedIn assets)
└── EPFO_Payroll_Analytics.pbix
```

## Status

- [x] Phase 0 — sample PDFs downloaded, table structure confirmed
- [x] Phase 1 — bulk + historical data acquisition (66 months, Jul 2019–Sep 2025)
- [ ] Phase 2 — data model (star schema)
- [ ] Phase 3 — DAX measures
- [ ] Phase 4 — report pages + AI-augmented visuals
- [ ] Phase 5 — polish (theme, tooltips, mobile layout)
- [ ] Phase 6 — publish (GitHub, resume bullet, LinkedIn post)
