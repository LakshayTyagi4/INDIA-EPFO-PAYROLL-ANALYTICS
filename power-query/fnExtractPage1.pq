// Function query — name this "fnExtractPage1" in Power BI Desktop.
// Takes one PDF file's binary content, returns its cleaned Page-1 monthly summary table.
//
// v3: entire body wrapped in try/otherwise. Some files (mostly the older Wayback-
// recovered 2019/2020 reports, which predate the current template) produce a
// differently-shaped Page 1 table that broke the plain v2 attempt at the whole-row
// level during Table.ExpandTableColumn, not just a missing field. Any failure now
// falls back to an empty table with the exact same column signature as a successful
// parse, so one malformed file can never break the 66-file combine — it just
// contributes zero rows, and can be investigated separately afterward.
let
    fnExtractPage1 = (fileContent as binary) as table =>
        let
            EmptyResult = #table(
                {"Month", "Less than 18", "18-21", "22-25", "26-28", "29-35", "More than 35", "Total", "EstablishmentsFirstECR"},
                {}
            ),
            Attempt = try
                let
                    Tables = Pdf.Tables(fileContent, [Implementation = "1.3"]),
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
                    // Force the exact same column set/order as EmptyResult so every file's
                    // output has an identical schema, success or fallback.
                    Reordered = Table.SelectColumns(Filtered, Table.ColumnNames(EmptyResult))
                in
                    Reordered
            otherwise
                EmptyResult
        in
            Attempt
in
    fnExtractPage1
