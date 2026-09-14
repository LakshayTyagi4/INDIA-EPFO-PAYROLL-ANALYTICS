# Processed data

I'm planning to export `payroll_monthly.csv` here once the report itself is
further along — the cleaned, combined output of the Power Query extraction
(one row per month per age band), so the dataset is inspectable on GitHub
without opening Power BI Desktop. Not exported yet.

To generate it: refresh the .pbix, then export the `PayrollMonthlyRaw` table
from Data view (right-click the table → Copy table, or use the "Export data"
option on any visual built from it) and save it here as `payroll_monthly.csv`.
