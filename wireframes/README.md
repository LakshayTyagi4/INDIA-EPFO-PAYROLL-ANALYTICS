# Wireframes

Plan for the report, sketched out **before** building it in Power BI —
[`report_wireframe.svg`](report_wireframe.svg).

**One consolidated dashboard page**, organized into 5 clearly labeled sections:

1. **Trend Overview** — main Net Payroll trend chart with a Rolling 3-Month
   Average overlay, a month-over-month waterfall, a Smart Narrative
   auto-summary, a seasonality heatmap (month x fiscal year), a
   same-month-vs-last-2-years comparison, and a fiscal-quarter progress bar
2. **Monthly Detail** — a Matrix table (Month x Net Payroll/MoM %/YoY %) with
   in-cell data bars
3. **Age-Band Breakdown** — Decomposition Tree, a bar chart and donut share
   chart by age band, Key Influencers, and a small-multiples row of trend
   sparklines (one per age band)
4. **COVID-19 Impact** — a before/during/after 3-bar comparison, a zoomed
   trend chart with the Mar-Aug 2020 window highlighted, and a recovery
   timeline
5. **Advanced Analysis** — a scatter/bubble chart (MoM % vs. YoY % by month,
   bubble size = Net Payroll, colored by age band) and a view-toggle button
   group (a field-parameter pattern that swaps which measure drives the
   page's visuals without duplicating charts)

One shared **Age Band filter** (multi-select pills) and **Fiscal Year slicer**
sit at the top, applying to the whole page — no per-section duplicates.

Typography follows a deliberate hierarchy: a big meta-title at the very top of
this wireframe document, a normal-sized dashboard header inside the card
(representing the actual Power BI page title), normal-sized section labels
dividing the 5 groups above, and small chart captions within each visual.
Every visual also carries a small italic annotation naming the actual DAX
measure or column behind it, and the legend includes the report's color theme
(slate grey primary, cyan/amber/emerald/red/pink accents) for Phase 5.

This is a plan to build from, not a screenshot of the finished report — if the
actual build ends up diverging from it, update this file so it stays a
reliable record of intent rather than going stale.
