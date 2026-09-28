---
name: Apex Driver Transit
colors:
  surface: '#0d1320'
  surface-dim: '#0d1320'
  surface-bright: '#333948'
  surface-container-lowest: '#080e1b'
  surface-container-low: '#161b29'
  surface-container: '#1a1f2d'
  surface-container-high: '#242a38'
  surface-container-highest: '#2f3543'
  on-surface: '#dde2f5'
  on-surface-variant: '#bbcabf'
  inverse-surface: '#dde2f5'
  inverse-on-surface: '#2a303f'
  outline: '#86948a'
  outline-variant: '#3c4a42'
  surface-tint: '#4edea3'
  primary: '#4edea3'
  on-primary: '#003824'
  primary-container: '#10b981'
  on-primary-container: '#00422b'
  inverse-primary: '#006c49'
  secondary: '#4cd7f6'
  on-secondary: '#003640'
  secondary-container: '#03b5d3'
  on-secondary-container: '#00424e'
  tertiary: '#ffb95f'
  on-tertiary: '#472a00'
  tertiary-container: '#e29100'
  on-tertiary-container: '#523200'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#6ffbbe'
  primary-fixed-dim: '#4edea3'
  on-primary-fixed: '#002113'
  on-primary-fixed-variant: '#005236'
  secondary-fixed: '#acedff'
  secondary-fixed-dim: '#4cd7f6'
  on-secondary-fixed: '#001f26'
  on-secondary-fixed-variant: '#004e5c'
  tertiary-fixed: '#ffddb8'
  tertiary-fixed-dim: '#ffb95f'
  on-tertiary-fixed: '#2a1700'
  on-tertiary-fixed-variant: '#653e00'
  background: '#0d1320'
  on-background: '#dde2f5'
  surface-variant: '#2f3543'
typography:
  display-currency:
    fontFamily: Inter
    fontSize: 38px
    fontWeight: '800'
    lineHeight: 44px
    letterSpacing: -0.03em
  display-currency-mobile:
    fontFamily: Inter
    fontSize: 30px
    fontWeight: '800'
    lineHeight: 36px
    letterSpacing: -0.02em
  headline-xl:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 28px
    letterSpacing: -0.01em
  headline-md:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 22px
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
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 18px
    letterSpacing: 0.01em
  label-md:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '600'
    lineHeight: 16px
    letterSpacing: 0.02em
  label-sm:
    fontFamily: Inter
    fontSize: 10px
    fontWeight: '700'
    lineHeight: 14px
    letterSpacing: 0.05em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-mobile: 0.75rem
  margin: 1rem
  margin-mobile: 0.75rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
---

## Brand & Style

The design system is engineered specifically for mobility operators, rideshare drivers, and express couriers navigating high-pressure, fast-moving physical environments. The interface balances high-contrast glanceability with reduced cognitive load during night shifts, extreme daylight glare, and dashboard-mounted device interactions.

Drawing from modern utility-driven dark mode frameworks, the aesthetic combines deep oceanic navy tones, translucent layered glassmorphic cards, and hyper-legible status indicators. The emotional intent is clear: calm efficiency, absolute reliability, uncompromising road safety, and instant situational awareness. Every component prioritizes rapid tactile recognition with large interaction footprints suited for one-handed operation.

## Colors

The palette uses a deliberate hierarchy of deep slate-navy surfaces punctuated by mission-critical functional accents. The system deliberately avoids pure pitch black (#000000) to eliminate OLED smearing and reduce eye strain across extended shifts.

### Palette Hierarchy & Intent
- **Base Surfaces**: `#0B111E` (Canvas/Map Base), `#111A2E` (Surface Layer 1 / Bottom Sheets), `#18233C` (Surface Layer 2 / Elevated Cards), `#233354` (Surface Highlight & Field Backgrounds).
- **Primary Emerald (`#10B981`)**: Dedicated to online status, active job acceptance, pickup pin locations, and route completion affirmations.
- **Secondary Cyan & Blue (`#06B6D4`, `#3B82F6`)**: Reserved for digital wallet workflows, driver earnings, cashout actions, and operational telemetry.
- **Tertiary Amber (`#F59E0B`)**: Designates drop-off destinations, incoming countdown timers, surge pricing indicators, and intermediate warnings.
- **Destructive / Urgent Crimson (`#EF4444`)**: Emergency SOS, critical cancellations, safety dispatches, and hazard flags.
- **Neutrals**: `#F8FAFC` (High-contrast Primary Text), `#94A3B8` (Secondary / Supporting Metadata), `#334155` (Subtle Dividers & Ghost Outlines).

## Typography

The typography system relies exclusively on `Inter` with tabular numeral support (`tnum`) enabled globally for financial metrics, trip meters, and countdowns. 

- **Financial & Metrics Display**: Currencies (e.g., `195.080 ₫`, `$42.50`) use `display-currency` with tight tracking and extra-bold weighting, ensuring legible readouts when the driver is at arm's length from a mounted device.
- **Operational Street Typography**: Street addresses and turning directives use `headline-lg` and `headline-md` at 600–700 weights to maintain instant legibility without requiring full reading comprehension.
- **Pill Badges & Metrics**: Upper-case styling with letter spacing applied through `label-sm` to maintain visual crispness against dark translucent backgrounds.

## Layout & Spacing

The layout is built for real-time mobile map overlays and modular sliding bottom sheets. The spatial grid operates strictly on a 4px/8px incremental scale, providing clear tap clearance and visual separation between real-time telemetry and navigation overlays.

### Screen Partitioning & Layout Flow
- **Base Map Viewport**: Occupies 100% of the canvas height and width with fluid anchor points for floating action buttons (re-center, heat map toggle, SOS).
- **Persistent Bottom Sheets**: Float over the map with fixed horizontal margins (`12px` to `16px`) and variable vertical heights based on driver workflow states (Idle, Incoming Request, En Route to Pickup, On Trip).
- **Touch Targets**: All interactive elements (accept ride, call passenger, toggle online) enforce a minimum tap target of `52px` vertically and full-width container spans horizontally on mobile viewports.

## Elevation & Depth

Visual hierarchy is established using layered glassmorphism, subtle high-chroma ambient glows, and low-contrast borders.

- **Level 0 (Map / Ground)**: Base background `#0B111E`.
- **Level 1 (Docked Panels & Bottom Sheets)**: Surface `#111A2E` with 92% opacity and `backdrop-filter: blur(16px)`. Rim bordered by a 1px solid line (`rgba(255, 255, 255, 0.08)`).
- **Level 2 (Active Cards & Overlay Tiles)**: Surface `#18233C` with 88% opacity, `backdrop-filter: blur(12px)`. Shadow: `0 12px 32px -4px rgba(0, 0, 0, 0.55), 0 4px 12px rgba(0, 0, 0, 0.35)`. Border: `1px solid rgba(255, 255, 255, 0.12)`.
- **Level 3 (Modal Alerts & Incoming Ride Dispatchers)**: Surface `#1E2B48` with active state rim glows. Incoming requests cast a pulsing radial aura tinted with emerald (`rgba(16, 185, 129, 0.2)`) or amber (`rgba(245, 158, 11, 0.2)`).

## Shapes

The design system incorporates geometric curves with rounded-corner standards to optimize ergonomics:

- **Cards & Bottom Sheets**: Corner radii follow `rounded-xl` (24px) on top edges for sliding sheets and `rounded-lg` (16px) on floating interior metric cards.
- **Buttons & Core Action Controls**: Large CTA buttons adhere to `rounded-lg` (16px) for structured authority, while operational status chips and trip pills leverage true 9999px fully rounded caps (`rounded-full`).
- **Input Fields & Icon Containers**: Set to `rounded` (8px to 12px) to match the internal radius rhythm of nested cards.

## Components

### Buttons & Core Touch Triggers
- **Primary Online/Accept Button**: Height of 56px to 64px. Fill in `#10B981` with high-contrast `#042F2E` text, weight 700. Features an embedded countdown timer bar along the bottom border during incoming trip dispatches.
- **Secondary Action Buttons (Navigation, Chat, Safety)**: Surface `#1E2B48` with `#F8FAFC` icons and text. Outlined with `1px solid rgba(255, 255, 255, 0.12)`.
- **Destructive / Decline Button**: High-transparency crimson tint (`rgba(239, 68, 68, 0.15)`) with `#EF4444` label.

### Trip & Service Pill Badges
- **Trip Status Pills**: Full rounded caps (`height: 28px`, `padding: 0 12px`).
  - *Express Delivery*: Purple-cyan gradient border or cyan fill (`rgba(6, 182, 212, 0.15)` with `#06B6D4` text).
  - *Ride-Hailing (Car/Bike)*: Emerald tint (`rgba(16, 185, 129, 0.15)` with `#10B981` text).
  - *Surge / Priority*: Amber badge with high-contrast icon tag (`rgba(245, 158, 11, 0.2)` with `#F59E0B` text).

### Metric & Order Cards
- Background: `#18233C` at 90% opacity over dark map canvas. 
- Pickup and Drop-off routes use a vertical milestone node architecture: a 10px circular Emerald ring for the pickup node connected by a 2px dashed slate spine (`#334155`) to a 10px solid Amber square for the destination node.
- High-visibility tabular currency readouts positioned top-right for instantaneous income auditing.

### Inputs & Toggles
- **Slide-to-Confirm Bar**: Replaces standard tap buttons for irreversible actions (e.g., "Slide to Complete Delivery"). Consists of an inset track in `#111A2E` and an illuminated emerald circular thumb (`#10B981`) with haptic drag indicators.
- **Search & Destination Fields**: Deep container fill (`#1E2B48`), borderless in rest state, transitioning to a 1.5px `#06B6D4` border on active focus.