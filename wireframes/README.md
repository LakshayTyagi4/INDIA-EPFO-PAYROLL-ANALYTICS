# Wireframes

Plan for the report's pages, sketched out **before** building them in Power BI —
[`report_wireframe.svg`](report_wireframe.svg).

2 pages, each carrying several visuals:

1. **Overview & Trend** — KPI cards (latest month, MoM/YoY, age-band volatility
   gauge), Smart Narrative auto-summary, main Net Payroll trend chart with a
   Rolling 3-Month Average overlay, a month-over-month waterfall, a seasonality
   heatmap (month x fiscal year), a same-month-vs-last-2-years comparison, and
   a fiscal-quarter progress bar
2. **Age-Band Breakdown & COVID-19 Analysis** — a full page: Decomposition
   Tree, a bar chart and donut share chart by age band, Key Influencers, a
   small-multiples row of trend sparklines (one per age band), plus a
   dedicated COVID-19 section: a before/during/after 3-bar comparison, a
   zoomed trend chart with the Mar-Aug 2020 window highlighted, and a
   recovery timeline

A separate Methodology page was cut — that content (data source, refresh
cadence, known limitations, data model, pipeline diagram) already lives in
the various READMEs (see the main [README.md](../README.md)'s Documentation
section), so it didn't need its own report page.

This is a plan to build from, not a screenshot of the finished report — if the
actual build ends up diverging from it, update this file so it stays a
reliable record of intent rather than going stale.
