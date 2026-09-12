# India EPFO Formal Workforce Analytics

I built this Power BI project to analyze India's monthly formal-workforce growth
using EPFO's official "Provisional Estimate of Payroll" data — tracking new,
exiting, and re-joined members by age band, month over month.

**Data source:** https://www.epfo.gov.in/data-hub/ (monthly PDF releases, Jan 2021–present),
which I extended back to 2019 via the Wayback Machine — see below.

## Data coverage

**66 monthly reports spanning July 2019 – September 2025**, which I downloaded
into `data/raw/`:
- Jan 2021 – Sep 2025: complete except for **July 2024**, which has no
  standalone file (see below — I recovered the data itself anyway).
- Jul–Dec 2019 and Jan–Oct 2020: 10 additional months I recovered from the
  Wayback Machine (the current site only goes back to Jan 2021) — I verified
  each one independently by reading the report's own "Date" line inside the
  PDF, rather than trusting the crawl metadata.
- The Power Query pipeline (Phase 2) combines all 66 raw PDFs, and since each
  report's Page 1 retroactively covers its whole fiscal year, I end up
  recovering **July 2024's actual figures anyway** via a later report's
  cumulative table — full explanation in `data/raw/README.md`.

I've written up the full methodology — exact source URLs, how the historical
recovery works, the gap in coverage, and a live-site data-quality bug I ran
into along the way — in [`data/raw/README.md`](data/raw/README.md). Full
per-file provenance is in
[`data/raw/download_log.csv`](data/raw/download_log.csv).

## Documentation

- [`data/raw/README.md`](data/raw/README.md) — data sourcing & methodology
  (how I acquired the 66 PDFs, the Wayback Machine recovery, known gaps)
- [`power-query/README.md`](power-query/README.md) — the PDF-to-fact-table
  pipeline in depth: every bug I hit along the way and why each fix works
- [`model/README.md`](model/README.md) — the star schema (fact table, Date
  dimension, relationship)
- [`dax/README.md`](dax/README.md) — the full DAX measure library
- [`wireframes/README.md`](wireframes/README.md) — the planned report layout,
  which I sketched before starting the Power BI build

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

## What's next

Right now the dashboard is built entirely on Page 1 of each report — the Net
Payroll summary by age band. Every PDF actually contains four more full
sections, and I'm planning to bring each of them into this project as its
own dimension and report page:

1. **Age-Band Detail** — the fiscal-year and monthly breakdown behind the
   Page 1 summary (new / exited / re-joined subscribers, plus a second
   related metric, Net new EPF Subscribers). This is my natural first
   extension, since it's the same subject the dashboard already covers, just
   at full depth instead of a summary.
2. **Gender-Wise Analysis** — a new page tracking the Male / Female /
   Transgender / Not Available split in formal-workforce growth over time —
   a genuine diversity angle India's formal-employment data rarely gets
   analyzed through.
3. **State-Wise Map** — a geographic view of new subscribers by Indian
   state, so the dashboard can show *where* formal-job growth is happening,
   not just how much.
4. **Industry-Wise Breakdown** — a sector-level page on which industries are
   adding the most formal jobs each month.

I've already read through all four of these sections across 7 reports
spanning 2019–2025 to work out how each one would actually get built — my
implementation notes are in
[`data/raw/README.md`](data/raw/README.md#planned-extensions-beyond-page-1).
I haven't started building any of it yet — I'm keeping the current build
focused on Page 1 until Phase 6 is done.

## Status

- [x] Phase 0 — sample PDFs downloaded, table structure confirmed
- [x] Phase 1 — bulk + historical data acquisition (66 months, Jul 2019–Sep 2025)
- [x] Phase 2a — Power Query pipeline: 66 PDFs → deduplicated, unpivoted fact table (456 rows)
- [x] Phase 2b — Date dimension (with fiscal-year columns) + relationship built
- [x] Phase 3 — DAX measures (time intelligence, rolling average, volatility, COVID-19 comparison)
- [ ] Phase 4 — report pages + AI-augmented visuals
- [ ] Phase 5 — polish (theme, tooltips, mobile layout)
- [ ] Phase 6 — final documentation and release
- [ ] Phase 7 — modifications and additions (ongoing, post-release: the
      Future Scope dimensions above, and any other changes that come up
      after Phase 6)
