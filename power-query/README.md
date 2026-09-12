# Power Query pipeline — how 66 PDFs become one clean table

This is the part of the project with the most actual engineering in it: turning
66 government PDF reports (not a clean CSV, not an API) into a single reliable
table Power BI can build a data model on. The two files here —
[`fnExtractPage1.pq`](fnExtractPage1.pq) and
[`PayrollMonthly_Raw.pq`](PayrollMonthly_Raw.pq) — are the actual working M code,
paste-able straight into Power BI's Advanced Editor. What follows is the
reasoning behind them: not just what the code does, but why it's shaped this way,
including the bugs that shaped it.

## The problem, in one sentence

Every one of EPFO's 66 monthly PDF reports has a table on Page 1 showing net
payroll additions by age band — but no two months' PDFs are guaranteed to look
byte-identical internally, and a pipeline that assumes they do will silently
break on real files.

## Step 1 — read the PDF, find the real table

```m
Tables = Pdf.Tables(fileContent, [Implementation = "1.3"]),
Page1 = Tables{[Name = "Table001 (Page 1)"]}[Data],
```
Power Query's PDF connector splits every page of a document into detected
tables (`Table001 (Page 1)`, `Table002 (Page 3)`, etc.). Page 1 is consistently
the summary table we want across all 66 files — verified by hand against
several files before trusting it as a rule.

## Step 2 — find the header row, don't assume its position

```m
FirstColName = Table.ColumnNames(Page1){0},
ColValues = Table.Column(Page1, FirstColName),
HeaderRowIndex = List.PositionOf(
    List.Transform(ColValues, each Text.StartsWith(Text.From(_ ?? ""), "Month")),
    true
),
RemovedTop = Table.RemoveFirstN(Page1, HeaderRowIndex),
```
**The naive version of this just removes a fixed number of rows** (e.g. "always
skip the first 3"), because that's what worked for the first file tested
(`2025-09.pdf`). It broke almost immediately on `2023-09.pdf`, which has a
different number of title/junk rows before its real header — the PDF's title
text wraps differently depending on subtle rendering differences between when
each report was generated. Instead of a fixed skip count, this searches the
first column for wherever the word "Month" actually appears and skips to there
— correct regardless of how many junk rows precede it, for any file.

## Step 3 — rename columns by position, not by exact text

```m
Promoted = Table.PromoteHeaders(RemovedTop, [PromoteAllScalars = true]),
ColNames = Table.ColumnNames(Promoted),
Renamed = Table.RenameColumns(Promoted, {
    {ColNames{0}, "Month"},
    {ColNames{8}, "EstablishmentsFirstECR"}
}),
```
**This is the bug that took the longest to find.** The first two real header
labels ("Month/Age Band" and "Establishments remitting first ECR in the month")
wrap across multiple lines inside their PDF cell, so after promoting headers
they come through as text containing an embedded line-break character —
something like `"Month/Age Band"` with a literal `#(lf)` in the middle.

The first version of this pipeline matched that exact text, embedded line-break
included, to rename the columns. It worked for the one file it was tested
against and then silently failed on ~64 of the other 65 — not with an error,
just with the rename never happening, so every downstream row got filtered out
with nothing to show for why. The root cause: different report vintages use a
different line-break character sequence inside that same wrapped cell (LF vs
CRLF), so an exact-text match only worked for whichever files happened to share
the exact sequence tested against.

The fix was to stop caring what the text says at all and rename by **column
position** instead — "whatever the 1st column is called, call it Month."
Position is stable even when the exact wrapped text isn't.

## Step 4 — never let one bad file break the other 65

```m
Attempt = try
    let
        ... all of the above ...
    in
        Reordered
otherwise
    EmptyResult   -- same 9 columns, zero rows
```
The whole per-file extraction is wrapped in `try/otherwise`. If a file's
structure doesn't match — including a genuinely different one, see the known
gap below — it contributes zero rows instead of raising an error that kills the
whole 66-file combine. Critically, the fallback (`EmptyResult`) has the
**exact same column signature** as a successful parse, which matters for the
next step.

## Step 5 — combine and expand

```m
Source = Folder.Files("...\data\raw"),
OnlyPDFs = Table.SelectRows(Source, each [Extension] = ".pdf"),
AddParsed = Table.AddColumn(OnlyPDFs, "ParsedData", each ...the above...),
Expanded = Table.ExpandTableColumn(KeptCols, "ParsedData", {9 named columns})
```
`Folder.Files` reads every PDF in `data/raw/` — not a hardcoded list of 66
filenames, whatever's actually in the folder. This is what makes adding a new
month later as simple as dropping in the file and hitting Refresh (see the
main README). `Table.ExpandTableColumn` requires every nested table to share
the same column names, which is exactly why Step 4's fallback schema matters:
without it, one malformed file breaks the expand for the whole table, not just
its own row.

At this stage the combined table has **~403 rows**, not ~76 — because of the
next thing this project uncovered.

## Step 6 — deduplicate: each report is cumulative for its fiscal year

Each PDF's Page 1 doesn't only show its own month — it shows every month of its
fiscal year (April onward) up to itself. A February 2024 report shows Apr 2023
through Jan 2024, all in the same table. That means consecutive months'
reports overlap heavily, and simply combining all 66 files produces many
duplicate rows for the same calendar month, sourced from different reports.

```m
SortedRows = Table.Sort(Expanded, {{"Name", Order.Descending}}),
RemovedDuplicates = Table.Distinct(SortedRows, {"Month"}),
```
Because files are named `YYYY-MM.pdf`, sorting by filename descending puts the
most recent report first for any given month. `Table.Distinct` then keeps only
the first (= most recent) row per month — which matters because EPFO
explicitly marks this data "provisional" and revises it in later releases, so
the newest available figure is the most accurate one.

**This mechanism also recovered data we thought was permanently missing.**
July 2024 has no standalone PDF (see `data/raw/README.md` for why) — but it's
not actually absent from the final table, because a later report
(`2025-05.pdf`) retroactively includes it in its own fiscal-year table. Found
by testing whether "Jul-2024" appeared anywhere in the deduplicated output —
it did.

## Step 7 — unpivot into a proper fact-table shape

```m
Unpivoted = Table.UnpivotOtherColumns(
    RemovedNullMonth, {"Name", "Month", "Total", "EstablishmentsFirstECR"},
    "AgeBand", "NetPayroll"
)
```
Up to this point the six age bands are six separate columns (a wide table).
For a real star schema — and for letting a Power BI slicer/chart treat age band
as a normal filterable dimension — they need to be two columns instead: one
row per Month **per** age band. This is the same unpivot pattern behind the
`model/README.md` star-schema design.

## Step 8 — a real date column

```m
MonthStart = Date.FromText("01-" & [Month])
```
"Apr-2025" is text, not a date Power BI can use for time intelligence or a
calendar relationship. Prepending a fake day-of-month and parsing gives a real
date (the 1st of that month), explicitly typed as Date — which is what the
`Calendar` table's relationship joins against.

## Known gap: 2019-09.pdf

One file (out of 66) still contributes zero rows: its Page 1 table has "Month/
Age Band" landing in Column2 instead of Column1 — the whole table is shifted
one column right compared to every other file. Confirmed by testing this file
in isolation and inspecting its raw structure directly. This is a genuine,
understood one-off (not the line-break bug, not the header-row-position issue —
a third, different quirk), and fixing it would mean adding column-shift
detection for the sake of one file out of 66. Documented rather than chased
further, the same call made for the July 2024 raw-file gap.

## What's next for this pipeline: extending past Page 1

`Pdf.Tables` sees every table across all of each report's pages (13 pages in
the earliest reports, growing to 24 by 2025), but this pipeline only reads
`"Table001 (Page 1)"`. The rest of each report — fiscal-year and monthly
age-band detail, state-wise, industry-wise, and gender-wise breakdowns, full
structural analysis in [`data/raw/README.md`](../data/raw/README.md#planned-extensions-beyond-page-1)
— is real, available data this same `Pdf.Tables` call already has access to;
it's just filtered out at the `Tables{[Name = "Table001 (Page 1)"]}` step.
Extending `fnExtractPage1` to also pull those tables is the plan; a
structural deep-read across 7 sample reports (2019-2025) already scoped out
what each extension will need from this pipeline specifically:

- **Age-Band Detail (the fiscal-year/monthly detail behind Page 1) is the
  most direct extension of this file's own logic.** It reuses the exact
  same dynamic-header-search and try/otherwise isolation built above; the
  one new wrinkle is that about half the sampled files have the detail
  table's row labels sitting on a different line than their own numeric
  values (not the rename-by-text bug above, but a related one) — so labels
  and values need to be pulled as two independent ordered lists and zipped
  by position, rather than assumed to share a line.
- **State-Wise and Industry-Wise will need a different extraction approach
  than the position-based rename this file relies on.** Every one of the 7
  sampled files shows numeric corruption in the State-Wise table, getting
  worse as the table gains columns each year (4 in 2019 → 12 by 2025): mild
  character interleaving in the earliest files, a clean one-row label/value
  offset through the middle years, and by 2025 the table's own banner text
  bleeding into data rows. Industry-Wise adds a second complication on top:
  its "top 10" industry list isn't a fixed dimension, it rotates release to
  release and differs by age bucket. Both are workable, but rather than
  reusing this file's text-position tricks, they're worth prototyping
  against a table-aware extractor (pdfplumber/camelot/Tabula) instead of
  `pdftotext -layout`, since the failure mode here is silent — a naive
  parser wouldn't error, it would just swap one state's numbers onto
  another's row.
- **Gender-Wise is the one to build first once Age-Band Detail is done** —
  its schema is fixed (Male/Female/Transgender/Not Available × 6 age
  slabs), historical figures are byte-identical across every report vintage
  that carries them (so they only need reconstructing once), and every
  month has extracted cleanly since ~May 2024. The only thing this
  pipeline's `try/otherwise` pattern needs to additionally tolerate: the
  section is confirmed absent entirely from at least one sampled report
  (Aug 2020) — that has to come back as a valid empty state, not an error.

## Reproducing / extending this

Both `.pq` files are meant to be pasted directly into a Power BI Desktop
Advanced Editor — `fnExtractPage1` as a function query, `PayrollMonthly_Raw` as
the main query that calls it. Dropping a new month's PDF into `data/raw/` and
hitting Refresh re-runs this entire pipeline against the new file automatically
— no code changes needed.
