# Data model

## Fact table: PayrollMonthlyRaw

I built this entirely in Power Query (see `power-query/PayrollMonthly_Raw.pq` for the full,
documented M code). Grain: **one row per Month per AgeBand.**

Here's the pipeline, in order:
1. `Folder.Files` reads every PDF in `data/raw/`.
2. I parse each file with `Pdf.Tables`, extracting its Page-1 "Provisional Estimate
   of Net Payroll in Age Buckets" summary table (age bands × month/fiscal-year rows).
3. I wrap per-file parsing in `try/otherwise` so one malformed file can't break
   the other 65 — a failing file just contributes zero rows.
4. I combine all 66 files' extracted tables (`Table.ExpandTableColumn`) into one
   flat table — at this stage, ~403 rows, because each report's Page 1 is
   *cumulative for its fiscal year*, so consecutive months' reports overlap heavily.
5. I **dedupe** that down to ~76 rows: sort by source filename descending, then
   run `Table.Distinct` on Month — since filenames are `YYYY-MM.pdf`, sorting
   descending means the *most recent* report's figures win for any month reported
   in more than one file (EPFO revises "provisional" data in later releases).
6. I **unpivot** the six age-band columns (Less than 18, 18-21, 22-25, 26-28,
   29-35, More than 35) into two columns, `AgeBand` and `NetPayroll` — turning
   a wide table into the proper long/tall shape a fact table needs.
7. I add `MonthStart` — a real Date column parsed from the "Apr-2025"-style text
   Month label (`Date.FromText("01-" & [Month])`), explicitly typed as Date.
8. I add `AgeBandSort` — a Conditional Column mapping each `AgeBand` value to
   its natural order (1 for "Less than 18" up to 6 for "More than 35"), so I
   can sort `AgeBand` correctly instead of alphabetically. This has to be
   built here in Power Query rather than as a DAX calculated column — see
   `power-query/README.md` for why.

Final columns: `Name` (source file), `Month` (text label), `Total`,
`EstablishmentsFirstECR`, `AgeBand`, `NetPayroll`, `MonthStart` (date),
`AgeBandSort` (integer).

Final row count: **456** (76 unique months × 6 age bands).

Known gap: `2019-09.pdf` still fails extraction — a column-layout quirk unique to
that one file, where "Month/Age Band" lands in Column2 instead of Column1 — so it
contributes zero rows. That's one month out of ~77 possible; I've documented it
rather than chasing it down further. See `power-query/PayrollMonthly_Raw.pq` for
the full root-cause writeup.

## Date dimension: Calendar

A DAX calculated table (Modeling → New table):
```dax
Calendar = CALENDAR(MIN(PayrollMonthlyRaw[MonthStart]), MAX(PayrollMonthlyRaw[MonthStart]))
```
One row per day spanning the fact table's full date range. I expected the minimum
to land on July 2019, the earliest file I have standalone, but it turned out to be
**April 2019** instead — the same retroactive-fiscal-year effect that recovers
July 2024 also means `2019-07.pdf` itself retroactively includes Apr/May/Jun 2019,
the start of that fiscal year.

Calculated columns I added:
- `Year`, `MonthNumber`, `MonthName`, `Quarter` — standard calendar attributes
- `YearMonthSort` (`YYYYMM` integer) — hidden helper for correct chronological
  sort order (months don't sort correctly alphabetically)
- `FiscalYear` (e.g. "2019-20") and `FiscalQuarter` (Q1 = Apr-Jun ... Q4 = Jan-Mar)
  — matching EPFO's own reporting convention (India's fiscal year runs April to
  March), since that's how the source data itself groups time, not the calendar year

I marked this as an official **Date Table** (Modeling → Mark as date table, using
`Date`) so DAX time-intelligence functions work correctly against it.

## Relationships

- `Calendar[Date]` (1) → `PayrollMonthlyRaw[MonthStart]` (*) — single direction;
  it's the one relationship the whole star schema hangs off.

## Status: star schema complete

Fact table (PayrollMonthlyRaw) + Date dimension (Calendar), properly related.
This is what I built Phase 3's DAX measures on top of — see `dax/README.md`.

## Why this shape

I kept this as a deliberately simple star schema: one fact table (grain: Month ×
AgeBand) and one Date dimension. I do sort `AgeBand` correctly now (via the
`AgeBandSort` column above), but that's a lightweight fix on the fact table
itself, not a real dimension table. Pulling `AgeBand` out into its own
dimension table is still worth doing once I've got a second fact table (from
the Future Scope pages) that also needs to join to the same age bands — no
reason to build it before there's a second table to share it with.
