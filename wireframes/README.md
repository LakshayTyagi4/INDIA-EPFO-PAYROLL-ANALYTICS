# Wireframes

Plan for the report's pages, sketched out **before** building them in Power BI —
[`report_wireframe.svg`](report_wireframe.svg).

Consolidated into 3 pages, each carrying several visuals:

1. **Overview & Trend** — KPI cards (latest month, MoM/YoY, age-band volatility
   gauge), Smart Narrative auto-summary, main Net Payroll trend chart with a
   Rolling 3-Month Average overlay, a month-over-month waterfall, a seasonality
   heatmap (month x fiscal year), a same-month-vs-last-2-years comparison, and
   a fiscal-quarter progress bar
2. **Age-Band Breakdown & COVID-19 Analysis** — Decomposition Tree, a bar chart
   and donut share chart by age band, Key Influencers, plus a dedicated
   COVID-19 section: a before/during/after 3-bar comparison, a zoomed trend
   chart with the Mar-Aug 2020 window highlighted, and a recovery timeline
3. **Methodology** — data source, refresh cadence, known limitations, a mini
   data-model diagram, and an end-to-end pipeline flow diagram (PDFs → Power
   Query → Star Schema → DAX → Report)

This is a plan to build from, not a screenshot of the finished report — if the
actual build ends up diverging from it, update this file so it stays a
reliable record of intent rather than going stale.
