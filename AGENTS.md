# GoKarting UI Style Lock (Final Canonical Spec)

This is the non-negotiable UI style contract for this app.
Primary visual reference is the current `Sessions` and `Session` screens after latest fixes.

If a screen deviates from these patterns, it is a bug.

## 1) Visual Identity
- Dark, high-contrast motorsport theme.
- No bright/light backgrounds.
- Subtle glass materials, not heavy blur.
- Accent meaning:
  - Red = selected mode, primary CTA, critical performance number.
  - Blue = neutral filter/select chips.
  - Gray = secondary text/meta.

## 2) Color and Contrast
- Background: black / deep navy gradient (`appScreenBackground`).
- Primary text: white.
- Secondary text: `.secondary`.
- Selected chip/button text: white.
- Red controls: vivid coral-red.
- Blue controls: clear electric blue, used for neutral selectors.

Do not invent new accent colors for controls.

## 3) Top Header Pattern (Required)
All top-level tabs/screens must start with a manual in-content header:
- Title:
  - `.font(.system(.largeTitle, design: .rounded, weight: .bold))`
  - white
- Subtitle:
  - `.font(.subheadline)`
  - `.foregroundStyle(.secondary)`
- Header stack spacing: `6`.

Examples:
- `Sessions` + `Browse Time Trials or Race sessions.`
- `Tracks` + `Browse layouts, gates, and track metadata.`
- `Session` + `Configure, run, and review your live timing session.`

Navigation bar rule:
- Hide top nav chrome on these screens (`.toolbar(.hidden, for: .navigationBar)`) so title vertical position stays consistent.

## 4) Spacing System
- Horizontal screen padding: `20`.
- Top padding under safe area: `12`.
- Bottom content padding: `24`.
- Section spacing: `20` (default), `14` inside compact groups.
- Tight text stack spacing (title/subtitle): `6`.

No random per-screen spacing unless needed for overflow fixes.

## 5) Filter / Selector Rules (Most Important)
This was the biggest source of inconsistency. Follow exactly.

### 5.1 Neutral Selector Chip (All Combos style)
Use this exact pattern:
- `Menu { Picker(...) } label: { Label(...) ... }`
- Label style:
  - `.font(.subheadline.weight(.semibold))`
  - `.lineLimit(1)`
  - `.padding(.horizontal, 12)`
  - `.padding(.vertical, 10)`
  - `.frame(maxWidth: .infinity, alignment: .leading)` when full-width.
  - `.foregroundStyle(.blue)`
- Background:
  - `.glassCapsuleBackground(accented: false)`

This is the canonical chip style for:
- Track select
- Kart select
- Phone mount select
- Combo/range style filters

### 5.2 Selected Mode Chips (Time Trials / Races style)
- Build as custom buttons in a horizontal row.
- Active state:
  - `.glassCapsuleBackground(accented: true)` (red tint in existing helper)
  - white text/icon
- Inactive state:
  - `.glassCapsuleBackground(accented: false)`
  - normal light text

### 5.3 Forbidden Patterns for Filters
Do NOT:
- Wrap a single selector chip in a large card just to style it.
- Use oversized paddings (`16/14+`) for filter chips.
- Use plain `Picker(.segmented)` when it renders gray selected state and breaks red selected design.
- Create custom pill backgrounds that differ from `glassCapsuleBackground`.

## 6) Card System
- Main card container:
  - `.glassCard(radius: 30)` for large panels.
  - Internal padding typically `20`.
- Use section titles inside cards only when useful (`Map`, `Info`, `Start / Finish Gate`).
- Avoid redundant section labels above a single obvious control.
  - Example removed labels:
    - `Track` above lone track chip.
    - `Session Configuration` above selector group when header already explains context.

## 7) Typography Rules
- Main screen title: large rounded bold.
- Subtitle/meta: `subheadline` + `.secondary`.
- Chip/selector labels: `subheadline.semibold`.
- Card section titles: `title3.semibold`.
- KPI labels: secondary.
- KPI values: white; key performance values can be red.

Special known tweak:
- Dashboard tagline (`Track your speed. Beat your best.`) must be `subheadline`, not `title3`.

## 8) Controls
- Primary CTA button:
  - full-width capsule
  - red fill
  - white text
- Secondary actions should stay less prominent than primary CTA.

## 9) Maps and Data Panels
- Map cards remain in glass cards.
- Map frame stays compact and rounded (not edge-to-edge full screen in setup/list contexts).
- Keep supporting text muted (`.secondary`) and compact.

## 10) Bottom Tab Bar
- Keep floating/translucent style.
- Active tab blue highlight behavior must stay consistent.
- Do not change icon/label geometry per tab.

## 11) Implementation Checklist (Before Finishing Any UI Change)
- Does the screen have title + gray subtitle with correct sizes?
- Is nav bar hidden where needed to keep top alignment consistent?
- Are selectors using the canonical `Menu + Label + glassCapsuleBackground(false)` pattern?
- Are mode toggles using the red active capsule behavior?
- Are any selector chips wrapped in unnecessary giant cards? If yes, remove.
- Are spacing and paddings consistent with this spec?
- Does the screen visually match `Sessions` patterns at first glance?

## 12) Strict Rule
When there is ambiguity, copy `Sessions` control styling and spacing exactly and adapt only content labels.
