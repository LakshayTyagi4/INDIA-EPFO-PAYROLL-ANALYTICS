# Wireframes

This is my plan for the report, sketched out **before** I built it in Power BI —
[`report_wireframe.svg`](report_wireframe.svg), a static diagram of both pages
stacked one below the other (the format that actually renders inline on
GitHub). I also built
[`report_wireframe.html`](report_wireframe.html) — the same plan, but as a
real clickable prototype: a page-tab bar at the top switches between Action
Center and Overall Summary, the same way a Page Navigator would in the real
report. Download it and open it in a browser to click through it; GitHub's
file viewer only shows its source, not the rendered page.

## Page structure: a landing page, then the dashboard pages

The report has an **Action Center** page as the entry point — a plain title
plus a list of buttons, one per dashboard page, that jump straight there. Right
now that's a single button ("1. Overall Summary"), since Overall Summary is the
only dashboard page built so far, but the page is built to grow: as I add the
Age-Band Detail, Gender-Wise, State-Wise Map, and Industry-Wise pages from the
[Future scope](../README.md#future-scope), each one gets its own button here
rather than needing a redesign. Both pages are sketched in
[`report_wireframe.svg`](report_wireframe.svg) — Page 1 is Action Center,
Page 2 is the dashboard content below.

## The Overall Summary page

I laid it out as **one consolidated dashboard page**, organized into 3
clearly labeled sections. I originally sketched 6 (adding a Monthly Detail
matrix, an Advanced Analysis scatter chart with a view-toggle, and an
Establishment & Ranking Insights combo/ribbon chart), but decided to keep
the page to these 3 instead of building out the rest — here's the plan for
each, with what's actually built so far:

1. **Trend Overview** *(in progress)* — planned: main Net Payroll trend chart
   with a Rolling 3-Month Average overlay, a month-over-month waterfall, a
   Smart Narrative auto-summary, a seasonality heatmap (month x fiscal year),
   a same-month-vs-last-2-years comparison, and a fiscal-quarter progress
   bar. Built so far: the trend line chart with the rolling average overlay,
   and a Waterfall chart bound to Total Net Payroll by year (by year, not
   month-over-month as originally planned). One bug I've spotted: the
   waterfall's years aren't in chronological order (it renders
   2023, 2022, 2024, 2021, 2025, 2020, 2019 — largest total first, smallest
   last), which looks like the Year axis is sorting by the measure value
   instead of by Year itself. Still need to fix that (set the axis to sort
   by Year ascending) before this section is done. The rest is still to add.
2. **Age-Band Breakdown** *(in progress)* — planned: Decomposition Tree, a
   bar chart and donut share chart by age band, Key Influencers, and a
   small-multiples row of trend sparklines (one per age band). Built so far:
   a Treemap of Net Payroll by month (in place of the planned bar chart —
   worth double-checking whether that was meant to group by age band
   instead, to match the section), a Decomposition Tree explained by both
   AgeBand and Date (an earlier duplicate second tree has been removed),
   and the donut. Key Influencers and small multiples still to add.
3. **COVID-19 Impact** *(in progress)* — planned: a before/during/after
   3-bar comparison, a zoomed trend chart with the Mar-Aug 2020 window
   highlighted, and a recovery timeline. Built so far: the 3-bar comparison
   (a clustered column chart titled "Pre-COVID vs Post-COVID Impact",
   bound to `Pre-COVID Avg Monthly Net Payroll`, `COVID Era Avg Monthly Net
   Payroll`, and a new `Post-COVID Avg Monthly Net Payroll` measure I added
   for the "after" bar), plus a line chart of `MoM % Change` and
   `YoY % Change` over the full date range — I ended up building that
   second chart differently than planned: it's not zoomed to 2020 or
   highlighted, it's the full history of both percentage measures instead.
   The recovery timeline is still to add.

The page opens with its own title ("Overall Summary," in the same dark
slate as every other heading) and the logo mark in the top-right corner —
this replaced my original header-bar sketch once I saw how the real page
actually came together, though the KPI row from that original sketch made
it back in below the filters. The filter card holds the **Age Band
filter** (a row of pills) and a **date-range filter** on `Calendar[Date]`
(two date pickers) — not a Fiscal Year filter, which is what I'd originally
planned; `FiscalYear` still exists as a column on `Calendar` for later, it's
just not bound to a filter on this page. Both apply to the whole page below
them.

One thing still to fix: the pills currently render as "18-21, 22-25, 26-28,
29-35, Less than 18, More than 35" — that's a plain alphabetical sort on the
AgeBand text (1s and 2s sort before "L" and "M"), not the age order
`AgeBandSort` is supposed to enforce. My guess is this pill-style slicer
visual doesn't respect column-level Sort by Column the way the classic
Slicer does — I still need to check whether it has its own per-visual Sort
by option, or whether I have to switch back to the classic Slicer to get
correct ordering.

Another thing I only caught by re-checking the raw source PDFs directly: the
date-range filter's saved default is 01-06-2019 to 01-07-2025, but the model
actually has data back to April 2019 (`2019-07.pdf` itself has standalone
Apr-2019 and May-2019 rows in its fiscal-year table). So as saved, the page
is quietly excluding two real months of recovered data from every visual by
default — I need to widen the filter's start back to April 2019.

I set up the typography with a deliberate hierarchy: a big meta-title at the
very top of this wireframe document, the page's own title text below it (the
actual Power BI page heading), normal-sized section labels dividing the 3
groups above, and small chart captions within each visual. Every visual also
carries a small italic annotation naming the actual DAX measure or column
behind it — I kept that in the SVG deliberately, since it's build guidance,
not decoration.

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
| Extra accent | `#9D174D` (deep rose) | Additional data-series variety (small multiples, donut slice) |
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
- **Heatmap intensity**: darker cell = higher Net Payroll that month

This is a plan for me to build from, not a screenshot of the finished report
— if the actual build ends up diverging from it, I'll update this file so it
stays a reliable record of intent instead of going stale.
