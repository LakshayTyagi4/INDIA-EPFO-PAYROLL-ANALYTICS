# India EPFO Formal Workforce Analytics

A Power BI project analyzing India's monthly formal-workforce growth using EPFO's
official "Provisional Estimate of Payroll" data — tracking new, exiting, and
re-joined members by age band, month over month.

**Data source:** https://www.epfo.gov.in/data-hub/ (monthly PDF releases, Jan 2021–present)

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

- [ ] Phase 0 — sample PDFs downloaded, table structure confirmed
- [ ] Phase 1 — bulk data acquisition + Power Query ingestion pipeline
- [ ] Phase 2 — data model (star schema)
- [ ] Phase 3 — DAX measures
- [ ] Phase 4 — report pages + AI-augmented visuals
- [ ] Phase 5 — polish (theme, tooltips, mobile layout)
- [ ] Phase 6 — publish (GitHub, resume bullet, LinkedIn post)
