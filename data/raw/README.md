# Raw data — sourcing & methodology

Monthly **"Provisional Estimate of Net Payroll in Age Buckets"** reports, published by
EPFO (Employees' Provident Fund Organisation, Ministry of Labour & Employment,
Government of India). Each report is a ~19-24 page PDF released around the 20th of
the following month, showing new/exited/re-joined member counts by age band.

Naming convention: `YYYY-MM.pdf`, where `YYYY-MM` is the **report month**, not the
release date (e.g. `2024-01.pdf` covers January 2024, released ~20 Feb 2024).

## Coverage: 66 months, July 2019 – September 2025

| Year | Months present | Missing |
|---|---|---|
| 2019 | Jul, Sep, Oct, Dec (4) | Jan–Jun, Aug, Nov |
| 2020 | Jan, Feb, Apr, May, Aug, Oct (6) | Mar, Jun, Jul, Sep, Nov, Dec |
| 2021 | Jan–Dec (12) | — complete |
| 2022 | Jan–Dec (12) | — complete |
| 2023 | Jan–Dec (12) | — complete |
| 2024 | Jan–Jun, Aug–Dec (11 raw files) | **Jul** missing as a standalone file, but see below — recovered anyway |
| 2025 | Jan–Sep (9) | — complete through the latest available release |

Full per-file provenance (exact source URL, HTTP status, byte size, recovery method)
is in [`download_log.csv`](download_log.csv).

## How this was acquired

**Primary source (2021–2025, 56 files):** EPFO's current data hub
(`epfo.gov.in/data-hub/`) links each month's PDF from a CDN
(`pmvbry-cdn.epfindia.gov.in/wp-content/uploads/2025/10/{Month}-{Year}.pdf`) — no
login, no API, direct HTTPS download.

**Historical recovery (2019–2020, 10 files):** EPFO's *current* site only goes back
to January 2021. Earlier months were recovered from the **Wayback Machine**
(web.archive.org), which had crawled an older, generically-named report URL on the
previous site domain (`epfindia.gov.in/site_docs/exmpted_est/Payroll_Data_EPFO.pdf`)
at scattered points in time. Since that URL got overwritten with a new report every
month, each Wayback *snapshot timestamp* effectively froze whatever month's report
was live at that moment — so the snapshot history became a proxy monthly archive.
Every recovered file's actual report date was independently verified by extracting
its PDF text and checking the "Date" line, not assumed from the crawl timestamp.

**July 2024 has no standalone file — but the data isn't actually missing.** The live
source returns HTTP 403 for every filename variant tried, and the Wayback Machine's
only capture of that file is the origin server's WAF "Request Rejected" error page,
not the real document — so as a *standalone PDF*, it's genuinely unrecoverable.
However, once the Phase 2 pipeline was built (see the modeling note below), it turned
out `2025-05.pdf`'s cumulative fiscal-year table already includes a full row for
Jul-2024 retrospectively — so the actual figures are present in the combined dataset
even though no dedicated July 2024 PDF exists. Confirmed by direct inspection.

**Data-quality note on the live source:** as of this writing, `epfo.gov.in/data-hub/`
lists a "2026" entry dated 20 Oct 2025 whose download link actually points to
`February-2021.pdf` — a labeling bug on EPFO's own site, not ours. The most recent
*genuine* report currently published is September 2025.

## Modeling note for Phase 2 — confirmed in practice

Each report's page 1 table isn't just "this month's row" — it's **cumulative for the
current fiscal year**, i.e. a single report typically shows every month from the
start of its fiscal year (April) up to itself. This was a prediction when Phase 1
finished; it's now confirmed: the Power Query pipeline parses every report's *full*
page-1 table (not just its own month's row), combines all 66 files, and for any month
that appears in more than one report (which is most of them, since fiscal years
overlap across consecutive reports), keeps the **most recent report's figures**
(sorted by filename descending, first occurrence wins — EPFO revises "provisional"
data in later releases, so the newest version is the most accurate).

This genuinely recovered data we didn't have as standalone files — most notably
**July 2024**, which has no dedicated PDF but appears correctly via `2025-05.pdf`'s
retrospective table. The final deduplicated table has ~76-77 unique months from
July 2019 through September 2025 (one straggler file, `2019-09.pdf`, still fails
extraction due to an unrelated column-layout quirk specific to that one file — see
`power-query/PayrollMonthly_Raw.pq` for details).

## Reproducing this

`download_log.csv` records the exact URL and method used for every file, so the
whole dataset can be re-downloaded from scratch by replaying that log — no manual
guesswork needed.
