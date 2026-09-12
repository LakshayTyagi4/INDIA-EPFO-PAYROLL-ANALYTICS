# Wireframes

Plan for the report's pages, sketched out **before** building them in Power BI —
[`report_wireframe.svg`](report_wireframe.svg).

2 pages, each carrying several visuals, plus explicit filtering on every page:

1. **Overview & Trend** — KPI cards (latest month, MoM/YoY, age-band volatility
   gauge), Smart Narrative auto-summary, main Net Payroll trend chart with a
   Rolling 3-Month Average overlay, a month-over-month waterfall, a seasonality
   heatmap (month x fiscal year), a same-month-vs-last-2-years comparison, a
   fiscal-quarter progress bar, an **Age Band filter** (multi-select pills), a
   Fiscal Year slicer, and a **Matrix table** (Month x Net Payroll/MoM %/YoY %)
   with in-cell data bars
2. **Age-Band Breakdown & COVID-19 Analysis** — a full page, with its own
   **Age Band filter row** and Fiscal Year slicer at the top, then:
   Decomposition Tree, a bar chart and donut share chart by age band, Key
   Influencers, a small-multiples row of trend sparklines (one per age band),
   a dedicated COVID-19 section (before/during/after 3-bar comparison, a
   zoomed trend chart with the Mar-Aug 2020 window highlighted, a recovery
   timeline), a **scatter/bubble chart** (MoM % vs. YoY % by month, bubble size
   = Net Payroll, colored by age band), and a **view-toggle button group**
   (a field-parameter pattern that swaps which measure drives the page's
   visuals — Net Payroll / MoM % / YoY % — without duplicating charts)

Every visual carries a small italic annotation naming the actual DAX measure
or column behind it, and the legend includes the report's color theme
(primary/secondary/positive/alert/card/text) for Phase 5.

A separate Methodology page was cut — that content already lives in the
various READMEs (see the main [README.md](../README.md)'s Documentation
section), so it didn't need its own report page.

This is a plan to build from, not a screenshot of the finished report — if the
actual build ends up diverging from it, update this file so it stays a
reliable record of intent rather than going stale.
