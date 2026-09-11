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
| 2024 | Jan–Jun, Aug–Dec (11) | **Jul** (confirmed unrecoverable, see below) |
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

**Confirmed unrecoverable: July 2024.** The live source returns HTTP 403 for every
filename variant tried. The Wayback Machine has exactly one capture of that file —
but it captured the origin server's WAF **"Request Rejected"** error page (HTTP 200,
but not the real document), not the actual PDF. Checked directly; there is no other
archived copy. This is a genuine, documented gap, not an oversight.

**Data-quality note on the live source:** as of this writing, `epfo.gov.in/data-hub/`
lists a "2026" entry dated 20 Oct 2025 whose download link actually points to
`February-2021.pdf` — a labeling bug on EPFO's own site, not ours. The most recent
*genuine* report currently published is September 2025.

## Important modeling note for Phase 2 (not yet acted on)

Each report's page 1 table isn't just "this month's row" — it's **cumulative for the
current fiscal year**, i.e. a single report typically shows every month from the
start of its fiscal year (April) up to itself. That means a report we already have
(e.g. `2021-01.pdf`, fiscal year 2020-21) likely already contains the *retrospective*
monthly figures for several months we've listed as "missing" above (e.g. Jun/Jul/Sep/
Nov/Dec 2020), since they fall in the same fiscal year. This hasn't been extracted or
verified yet — it's a real opportunity to shrink the gap list further once we build
the actual parsing pipeline in Phase 2, by parsing every report's *full* page-1 table
(not just its own month's row) and reconciling overlaps, preferring the most recent
revision of any given month where reports disagree (EPFO explicitly marks the data
"provisional" and revises it in subsequent releases).

## Reproducing this

`download_log.csv` records the exact URL and method used for every file, so the
whole dataset can be re-downloaded from scratch by replaying that log — no manual
guesswork needed.
