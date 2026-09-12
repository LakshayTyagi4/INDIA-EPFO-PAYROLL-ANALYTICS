# Raw data — sourcing & methodology

Monthly **"Provisional Estimate of Net Payroll in Age Buckets"** reports, published by
EPFO (Employees' Provident Fund Organisation, Ministry of Labour & Employment,
Government of India). Each report is a PDF released around the 20th of the
following month, showing new/exited/re-joined member counts by age band —
13 pages in the earliest reports (2019), growing to 24 pages by 2025 as more
fiscal years and months accumulate into every table.

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
retrospective table. The same effect pushes the *start* of the final deduplicated
table earlier than our earliest standalone file too: `2019-07.pdf` itself
retroactively includes Apr/May/Jun 2019, the start of that fiscal year, so the
table's true minimum is **April 2019**, not July 2019. It has ~76-77 unique months
running April 2019 through mid-2025 (one straggler file, `2019-09.pdf`, still fails
extraction due to an unrelated column-layout quirk specific to that one file — see
`power-query/PayrollMonthly_Raw.pq` for details).

## Planned extensions beyond Page 1

The dashboard today is built entirely on Page 1 of each report. Every PDF
also contains four more full sections, and this is the plan for bringing
each of them in — what it adds to the project, and the implementation notes
from a structural read of 7 reports spanning 2019–2025 (Jul 2019, Aug 2020,
Jan 2021, Jun 2022, Jun 2023, Aug 2024, Sep 2025) done to scope the work.

**How the reports are put together, so the plan below makes sense:** every
sampled report follows the identical section order — Page 1 summary →
Age-Band Detail → State-Wise → Industry-Wise → Gender-Wise (always last) —
and that order never varies across 6+ years of reports. What grows is
volume: reports went from 13 pages (2019-07) to 24 pages (2025-09) as more
fiscal years and months accumulate.

### 1. Age-Band Detail — the natural first extension

**What it adds:** the fiscal-year and monthly breakdown behind the Page 1
summary — new / exited / re-joined subscriber counts, plus a second related
metric worth surfacing on its own, "Net new EPF Subscribers" (a narrower
post-Sep-2017 cohort that gives a genuinely different bottom-line number
than Net Payroll for the same period). Present in every sampled report back
to 2019, so there's a full history to build from immediately.

**Implementation notes:** the two tables share the same 6 age bands as
Page 1, so the age-band dimension already built extends here directly. The
one thing to build carefully for: about half the sampled files have the
table's row labels sitting on a different line than their own numeric
values — solved by extracting labels and values as two independent ordered
lists and zipping them by position, rather than assuming they share a line.

### 2. Gender-Wise Analysis — a genuine diversity angle

**What it adds:** a page tracking the Male / Female / Transgender / Not
Available split in formal-workforce growth over time — the kind of
diversity-in-employment view that's rarely built out for Indian labor-market
data. This is also the quickest of the three to get right: the schema is
fixed, and historical figures are byte-identical across every report
vintage that carries them (EPFO republishes rather than revises), so past
years only need reconstructing once, and every month since roughly May 2024
already extracts cleanly.

**Implementation notes:** one gap to design around — the whole section is
missing entirely from at least one sampled report (Aug 2020), so "no data
this month" needs to be a normal, handled case rather than an error.

### 3. State-Wise Map — where the growth is happening

**What it adds:** a geographic breakdown of new subscribers by Indian state,
turning "how much formal-job growth" into "where it's happening" — a natural
map visual for the dashboard. The state list itself is stable (~32
states/UTs from 2021 onward) and present in every sampled report back to
2019.

**Implementation notes:** this is the one that'll take the most care —
because the table keeps adding a new column every year (4 columns in 2019,
12 by 2025), the wider it gets the more its rows tend to run together when
extracted, in a few different ways depending on the report's age. The plan
is to extract labels and values independently (same idea as Age-Band
Detail) and cross-check the results against each table's own subtotal row
before trusting them — and to look at a table-aware PDF extraction tool
instead of plain text extraction if that's not enough on its own.

### 4. Industry-Wise Breakdown — which sectors are hiring

**What it adds:** a sector-level page on which industries are adding the
most formal jobs each month — present in every sampled report back to 2019.

**Implementation notes:** unlike the state list, the industry list isn't
fixed — each report shows a "top 10" that rotates slightly release to
release, and a different top 10 for each age bracket. So rather than a
fixed Industry dimension, this needs to be built as the union of every
industry name ever observed, with each report only filling in whichever
industries made that month's top 10 — a sparse table by design, not a gap
to fix.

**One shared note across all four:** a couple of one-off quirks turned up
in the sample that any build should just skip past rather than try to
generalize — a corrigendum table in one report (`2022-06.pdf`) that never
recurs, and Page 1 itself becoming a less reliable cross-check source from
~2024 onward as its own summary table grew dense enough to occasionally
garble on extraction. Full per-file detail (exact line numbers, sample
extraction output, and every quirk found) is preserved in the project's
research notes if it's useful when this work actually starts.

## Reproducing this

`download_log.csv` records the exact URL and method used for every file, so the
whole dataset can be re-downloaded from scratch by replaying that log — no manual
guesswork needed.
