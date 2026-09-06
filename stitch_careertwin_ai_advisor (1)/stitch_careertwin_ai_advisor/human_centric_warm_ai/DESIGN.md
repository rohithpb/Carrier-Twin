---
name: Human-Centric Warm AI
colors:
  surface: '#fef9f1'
  surface-dim: '#ded9d2'
  surface-bright: '#fef9f1'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f8f3eb'
  surface-container: '#f2ede5'
  surface-container-high: '#ede7e0'
  surface-container-highest: '#e7e2da'
  on-surface: '#1d1b17'
  on-surface-variant: '#57423c'
  inverse-surface: '#32302b'
  inverse-on-surface: '#f5f0e8'
  outline: '#8a726b'
  outline-variant: '#ddc0b8'
  surface-tint: '#a13f20'
  primary: '#9e3d1e'
  on-primary: '#ffffff'
  primary-container: '#be5434'
  on-primary-container: '#fffbff'
  inverse-primary: '#ffb59f'
  secondary: '#4a47d2'
  on-secondary: '#ffffff'
  secondary-container: '#6462ec'
  on-secondary-container: '#fffbff'
  tertiary: '#136948'
  on-tertiary: '#ffffff'
  tertiary-container: '#348260'
  on-tertiary-container: '#f5fff6'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#ffdbd1'
  primary-fixed-dim: '#ffb59f'
  on-primary-fixed: '#3a0a00'
  on-primary-fixed-variant: '#81280a'
  secondary-fixed: '#e2dfff'
  secondary-fixed-dim: '#c2c1ff'
  on-secondary-fixed: '#0c006b'
  on-secondary-fixed-variant: '#332dbc'
  tertiary-fixed: '#a4f3ca'
  tertiary-fixed-dim: '#88d6af'
  on-tertiary-fixed: '#002113'
  on-tertiary-fixed-variant: '#005236'
  background: '#fef9f1'
  on-background: '#1d1b17'
  surface-variant: '#e7e2da'
typography:
  headline-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 48px
    letterSpacing: -0.02em
  headline-xl-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 30px
    fontWeight: '700'
    lineHeight: 38px
    letterSpacing: -0.015em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.015em
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 24px
    fontWeight: '600'
    lineHeight: 32px
    letterSpacing: -0.01em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 26px
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 22px
  label-lg:
    fontFamily: Inter
    fontSize: 15px
    fontWeight: '500'
    lineHeight: 20px
  label-md:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 18px
    letterSpacing: 0.01em
  label-sm:
    fontFamily: Inter
    fontSize: 11px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.03em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  space-2xs: 0.25rem
  space-xs: 0.5rem
  space-sm: 0.75rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
  space-2xl: 3rem
  space-3xl: 4rem
  gutter-mobile: 1rem
  gutter-desktop: 1.5rem
  margin-mobile: 1rem
  margin-tablet: 2rem
  margin-desktop: 3rem
---

## Brand & Style

This design system is guided by a human-first, approachable ethos. Rather than cold, futuristic, or hyper-technical tropes, the aesthetic draws inspiration from conversational companions like Claude and ChatGPT—blending thoughtful editorial clarity with welcoming warmth.

### Emotional Target & Voice
- **Empathetic & Supportive:** Interactions feel like an encouraging partner, particularly across high-stress environments such as career progression, student placement, and mentoring.
- **Clear & Unpretentious:** Avoid sci-fi jargon, overly dense tech metrics, or algorithmic obfuscation. Use direct, conversational natural language (e.g., "Ready for review" instead of "Batch Pipeline Executed").
- **Calm Mastery:** Visuals balance open, breathable layouts with grounded typography, reducing cognitive fatigue during extended sessions.

### Design Movement: Warm Tactile Editorial
The style merges clean modern software paradigms with subtle editorial warmth:
- Soft off-white, warm-stone surfaces instead of stark clinical white or sterile blue-grays.
- Generous internal padding and fluid layouts that emphasize reading comfort.
- Rounded visual containers (16px base card radiuses) paired with quiet micro-borders and soft ambient shadows.
- Distinct semantic identities for core user roles (Students, Placement Coordinators, and Mentors) integrated natively without visual friction.

## Colors

The palette establishes an inviting atmosphere centered on warm terracotta earth tones, balanced by calm violet and organic herbal greens.

### Primary: Terracotta Coral (`#D96846`)
Acts as the central brand identity and focal interaction color. It provides a human, organic presence distinct from standard corporate blues, ideal for call-to-action buttons, active navigation triggers, and prominent AI highlight moments.

### Secondary: Soft Indigo / Violet (`#5E5CE6`)
Used for reflective AI generative states, assistant prompts, suggestions, and deep analytical actions. Also serves as the primary visual anchor for **Placement Coordinators**.

### Tertiary: Friendly Emerald (`#2E7D5B`)
Represents success states, validated achievements, affirmative status indicators, and serves as the visual signature for **Mentors**.

### Role-Based Semantics
- **Student Profile / Actions:** Warm Terracotta tint (`#FFF5F2` background, `#D96846` border and text).
- **Placement Coordinator Profile / Actions:** Soft Indigo tint (`#F5F5FE` background, `#5E5CE6` border and text).
- **Mentor Profile / Actions:** Friendly Emerald tint (`#F2F8F5` background, `#2E7D5B` border and text).

### Neutral & Surface Architecture
- **Base Canvas (`#FAF8F5`):** Warm stone neutral providing low-glare reading comfort.
- **Card & Surface (`#FFFFFF`):** Crisp white layer floating subtly above the base canvas.
- **Subtle Surface (`#F3EFEA`):** Low-contrast grouping containers, toolbars, and input backgrounds.
- **Borders & Dividers (`#E8E3DC`):** Delicate separation lines that define structural boundaries without stark contrast.
- **Body Text (`#2D2A26`):** Deep warm soot providing crisp, high-contrast readability without the harshness of pure black (`#000000`).
- **Muted Text (`#6F6C66`):** Balanced secondary tone for helper labels, timestamps, and contextual descriptions.

## Typography

Typography balances approachable friendliness with functional precision.

- **Headlines & Body (Plus Jakarta Sans):** The geometric yet humanist grotesque structure introduces round, open counters that evoke friendliness and transparency. It handles long-form natural dialogue and guidance cleanly.
- **Labels & System Meta (Inter):** Applied across compact elements such as status tags, metric readouts, navigation items, and button labels, ensuring legibility at smaller scales.

### Rhythm & Reading Ease
- Body line heights sit at a comfortable 1.55x–1.65x multiplier to allow room for effortless scanning.
- Conversational assistant prompts use `body-lg` to create a personal, dialogue-oriented pacing.
- Large numerical highlights always pair with a clear, conversational label beneath (e.g., "7 of 10 interviews completed" rather than cryptic abbreviations like "COMPL: 70%").

## Layout & Spacing

The layout is built on a 12-column responsive fluid grid designed around conversational containers and modular cards.

### Breakpoints & Adaptive Logic
- **Mobile (< 640px):** Single-column stack. Page margin `1rem`, card internal padding `1.25rem`. Complex dual actions collapse to vertical stacks.
- **Tablet (640px – 1024px):** 6-column fluid structure. Page margin `2rem`, gutter `1.5rem`. Role-indicator rails convert to top contextual banners.
- **Desktop (> 1024px):** 12-column grid with a maximum content container width of `1280px`. Left rail anchors navigation and AI copilot interaction, while the center canvas hosts multi-column card metrics and task lists.

### Spacing Philosophy
- Elements use an 8pt spatial baseline, with 4pt allowances for tight badge and label padding.
- Containers favor generous breathing room (`space-lg` to `space-xl`) inside cards to avoid dense information crowding.

## Elevation & Depth

Visual depth is achieved through gentle atmospheric layers and low-contrast borders rather than harsh, elevated shadows.

### Atmospheric Shadow Layers
- **Resting Card:** `0 1px 3px rgba(45, 42, 38, 0.04), 0 4px 12px rgba(45, 42, 38, 0.02)`. Grounded, soft, and blending naturally into the canvas.
- **Interactive / Hover:** `0 4px 6px rgba(45, 42, 38, 0.04), 0 12px 24px rgba(45, 42, 38, 0.06)`. Lifts subtly without sharp edges.
- **Floating Prompts & Overlays:** `0 8px 16px rgba(45, 42, 38, 0.06), 0 20px 36px rgba(45, 42, 38, 0.08)`. Reserved for modal assistant sheets and flyouts.

### Surface Outlines
All cards and floating containers incorporate a thin, muted border (`1px solid #E8E3DC`) to preserve boundary distinction across displays with varying contrast settings.

## Shapes

The interface embraces organic curvature to foster an accessible, relaxed atmosphere.

- **Standard Cards & Modular Panels:** Set to a foundational `16px` (`1rem`) radius, providing a tactile, pillowed appearance.
- **Interactive Buttons & Controls:** Formed with an `8px` (`0.5rem`) radius for crisp touch targets, balancing the softer container shapes.
- **Pills & Status Badges:** Fully circular (`rounded-full` / 9999px) to accentuate their metadata nature and prevent confusion with actionable card boundaries.
- **Input Fields:** Styled with `10px` roundedness to feel soft and welcoming to type in.

## Components

### Buttons
- **Primary:** Terracotta background (`#D96846`), white text, `8px` radius, `0 2px 6px rgba(217, 104, 70, 0.25)` drop shadow. Smooth hover lift with a subtle tint deepen (`#C55A3A`).
- **Secondary:** Soft off-white surface (`#FFFFFF`) with border (`#E8E3DC`), dark text (`#2D2A26`). Hover transitions surface to `#F3EFEA`.
- **Copilot Action Button:** Indigo background (`#5E5CE6`), white text, accompanied by an inline icon representing assistance or insights.

### Badges & Role Indicators
Semantic badges are rendered with soft pastel fills and saturated text to maintain high readability:
- **Student Indicator:** `#FFF5F2` background, `#D96846` text, `1px solid rgba(217, 104, 70, 0.2)`. Label: "Student".
- **Coordinator Indicator:** `#F5F5FE` background, `#5E5CE6` text, `1px solid rgba(94, 92, 230, 0.2)`. Label: "Coordinator".
- **Mentor Indicator:** `#F2F8F5` background, `#2E7D5B` text, `1px solid rgba(46, 125, 91, 0.2)`. Label: "Mentor".

### Cards
- Constructed with `#FFFFFF` backgrounds, `16px` border radiuses, and ambient soft shadowing.
- Header sections integrate conversational progress or summary text followed by contextual metadata badges in the top-right corner.
- Padded with `1.5rem` to keep metric points and summaries easily scannable.

### Input Fields & Search Bars
- Background set to `#FFFFFF` with an `#E8E3DC` boundary.
- Focused state replaces the perimeter border with a 2px Terracotta ring (`#D96846`) and a soft outer glow (`rgba(217, 104, 70, 0.15)`).
- Natural language placeholder examples (e.g., "Ask anything about upcoming interviews, prep materials, or schedule changes...").

### Conversational Copilot Feed & Cards
- Chat containers use a dual-bubble architecture:
  - **User Query:** Outlined warm-slate pill on the right (`#F3EFEA`).
  - **AI Assistant Response:** Open, unbounded left-aligned card with subtle left border accent (`3px solid #D96846` or `#5E5CE6`), rendering responses with clear bullet points, warm conversational transitions, and interactive confirmation chips.

### Checkboxes & Radio Controls
- Circular check handles with `4px` radius for checkboxes and 50% pill radius for radios.
- Unchecked: `#FFFFFF` fill with a `1.5px solid #E8E3DC` stroke.
- Checked: `#D96846` fill with an interior white checkmark icon.