# Data model

## Fact table: PayrollMonthlyRaw

Built entirely in Power Query (see `power-query/PayrollMonthly_Raw.pq` for the full,
documented M code). Grain: **one row per Month per AgeBand.**

Pipeline, in order:
1. `Folder.Files` reads every PDF in `data/raw/`.
2. Each file is parsed via `Pdf.Tables`, extracting its Page-1 "Provisional Estimate
   of Net Payroll in Age Buckets" summary table (age bands × month/fiscal-year rows).
3. Per-file parsing is wrapped in `try/otherwise` so one malformed file can't break
   the other 65 — a failing file just contributes zero rows.
4. All 66 files' extracted tables are combined (`Table.ExpandTableColumn`) into one
   flat table — at this stage, ~403 rows, because each report's Page 1 is
   *cumulative for its fiscal year*, so consecutive months' reports overlap heavily.
5. **Deduplicated** down to ~76 rows: sorted by source filename descending, then
   `Table.Distinct` on Month — since filenames are `YYYY-MM.pdf`, sorting
   descending means the *most recent* report's figures win for any month reported
   in more than one file (EPFO revises "provisional" data in later releases).
6. **Unpivoted**: the six age-band columns (Less than 18, 18-21, 22-25, 26-28,
   29-35, More than 35) became two columns, `AgeBand` and `NetPayroll` — turning
   a wide table into the proper long/tall shape a fact table needs.
7. Added `MonthStart` — a real Date column parsed from the "Apr-2025"-style text
   Month label (`Date.FromText("01-" & [Month])`), explicitly typed as Date.

Final columns: `Name` (source file), `Month` (text label), `Total`,
`EstablishmentsFirstECR`, `AgeBand`, `NetPayroll`, `MonthStart` (date).

Final row count: **456** (76 unique months × 6 age bands).

Known gap: `2019-09.pdf` still fails extraction (a column-layout quirk unique to
that one file — "Month/Age Band" lands in Column2 instead of Column1) and
contributes zero rows. One month out of ~77 possible; documented, not chased
further. See `power-query/PayrollMonthly_Raw.pq` for the full root-cause writeup.

## Date dimension: Calendar

A DAX calculated table (Modeling → New table):
```dax
Calendar = CALENDAR(MIN(PayrollMonthlyRaw[MonthStart]), MAX(PayrollMonthlyRaw[MonthStart]))
```
One row per day spanning the fact table's full date range. Year/Month/Quarter
columns and marking it as an official Date Table are the next step (see
`dax/README.md` for the measure library as it's built out).

## Relationships

- `Calendar[Date]` (one) → `PayrollMonthlyRaw[MonthStart]` (many) — the core
  relationship the whole star schema hangs off.

## Why this shape

This is a deliberately simple star schema: one fact table (grain: Month × AgeBand)
and one Date dimension. An AgeBand dimension table (with a proper sort order, since
"Less than 18, 18-21, 22-25..." doesn't sort correctly alphabetically) is a
reasonable next enhancement once the core model and DAX measures are working.
