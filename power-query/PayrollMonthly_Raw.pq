// Main query — name this "PayrollMonthlyRaw" in Power BI Desktop.
// Reads every PDF in data/raw, extracts each one's Page-1 monthly summary table,
// and combines the results into one table.
//
// v2 fix (the critical one): rename columns by POSITION, not by exact text match.
// Root cause found by testing 2023-09.pdf standalone: the wrapped header cell
// ("Month/Age Band", "Establishments remitting first ECR in the month") contains
// an embedded line break whose exact character sequence (LF vs CRLF) varies
// between different eras of this report template. Matching that text exactly
// silently failed for most files (no error — Table.RenameColumns with
// MissingField.Ignore just skipped the rename), which meant every row got
// filtered out by the later `[Month]`-based filter with zero visible error.
// Renaming by column position ({0} and {8}) instead is immune to that variation.
//
// Still contains duplicate months by design (each report's Page 1 shows every
// month of its fiscal year so far, so consecutive months' reports overlap) —
// deduplication, preferring the most recent report's figures per month, is a
// separate later step.
//
// Known remaining exception (as of this version): 2019-09.pdf still returns
// empty — investigate separately; does not block the rest of the pipeline
// thanks to the try/otherwise per-file isolation.
let
    Source = Folder.Files("C:\Lakshay\Everything\Personal Github Repos\EPFO Project\data\raw"),
    OnlyPDFs = Table.SelectRows(Source, each [Extension] = ".pdf"),
    AddParsed = Table.AddColumn(OnlyPDFs, "ParsedData", each
        let
            EmptyResult = #table(
                {"Month", "Less than 18", "18-21", "22-25", "26-28", "29-35", "More than 35", "Total", "EstablishmentsFirstECR"},
                {}
            ),
            Attempt = try
                let
                    Tables = Pdf.Tables([Content], [Implementation = "1.3"]),
                    Page1 = Tables{[Name = "Table001 (Page 1)"]}[Data],
                    FirstColName = Table.ColumnNames(Page1){0},
                    ColValues = Table.Column(Page1, FirstColName),
                    HeaderRowIndex = List.PositionOf(
                        List.Transform(ColValues, each Text.StartsWith(Text.From(_ ?? ""), "Month")),
                        true
                    ),
                    RemovedTop = Table.RemoveFirstN(Page1, HeaderRowIndex),
                    Promoted = Table.PromoteHeaders(RemovedTop, [PromoteAllScalars = true]),
                    ColNames = Table.ColumnNames(Promoted),
                    Renamed = Table.RenameColumns(Promoted, {
                        {ColNames{0}, "Month"},
                        {ColNames{8}, "EstablishmentsFirstECR"}
                    }),
                    Filtered = Table.SelectRows(
                        Renamed,
                        each let m = Record.FieldOrDefault(_, "Month", null) in m <> null and not Text.StartsWith(m, "2")
                    ),
                    Reordered = Table.SelectColumns(Filtered, Table.ColumnNames(EmptyResult))
                in
                    Reordered
            otherwise
                EmptyResult
        in
            Attempt
    ),
    KeptCols = Table.SelectColumns(AddParsed, {"Name", "ParsedData"}),
    Expanded = Table.ExpandTableColumn(
        KeptCols,
        "ParsedData",
        {"Month", "Less than 18", "18-21", "22-25", "26-28", "29-35", "More than 35", "Total", "EstablishmentsFirstECR"}
    )
in
    Expanded
