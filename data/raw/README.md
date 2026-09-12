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

## Full PDF contents (future scope, not currently parsed)

Only Page 1 of each PDF is extracted today. This section is the result of a
structural deep-read of **7 sample reports spanning the full archive** (Jul
2019, Aug 2020, Jan 2021, Jun 2022, Jun 2023, Aug 2024, Sep 2025 — 7 of the 66
total files, read in full rather than skimmed), done specifically to scope
what a future extension could cover. Not in progress — the current pipeline
deliberately stays scoped to Page 1 for now.

**Caveat up front:** because only 7 of 66 files were examined in depth,
findings are anchored to those exact files; behavior at the un-sampled months
in between is inferred, not confirmed, and flagged as such below.

### How the reports are put together

Every sampled report follows the identical section order: **Page 1 summary →
Age-Band Detail (two table variants) → [pre-2022 only: an explanatory
paragraph] → State-Wise → Industry-Wise → Gender-Wise (always last)**. This
order never varies across 6+ years of reports. What changes is only *volume*:
reports grew from 13 pages (2019-07) to 24 pages (2025-09, +85%), because
every table keeps appending one more closed fiscal-year column plus however
many months of the current FY have elapsed — a count that itself varies
release to release (1 to 8 new months seen in the sample), not a fixed
cadence.

Two things worth flagging up front:
- **Page 1 degrades as a source over time.** Reliable in 2019–2024, but a
  confirmed transcription error exists in `2024-08.pdf` (a copy-paste of the
  wrong age-band column into the 2019-20 row), and by 2025-09 the summary
  table has grown dense enough that `pdftotext` visibly corrupts it (values
  bleed between adjacent FY rows). The detail tables below are more
  trustworthy wherever they overlap with Page 1.
- **A second "Age-Band" table is easy to conflate with the first.** Right
  after the primary "Net Payroll" table, every report repeats the same 6 age
  bands against a *different* metric ("Net new EPF Subscribers," a narrower
  post-Sep-2017 cohort) — genuinely different bottom-line numbers for the
  same period (FY2017-18: Net Payroll = 1,552,940 vs. Net new EPF Subscribers
  = 7,384,814). A future extension must model both, not collapse them.
- One true one-off exists in the sample: `2022-06.pdf` carries a corrigendum
  table (corrected "first ECR" figures for Jan–May 2022) that fits none of
  the four dimensions and never recurs — any generic parser needs to skip it.

### 1. Age-Band Detail

Two parallel tables per period (fiscal year, and each elapsed month of the
current FY): **Variant A ("Payroll")** — new subscribers / exited / rejoined
/ **Net Payroll** — and **Variant B ("Net new EPF Subscribers")** — same new-
subscriber count, but exited/rejoined restricted to post-Sep-2017 joiners,
yielding a differently-derived net figure. Present, fully formed, in all 7
sampled files (earliest confirmed: 2019-07); both variants always co-occur.

Age bands are identical and stably ordered everywhere: `Less than 18 | 18-21
| 22-25 | 26-28 | 29-35 | More than 35 | Total`. The explanatory paragraph
between variants appears 2019–2021, then is silently dropped from 2022
onward.

**Parsing feasibility:** the most structurally dependable of the four
dimensions, but roughly half the sampled files show age-band **labels shifted
onto a different line than their own numeric values** — sometimes by exactly
one row, sometimes with all labels bunched separately from all values. Not
predictable by year — varies file to file and even variant to variant within
the same file. Fix: extract the ordered label list and ordered value-tuple
list independently, then zip by position rather than assuming same-line
co-occurrence; cross-validate against each table's own "Total" row.

**Era-inconsistency risks:** dynamic period detection needed (row/column
count grows every year); label/value misalignment unpredictable by file;
optional explanatory paragraph/blank page (2019–2021 only); footnote list
changed around 2022; reporting lag varies release to release; don't trust
Page 1 from ~2024 onward; skip the one-off 2022-06 addendum.

### 2. State-Wise Breakdown

`STATEWISE NEW PAYROLL DATA (EPFO)` — six sub-tables per report, one per age
bucket, each ranking ~30–32 states/UTs by new-subscriber count across all
FY-since-2017-18 and current-FY-month columns. Present, fully formed, in all
7 sampled files (earliest confirmed: 2019-07, 30 states/UTs, pre-J&K-
reorganisation). Jammu & Kashmir added from 2020-08; Ladakh appears from
2020-08 but is data-poor until 2021-01 — a steady 32-row list from 2021
onward. Sikkim, Puducherry, Dadra & Nagar Haveli/Daman & Diu, and Lakshadweep
never appear in any sampled file — a confirmed, consistent EPFO reporting
choice, not extraction loss.

Ranking is **recomputed every report and differs bucket to bucket** (e.g.
Uttar Pradesh/Uttarakhand swap order between 2019-07 and 2020-08) — row
position is never a safe join key, match by state name only. Column count
grows every release: 4 (2019-07) → 12 (2025-09, widest in the sample).

**Parsing feasibility — the riskiest of the four dimensions.** Every one of
the 7 sampled files shows numeric corruption, worsening as columns widen:
1. 2019-07 (4 cols): character-level interleaving of wrapped header text
   into the first data row's own digits.
2. 2020-08 → 2024-08 (6–10 cols): a clean, systematic **one-row offset**
   between a state's label and its true values, degrading by 2021-01's
   11-column table into a non-uniform per-column offset.
3. 2025-09 (12 cols, worst case): the section's own banner text gets
   physically interleaved mid-row into state data rows.

Critically, a naive same-line parser would **not error** on any of this — it
would silently misattribute one state's figures to another state's row,
which is more dangerous than an outright parse failure. `SUB TOTAL` rows
remain usable as a reconciliation checksum once reassembled, despite being
shredded across multiple trailing lines in several files.

**Recommendation:** given the severity, a bounding-box-aware re-extraction
(pdfplumber/camelot/Tabula) instead of `pdftotext -layout` is worth
evaluating before committing to text-position parsing at scale.

### 3. Industry-Wise Breakdown

`INDUSTRY WISE PAYROLL DATA (EPFO)` — "Net New Payroll in Top 10 Industries &
Age Buckets," six sub-tables (one per age bucket), each ending in `SUB TOTAL
(TOP 10 INDUSTRIES)`. Top-10 coverage runs **~81–86% of the true total**
in every year with clean numbers — an unlabeled "long tail" of industries is
always excluded, confirming this is a genuinely partial list, not exhaustive.
Present in the earliest sampled file (2019-07); cannot be dated further back.

**The hardest of the four dimensions to model as a fixed entity:** each
bucket has a stable "core" of ~7-9 industries, but 1-3 marginal slots rotate
release to release, and the industry set differs by age bucket within the
same report — **up to 6 independently-refreshed top-10 lists per report**,
not one universal list. "Others" functions as a floating catch-all rank
slot, not a true industry.

**Parsing feasibility:** heaviest multi-line wrapping of any of the four
dimensions. Two recurring, bucket-specific full-column-loss defects found:
the 22-25 bucket lost all columns beyond 2017-18 in the three earliest files
(2019-07/2020-08/2021-01); a different 26-28-bucket loss (only 3 of 12
columns survive) appears in 2025-09 — file-specific casualties needing
individual handling, not a uniform fix.

**Era-inconsistency risks:** no fixed Industry dimension is possible — must
be built as the union of all distinct industry names ever observed (21+ from
just this 7-file sample; likely 30+ across all 66), with an intentionally
**sparse** fact table, not a rectangular one.

### 4. Gender-Wise Breakdown

`GENDER WISE PAYROLL DATA (EPFO)` — always the final section. Three
sub-tables (New Subscribers / Ceased-Exited / Rejoined-Resubscribed), each
cross-tabbing **Male | Female | Transgender | Not Available | Total** against
6 age slabs labelled `A - <18, B - 18-21, C - 22-25, D - 26-28, E - 29-35,
F - >35` — a different label convention than the other three dimensions,
though it maps to the same 6 bands. No gender-split Net Payroll sub-table
exists; a net figure would need to be derived.

Present in 2019-07 with the full four-category schema already applied
retroactively to 2017-18/2018-19 — not a later addition within the sampled
window. **However, the section is completely absent in 2020-08** (confirmed
via a full read) and reappears unchanged in 2021-01 — the one confirmed
on/off gap found across all four dimensions; a future pipeline must treat
"section missing" as an expected state for at least mid-2020, not a parse
failure.

Historical annual totals are **byte-identical across every file that carries
them** (e.g. the FY2017-18 grand total recurs unchanged in 2019-07 through
2025-09) — EPFO republishes rather than revises history for this table.

**Parsing feasibility — distinctly bimodal:**
- Historical blocks (2017-18 through 2023-24) are garbled in **every single
  report that contains them, including the newest (2025-09)** — label/value
  offsets that, parsed naively, can produce impossible rows (a "Male" figure
  exceeding its own row's "Total"). This is baked into every report vintage.
- Recent-period blocks became **clean starting with data from roughly May
  2024 onward** (first observed inside `2024-08.pdf`) and stay clean in every
  later sample.

Because historical figures never change between report vintages, they only
need to be correctly reconstructed **once** (cross-validatable against the
age-band table's own totals) — after which only new incremental months need
ongoing parsing, and those have been reliably clean since ~May 2024.

### Feasibility summary

Ranked easiest → hardest to add, based on: availability across the sample,
table complexity, and severity of parsing defects actually found.

| Rank | Dimension | Availability | Complexity | Parsing difficulty | Verdict |
|---|---|---|---|---|---|
| 1 (easiest) | **Gender-Wise** | 2019-07, 2021-01→2025-09; **absent 2020-08** | Lowest — fixed 4 categories × 6 slabs | Bimodal: historical garbled everywhere but frozen (fix once); clean since ~May 2024 | Cheap for current data; historical backfill is a bounded, one-time job |
| 2 | **Age-Band Detail** | No gaps, all 7 files | Low-moderate — fixed bands, 2 variants | Label/value misalignment in ~half the files, unpredictable, but one robust fix works | Straightforward with one parsing rule |
| 3 | **State-Wise** | No gaps, all 7 files; entity list stable | Moderate — stable ~32-row list, 4-12 growing columns | Every file shows numeric corruption, worsening with column count | Feasible but higher-risk; a table-aware extractor is worth it |
| 4 (hardest) | **Industry-Wise** | No gaps, all 7 files | Highest — dynamic, non-exhaustive, up to 6 lists/report | Heaviest wrapping; recurring bucket-specific column losses | Requires a sparse fact table over a 30+ industry union; hardest to automate |

**Caveat:** all of the above is grounded in a structural read of 7 of the 66
archived reports. Transition points described as "starting around" a given
file (e.g. the Gender-wise clean-data boundary near May 2024, the footnote
change near 2022) are bounded by the nearest sampled files on either side,
not confirmed month-by-month — a wider sampling pass across the remaining 59
files is recommended before finalizing any extraction design, particularly
for State-Wise and Industry-Wise given how much their difficulty scales with
column count.

## Reproducing this

`download_log.csv` records the exact URL and method used for every file, so the
whole dataset can be re-downloaded from scratch by replaying that log — no manual
guesswork needed.
