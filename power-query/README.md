# Power Query pipeline — how 66 PDFs become one clean table

This is the part of the project I put the most actual engineering into: turning
66 government PDF reports (not a clean CSV, not an API) into a single reliable
table I can build a Power BI data model on. The two files here —
[`fnExtractPage1.pq`](fnExtractPage1.pq) and
[`PayrollMonthly_Raw.pq`](PayrollMonthly_Raw.pq) — are the actual working M code,
paste-able straight into Power BI's Advanced Editor. What follows is the
reasoning behind them: not just what the code does, but why I built it this
way, including the bugs that shaped it.

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
the summary table I want across all 66 files — I checked this by hand against
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
**My first version of this just removed a fixed number of rows** (e.g. "always
skip the first 3"), because that's what worked for the first file I tested
(`2025-09.pdf`). It broke almost immediately on `2023-09.pdf`, which has a
different number of title/junk rows before its real header — the PDF's title
text wraps differently depending on subtle rendering differences between when
each report was generated. So instead of a fixed skip count, I search the
first column for wherever the word "Month" actually appears and skip to there
— that's correct regardless of how many junk rows precede it, for any file.

## Step 3 — rename columns by position, not by exact text

```m
Promoted = Table.PromoteHeaders(RemovedTop, [PromoteAllScalars = true]),
ColNames = Table.ColumnNames(Promoted),
Renamed = Table.RenameColumns(Promoted, {
    {ColNames{0}, "Month"},
    {ColNames{8}, "EstablishmentsFirstECR"}
}),
```
**This is the bug that took me longest to find.** The first two real header
labels ("Month/Age Band" and "Establishments remitting first ECR in the month")
wrap across multiple lines inside their PDF cell, so after promoting headers
they come through as text containing an embedded line-break character —
something like `"Month/Age Band"` with a literal `#(lf)` in the middle.

My first version of this pipeline matched that exact text, embedded line-break
included, to rename the columns. It worked for the one file I tested it
against and then silently failed on about 64 of the other 65 — not with an
error, just with the rename never happening, so every downstream row got
filtered out with nothing to show for why. I eventually traced it to different
report vintages using a different line-break character sequence inside that
same wrapped cell (LF vs CRLF), so an exact-text match only worked for
whichever files happened to share the exact sequence I'd tested against.

The fix was to stop caring what the text says at all and rename by **column
position** instead — "whatever the 1st column is called, call it Month."
Position stays stable even when the exact wrapped text doesn't.

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
I wrapped the whole per-file extraction in `try/otherwise`. If a file's
structure doesn't match — including a genuinely different one, see the known
gap below — it contributes zero rows instead of raising an error that kills
the whole 66-file combine. The fallback (`EmptyResult`) has to keep the
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
filenames, whatever's actually in the folder. That's what makes adding a new
month later as simple as dropping in the file and hitting Refresh (see the
main README). `Table.ExpandTableColumn` requires every nested table to share
the same column names, which is exactly why Step 4's fallback schema matters:
without it, one malformed file breaks the expand for the whole table, not just
its own row.

At this stage the combined table has **~403 rows**, not ~76 — because of the
next thing I ran into.

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

**This mechanism also recovered data I thought was permanently missing.**
July 2024 has no standalone PDF (see `data/raw/README.md` for why) — but it
turns out it's not actually absent from the final table, because a later
report (`2025-05.pdf`) retroactively includes it in its own fiscal-year table.
I found this by testing whether "Jul-2024" appeared anywhere in the
deduplicated output — it did.

## Step 7 — unpivot into a proper fact-table shape

```m
Unpivoted = Table.UnpivotOtherColumns(
    RemovedNullMonth, {"Name", "Month", "Total", "EstablishmentsFirstECR"},
    "AgeBand", "NetPayroll"
)
```
Up to this point the six age bands are six separate columns (a wide table).
For a real star schema — and to let a Power BI slicer/chart treat age band as
a normal filterable dimension — I need them as two columns instead: one row
per Month **per** age band. It's the same unpivot pattern behind the
`model/README.md` star-schema design.

## Step 8 — a real date column

```m
MonthStart = Date.FromText("01-" & [Month])
```
"Apr-2025" is text, not a date Power BI can use for time intelligence or a
calendar relationship. I prepend a fake day-of-month and parse it to get a
real date (the 1st of that month), explicitly typed as Date — which is what
the `Calendar` table's relationship joins against.

## Known gap: 2019-09.pdf

One file (out of 66) still contributes zero rows: its Page 1 table has "Month/
Age Band" landing in Column2 instead of Column1 — the whole table is shifted
one column right compared to every other file. I confirmed this by testing the
file in isolation and inspecting its raw structure directly. It's a genuine,
understood one-off (not the line-break bug, not the header-row-position issue
— a third, different quirk), and fixing it would mean adding column-shift
detection for the sake of one file out of 66. I documented it rather than
chasing it further — the same call I made for the July 2024 raw-file gap.

## Future scope: extending this pipeline past Page 1

`Pdf.Tables` sees every table across all of each report's pages (13 pages in
the earliest reports, growing to 24 by 2025), but this pipeline only reads
`"Table001 (Page 1)"`. The rest of each report — fiscal-year and monthly
age-band detail, state-wise, industry-wise, and gender-wise breakdowns, full
structural analysis in [`data/raw/README.md`](../data/raw/README.md#future-scope-extensions-beyond-page-1)
— is real, available data this same `Pdf.Tables` call already has access to;
I'm just filtering it out at the `Tables{[Name = "Table001 (Page 1)"]}` step.
Extending `fnExtractPage1` to also pull those tables is next on my list; I
went through 7 sample reports (2019-2025) in detail to work out what each
extension will actually need from this pipeline:

- **Age-Band Detail (the fiscal-year/monthly detail behind Page 1) is the
  most direct extension of what I've already built.** I can reuse the exact
  same dynamic-header-search and try/otherwise isolation from above; the one
  new wrinkle is that about half the sampled files have the detail table's
  row labels sitting on a different line than their own numeric values (not
  the rename-by-text bug above, but a related one) — so I'll need to pull
  labels and values as two independent ordered lists and zip them by
  position, rather than assume they share a line.
- **State-Wise and Industry-Wise will need a different extraction approach
  than the position-based rename I'm using here.** Every one of the 7
  sampled files shows numeric corruption in the State-Wise table, getting
  worse as the table gains columns each year (4 in 2019 → 12 by 2025): mild
  character interleaving in the earliest files, a clean one-row label/value
  offset through the middle years, and by 2025 the table's own banner text
  bleeding into data rows. Industry-Wise adds a second complication on top:
  its "top 10" industry list isn't a fixed dimension — it rotates release to
  release and differs by age bucket. Both are workable, but instead of
  reusing this file's text-position tricks, I want to prototype these
  against a table-aware extractor (pdfplumber/camelot/Tabula) rather than
  `pdftotext -layout`, since the failure mode here is silent — a naive
  parser wouldn't error, it would just swap one state's numbers onto
  another's row.
- **Gender-Wise is the one I'll build first once Age-Band Detail is done** —
  its schema is fixed (Male/Female/Transgender/Not Available × 6 age
  slabs), historical figures are byte-identical across every report vintage
  that carries them (so I only need to reconstruct them once), and every
  month has extracted cleanly since ~May 2024. The one thing I'll still need
  my `try/otherwise` pattern to tolerate: the section is genuinely absent
  from at least one sampled report (Aug 2020) — that has to come back as a
  valid empty state, not an error.

## Reproducing / extending this

Both `.pq` files are meant to be pasted directly into a Power BI Desktop
Advanced Editor — `fnExtractPage1` as a function query, `PayrollMonthly_Raw` as
the main query that calls it. Drop a new month's PDF into `data/raw/`, hit
Refresh, and the entire pipeline re-runs against the new file automatically —
no code changes needed.
