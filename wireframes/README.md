# Wireframes

This is my plan for the report, sketched out **before** I built it in Power BI —
[`report_wireframe.svg`](report_wireframe.svg).

## Page structure: a landing page, then the dashboard pages

The report has an **Action Center** page as the entry point — a plain title
plus a list of buttons, one per dashboard page, that jump straight there. Right
now that's a single button ("Overview"), since Overview is the only dashboard
page built so far, but the page is built to grow: as I add the Age-Band
Detail, Gender-Wise, State-Wise Map, and Industry-Wise pages from the
[Future scope](../README.md#future-scope), each one gets its own button here
rather than needing a redesign. The wireframe below is for the dashboard
content itself (the Overview page) — the landing page is simple enough not to
need its own mockup.

## The Overview page

I laid it out as **one consolidated dashboard page**, organized into 6 clearly labeled sections:

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
6. **Establishment & Ranking Insights** — a combo chart (Net Payroll as a
   line over New Establishments as bars — the first visual to use the
   `EstablishmentsFirstECR` field) and a ribbon chart showing how each age
   band's rank (by Net Payroll) shifts month to month

I put one shared **Age Band filter** (multi-select pills) and **Fiscal Year
slicer** at the top, applying to the whole page, so I didn't need per-section
duplicates.

I set up the typography with a deliberate hierarchy: a big meta-title at the
very top of this wireframe document, a normal-sized dashboard header inside
the card (representing the actual Power BI page title), normal-sized section
labels dividing the 5 groups above, and small chart captions within each
visual. Every visual also carries a small italic annotation naming the actual
DAX measure or column behind it — I kept that in the SVG deliberately, since
it's build guidance, not decoration.

I didn't draw the color legend and theme swatch on the wireframe itself (a
real dashboard shouldn't carry a key explaining its own colors) — see Visual
Details below instead.

## Visual details (Phase 5 reference)

**Color theme:**

| Role | Hex | Used for |
|---|---|---|
| Primary | `#1E293B` | Headers (gradient to `#020617`), primary chart lines/bars, KPI accents, filter pills |
| Accent | `#0E7490` (teal) | Secondary data series (decomposition tree children, donut 2nd slice, one small-multiples line) |
| Secondary | `#4C1D95` (deep violet) | YoY-change indicators, one small-multiples line, donut 3rd slice |
| Positive | `#047857` (deep green) | Growth/gain indicators (waterfall gains, Recovery bar) |
| COVID/Alert | `#991B1B` / `#B91C1C` (deep red) | COVID-era markers, waterfall drops, alert callouts |
| Extra accent | `#9D174D` (deep rose) | Additional data-series variety (small multiples, scatter chart) |
| Card background | `#F4F6FA` | KPI cards, callout boxes |
| Body text | `#6B7280` | Chart captions and secondary text |

I kept all the accent colors in a deliberately deep, muted tier so they'd
read as one cohesive family against the near-black primary, rather than
bright colors clashing against dark grey.

**Visual conventions:**
- **KPI card**: light background with a colored left accent bar (color is
  decorative grouping, not semantic)
- **Primary measure line**: solid, `#1E293B` — the main Net Payroll trend
- **Rolling avg overlay**: dashed, secondary color — smoothing overlay on the
  same chart
- **Waterfall bars**: green = gain vs. prior month, red = drop
- **Highlighted period**: translucent red rectangle marking Mar-Aug 2020 on
  time-series charts
- **Heatmap intensity**: darker cell = higher Net Payroll that month

This is a plan for me to build from, not a screenshot of the finished report
— if the actual build ends up diverging from it, I'll update this file so it
stays a reliable record of intent instead of going stale.
