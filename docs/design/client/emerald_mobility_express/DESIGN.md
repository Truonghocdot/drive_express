---
name: Emerald Mobility & Express
colors:
  surface: '#f8f9ff'
  surface-dim: '#cbdbf5'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#eff4ff'
  surface-container: '#e5eeff'
  surface-container-high: '#dce9ff'
  surface-container-highest: '#d3e4fe'
  on-surface: '#0b1c30'
  on-surface-variant: '#404946'
  inverse-surface: '#213145'
  inverse-on-surface: '#eaf1ff'
  outline: '#707975'
  outline-variant: '#bfc9c4'
  surface-tint: '#2e685b'
  primary: '#003229'
  on-primary: '#ffffff'
  primary-container: '#054a3e'
  on-primary-container: '#7eb9a9'
  inverse-primary: '#97d2c2'
  secondary: '#006c49'
  on-secondary: '#ffffff'
  secondary-container: '#6cf8bb'
  on-secondary-container: '#00714d'
  tertiary: '#00312b'
  on-tertiary: '#ffffff'
  tertiary-container: '#004a41'
  on-tertiary-container: '#00c2ae'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#b2efde'
  primary-fixed-dim: '#97d2c2'
  on-primary-fixed: '#00201a'
  on-primary-fixed-variant: '#0f5044'
  secondary-fixed: '#6ffbbe'
  secondary-fixed-dim: '#4edea3'
  on-secondary-fixed: '#002113'
  on-secondary-fixed-variant: '#005236'
  tertiary-fixed: '#62fae3'
  tertiary-fixed-dim: '#3cddc7'
  on-tertiary-fixed: '#00201c'
  on-tertiary-fixed-variant: '#005047'
  background: '#f8f9ff'
  on-background: '#0b1c30'
  surface-variant: '#d3e4fe'
typography:
  headline-xl:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: -0.015em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '400'
    lineHeight: 16px
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 10px
    fontWeight: '700'
    lineHeight: 12px
    letterSpacing: 0.04em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-sm: 0.75rem
  margin: 1rem
  margin-lg: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1rem
  space-xl: 1.5rem
---

## Brand & Style

The design system creates a modern, trustworthy, and high-velocity mobile experience for on-demand transit and express logistics. It departs from sterile, generic utility design by blending deep, authoritative botanical tones with energetic, crystalline mint and teal highlights.

### Brand Personality & Emotional Impact
- **Decisive & Reassuring:** Deep forest and emerald hues project safety, operational scale, and structural reliability during time-sensitive tasks like summoning a driver or dispatching high-value parcels.
- **Fluid & Agile:** Vibrant accents guide user decisions with high contrast, conveying modern speed and responsiveness without sensory overwhelm.
- **Approachably Sophisticated:** Crisp rounded geometry, balanced information density, and calm, neutral surfaces give riders and senders a frictionless, premium everyday tool.

### Design Movement
**Modern Corporate Tech with Glass & Tactile Micro-Layers:** 
A calibrated synthesis of modern utilitarian mobile frameworks and soft physical depth. The system prioritizes tactile legibility through tinted surface containers, micro-borders with low opacity, and subtle ambient shadows tailored for daytime clarity and active outdoor use.

## Colors

The palette establishes an immediate identity rooted in deep botanical greens, supported by luminous mint accents and cool slate neutrals.

### Palette Architecture
- **Primary (`#054A3E`):** Deep Forest Emerald. Anchor color used for key visual headers, primary CTA buttons, dominant cards (such as the quick-booking prompt banner), active tab badges, and primary brand geometry.
- **Secondary (`#10B981`):** Electric Mint. Reserved for dynamic confirmations, ride progress markers, live tracking indicators, badge highlights, and secondary active state micro-interactions.
- **Tertiary (`#2DD4BF`):** Soft Turquoise / Teal. Utilized for route line highlights, promotional exploration chips, notification tags, and soft accent backdrops.
- **Neutral (`#64748B`):** Slate. Forms the bedrock of secondary typography, icon strokes, quiet structural outlines, and subdued utility labels.

### Functional Surfaces & Backgrounds
- **App Canvas:** `#F8FAFC` (Cool Off-White) ensures low eye fatigue and distinct contrast against card components.
- **Card / Surface Base:** `#FFFFFF` with an elevated tone alternative `#F1F5F9` for nested modules and group lists.
- **Text Primary:** `#0F172A` (Deep Slate Slate-900) delivers WCAG AAA compliance against both white surfaces and mint fills.
- **Critical & Error:** `#EF4444` specifically designated for cancellation, account logout, and urgent trip warnings.

## Typography

The type system blends the energetic geometric personality of **Plus Jakarta Sans** for headlines, service category titles, and navigation labels with the objective legibility of **Inter** for descriptions, rates, metadata, and multi-line ride updates.

### Scaling & Legibility Strategy
- **Headlines (`headline-xl`, `headline-lg`):** Reserved for screen headers ("Trang chủ", "Tài khoản"), top banner hooks, and high-level service callouts. Tight letter tracking ensures crisp hierarchy on compact viewports.
- **Body (`body-md`, `body-sm`):** Standardizes Vietnamese diacritics with generous line heights to prevent overlapping accents in multi-line addresses and descriptions.
- **Labels (`label-lg`, `label-md`, `label-sm`):** Used on interactive buttons, vehicle selector pills, and status tags (e.g., "Đang chạy", "Đã hoàn thành"). Medium-to-bold weights ensure clarity at glanceable speeds.

## Layout & Spacing

A compact, ergonomic rhythm tailored for one-thumb mobile accessibility in transit situations.

### Grid & Canvas Structure
- **Mobile Foundation:** Single-column fluid view anchored by a strict screen margin of `16px` (`margin`) up to `20px` (`margin-lg`) on wider devices.
- **Card Grids (Services & Booking Options):** Multi-column modules (such as "Giao hàng", "Đặt xe", "Đặt hộ") utilize an explicit 2-column or 3-column distribution separated by an internal gutter of `12px` (`gutter-sm`) to maximize tap target area while fitting within standard mobile viewports.
- **Bottom Navigation Clearances:** All primary scroll containers include a bottom padding offset of `88px` to guarantee zero overlap with the persistent 4-tab bar and system home-indicator.

## Elevation & Depth

Visual depth is achieved through quiet tonal shifts and ultra-soft, tinted ambient shadows rather than stark drop shadows, maintaining clean legibility in outdoor bright light.

### Elevation Hierarchy
- **Level 0 (Canvas):** Flat `#F8FAFC` base surface.
- **Level 1 (Card Default):** Pure `#FFFFFF` background bound by a 1px hairline border in `#E2E8F0` (`rgba(226, 232, 240, 0.8)`). Casts an ambient shadow: `0 2px 8px -2px rgba(5, 74, 62, 0.04), 0 1px 3px -1px rgba(0, 0, 0, 0.03)`.
- **Level 2 (Active & Floating Elements):** Top-level banners, floating action controls, and selected ride category tiles. Casts: `0 8px 20px -4px rgba(5, 74, 62, 0.08), 0 4px 6px -2px rgba(5, 74, 62, 0.04)`.
- **Level 3 (Modals, Sheets & Floating Navigation):** Persistent bottom navigation bar and driver dispatch bottom-sheets. Enhanced with a light frosted backdrop blur (`backdrop-filter: blur(12px)`) at `96%` surface opacity and elevated shadow `0 -4px 16px rgba(15, 23, 42, 0.04)`.

## Shapes

The geometric architecture balances friendliness and modern restraint through consistent Level 2 roundedness.

### Corner Radius Rules
- **Interactive Buttons & Form Fields:** `12px` to `16px` radius for a natural thumb press feel.
- **Service Action Tiles & Content Cards:** `16px` to `20px` corner curvature (`rounded-lg` / `rounded-xl`) offering soft visual separation between dense grid items.
- **Active Navigation Indicators & Status Chips:** Fully pill-shaped (`9999px`) to maintain immediate recognition as toggleable or tap-activated elements.
- **Nested Inner Modules:** Inside `16px` parent cards, child icon containers or sub-panels adhere to `10px` or `12px` to maintain concentric corner harmony.

## Components

### Buttons & Quick Triggers
- **Primary Button:** Background in Primary (`#054A3E`), foreground `#FFFFFF`, height `52px`, font `label-lg`, corner radius `14px`. On press, transitions to `#03322A` with a micro-scale factor of `0.98`.
- **Secondary / Ghost Button:** Transparent background, 1px border in `#CBD5E1`, text `#0F172A`. In active states, adopts a soft tint fill: `rgba(16, 185, 129, 0.08)`.

### Service Grid Tiles (Giao hàng, Đặt xe, Đặt hộ)
- Built on a solid white surface with a subtle 1px border `#E2E8F0`.
- Icon housing: circular or soft-square badge (`44px × 44px`) filled with soft mint tint (`#E6F7F2`), containing the primary emerald icon stroke.
- Content stack: Headline at `headline-md` (`16px`, bold), brief explanatory label at `body-sm` (`#64748B`). Padding is consistently `space-lg` (`16px`).

### Cards & Grouped List Rows (Tài khoản & Đơn hàng)
- Account modules group menu items into elevated surface containers.
- Each row contains an icon slot in muted slate/emerald, a primary label in `headline-md`, supporting text in `body-sm`, and an end-aligned chevron arrow (`#94A3B8`).
- Destructive items (e.g., "Đăng xuất") shift icon and text tone to `#DC2626` while retaining regular row geometry.

### Segmented Tabs (Hoạt động / Đơn hàng)
- Horizontal pill segment or underline tabs ("Đang chạy", "Đã hoàn thành").
- Selected tab features a bold indicator line (`3px` height) in Primary `#054A3E` or a pill container with `#054A3E` text and a background tint of `#E6F7F2`. Inactive tabs render in `#64748B`.

### Status Badges & Chips
- Compact, pill-shaped tags (`24px` height) with `8px` horizontal padding.
- **Active / Delivering:** Background `rgba(16, 185, 129, 0.12)`, text `#047857`, accompanied by a pulsating `6px` dot.
- **Completed:** Background `#F1F5F9`, text `#475569`.
- **Cancelled / Attention:** Background `rgba(239, 68, 68, 0.1)`, text `#B91C1C`.

### Bottom Navigation Bar (4 Tabs)
- Fixed at viewport base, `64px` height plus safe area padding. Background `#FFFFFF` with top border `1px solid #F1F5F9`.
- Tab architecture:
  1. **Trang chủ** (Home)
  2. **Hoạt động / Đơn hàng** (Activity)
  3. **Khám phá / Ưu đãi** (Explore)
  4. **Tài khoản** (Profile)
- **Active State:** Icon sits inside an ergonomic horizontal pill capsule (`56px × 32px`) filled with `#E6F7F2`, icon tinted in `#054A3E`. Bold label below in `label-sm` (`#054A3E`).
- **Inactive State:** Unadorned icon stroke in `#94A3B8`, text in `label-sm` (`#64748B`).