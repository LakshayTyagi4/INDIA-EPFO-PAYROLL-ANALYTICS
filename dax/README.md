# DAX measures

I keep all my measures in a dedicated `_Measures` table (a `{BLANK()}`
placeholder table with its one column hidden), separate from the data tables.
I did this so the model stays organized as I add more measures, instead of
scattering them across `PayrollMonthlyRaw`.

## Base measure

```dax
Total Net Payroll = SUM(PayrollMonthlyRaw[NetPayroll])
```
This is the foundation everything else builds on: the sum of net payroll
additions across whatever's currently filtered — a month, an age band, a
fiscal year, and so on.

## Time intelligence

```dax
Net Payroll PM = CALCULATE([Total Net Payroll], DATEADD(Calendar[Date], -1, MONTH))
MoM % Change   = DIVIDE([Total Net Payroll] - [Net Payroll PM], [Net Payroll PM])

Net Payroll PY = CALCULATE([Total Net Payroll], SAMEPERIODLASTYEAR(Calendar[Date]))
YoY % Change   = DIVIDE([Total Net Payroll] - [Net Payroll PY], [Net Payroll PY])
```
These are standard month-over-month and year-over-year comparisons, and I
formatted both as percentages in the model. One thing worth noting: they
depend on `Calendar` being marked as an official Date Table. `DATEADD` and
`SAMEPERIODLASTYEAR` need a proper contiguous daily calendar to walk backwards
correctly, which is why I built the Calendar table at daily grain even though
the fact table itself is monthly.

**Something I found while testing this:** MoM % Change goes sharply negative
for April/May 2020 — from a positive ~570K in March 2020 to -284K in April.
India's COVID-19 lockdown shows up directly in the DAX output, not just
anecdotally in the news. See the `IsCovidEra` column and the COVID comparison
measures below.

## Trend smoothing

```dax
Rolling 3M Avg Net Payroll =
    CALCULATE([Total Net Payroll], DATESINPERIOD(Calendar[Date], LASTDATE(Calendar[Date]), -3, MONTH)) / 3
```
I built this as a 3-month rolling average to sit alongside the raw monthly
figure on the line chart in the Trend Overview section of the Overall
Summary page. It smooths out month-to-month noise so
the underlying direction is easier to read.

## Statistical

```dax
AgeBand Volatility = STDEVX.P(VALUES(PayrollMonthlyRaw[AgeBand]), CALCULATE([Total Net Payroll]))
```
This is the standard deviation of net payroll *across age bands* for whatever
period is filtered. It's a measure of how unevenly growth is spread across age
groups in a given month, rather than just looking at the overall total — it
answers the question "is this month's growth broad-based across ages, or
concentrated in one age band?"

## COVID-19 impact

```dax
IsCovidEra =  -- Calendar table calculated column
    IF([Date] >= DATE(2020,3,1) && [Date] <= DATE(2020,8,31), "COVID Lockdown (Mar-Aug 2020)", "Normal")
```
This flags the window where the data shows clear disruption: negative net
payroll in Apr/May 2020, still-depressed June, and recovery by August. I
set the exact boundary by looking at where the numbers actually turn
negative and recover, not by picking an arbitrary date range.

```dax
Pre-COVID Avg Monthly Net Payroll =
    CALCULATE(AVERAGEX(VALUES(Calendar[YearMonthSort]), [Total Net Payroll]), Calendar[Date] < DATE(2020,3,1))

COVID Era Avg Monthly Net Payroll =
    CALCULATE(AVERAGEX(VALUES(Calendar[YearMonthSort]), [Total Net Payroll]), Calendar[IsCovidEra] = "COVID Lockdown (Mar-Aug 2020)")
```
These are the two headline comparison numbers I plan to use in the
COVID-19 Impact section of the Overall Summary page (see
`wireframes/report_wireframe.svg`): average monthly net payroll addition
before the lockdown versus during it.

## Status

I've built all 9 measures plus the `IsCovidEra` column, and I checked them in
the model — they work as expected. I still need to build calculation groups,
which would consolidate the time-intelligence measures into a single reusable
set I can apply dynamically to any base measure, and a what-if scenario
parameter for projecting future growth. I'm planning both as stretch
enhancements once I get further along on the report pages (Phase 4).
