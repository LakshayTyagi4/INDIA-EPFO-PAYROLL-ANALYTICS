# DAX measures

All measures live in a dedicated `_Measures` table (a `{BLANK()}` placeholder
table with its one column hidden) — kept separate from the data tables so the
model stays organized as more measures get added, rather than scattering them
across `PayrollMonthlyRaw`.

## Base measure

```dax
Total Net Payroll = SUM(PayrollMonthlyRaw[NetPayroll])
```
The foundation everything else builds on: sum of net payroll additions across
whatever's currently filtered (a month, an age band, a fiscal year, etc.).

## Time intelligence

```dax
Net Payroll PM = CALCULATE([Total Net Payroll], DATEADD(Calendar[Date], -1, MONTH))
MoM % Change   = DIVIDE([Total Net Payroll] - [Net Payroll PM], [Net Payroll PM])

Net Payroll PY = CALCULATE([Total Net Payroll], SAMEPERIODLASTYEAR(Calendar[Date]))
YoY % Change   = DIVIDE([Total Net Payroll] - [Net Payroll PY], [Net Payroll PY])
```
Standard month-over-month and year-over-year comparisons. Both are formatted as
percentages in the model. Note these rely on `Calendar` being marked as an
official Date Table — `DATEADD`/`SAMEPERIODLASTYEAR` need a proper contiguous
daily calendar to walk backwards correctly, which is exactly why the Calendar
table exists at daily grain even though the fact table is monthly.

**Real finding from testing this:** MoM % Change goes sharply negative for
April/May 2020 (from a positive ~570K in March 2020 to -284K in April) — India's
COVID-19 lockdown shows up directly in the DAX output, not just anecdotally.
See the `IsCovidEra` column and COVID comparison measures below.

## Trend smoothing

```dax
Rolling 3M Avg Net Payroll =
    CALCULATE([Total Net Payroll], DATESINPERIOD(Calendar[Date], LASTDATE(Calendar[Date]), -3, MONTH)) / 3
```
A 3-month rolling average, meant to sit alongside the raw monthly figure on the
Trend page's line chart — smooths out month-to-month noise so the underlying
direction is easier to read.

## Statistical

```dax
AgeBand Volatility = STDEVX.P(VALUES(PayrollMonthlyRaw[AgeBand]), CALCULATE([Total Net Payroll]))
```
Standard deviation of net payroll *across age bands* for whatever period is
filtered — a measure of how unevenly growth is spread across age groups in a
given month, rather than just looking at the overall total. Answers "is this
month's growth broad-based across ages, or concentrated in one age band?"

## COVID-19 impact

```dax
IsCovidEra =  -- Calendar table calculated column
    IF([Date] >= DATE(2020,3,1) && [Date] <= DATE(2020,8,31), "COVID Lockdown (Mar-Aug 2020)", "Normal")
```
Flags the window where the data shows clear disruption: negative net payroll in
Apr/May 2020, still-depressed June, recovering by August. The exact boundary is
a judgment call based on where the numbers actually turn negative and recover —
not an arbitrary date range.

```dax
Pre-COVID Avg Monthly Net Payroll =
    CALCULATE(AVERAGEX(VALUES(Calendar[YearMonthSort]), [Total Net Payroll]), Calendar[Date] < DATE(2020,3,1))

COVID Era Avg Monthly Net Payroll =
    CALCULATE(AVERAGEX(VALUES(Calendar[YearMonthSort]), [Total Net Payroll]), Calendar[IsCovidEra] = "COVID Lockdown (Mar-Aug 2020)")
```
The two headline comparison numbers for the planned COVID-19 Impact page (see
`wireframes/report_wireframe.svg`) — average monthly net payroll addition
before the lockdown vs. during it.

## Status

All 9 measures + the `IsCovidEra` column are built and confirmed in the model.
Not yet built: calculation groups (would consolidate the time-intelligence
measures into a single reusable set applied dynamically to any base measure)
and a what-if scenario parameter for projecting future growth — both still
planned as stretch enhancements once the report pages (Phase 4) are further along.
