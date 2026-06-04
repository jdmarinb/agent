# CSS Rules - Technical Brutalist-Minimalist Aesthetic

Mandatory guidelines for all artifact generation. These rules are NOT optional.

## Color Palette (Industrial/Nordic)

| Token | Hex | Usage |
|-------|-----|-------|
| --bg | #FBFBFB | Main background, off-white |
| --text | #111111 | Primary text, near-black |
| --secondary | #666666 | Secondary text, muted gray |
| --accent | #F0F0F0 | Containers, light gray |
| --border | #111111 | Sharp borders, 1px |
| --border-light | #EEEEEE | Subtle borders, 1px |

## Typography

**EXCLUSIVE MONOSPACE ONLY** - No exceptions.

```css
font-family: ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, "Liberation Mono", "Courier New", monospace;
```

- Base size: 16-18px
- Line height: 1.5
- Headings: bold, uppercase optional

## Hard Constraints (Absolute Bans)

- `border-radius: 0` — NEVER use rounded corners
- `box-shadow: none` — NO drop shadows
- `background: linear-gradient(...)` — NO color gradients
- `border-radius: 50%` — NO circles/pills
- `@import` Google Fonts — NO external font loads

## Layout Principles

1. **Flat** — Single layer, no depth effects
2. **Sharp** — Square edges, no curves
3. **Asymmetrical** — Off-center layouts, varied grids
4. **Whitespace** — Generous padding/margin for hierarchy

## Spacing Scale (em/rem based)

- xs: 0.25rem
- sm: 0.5rem
- md: 1rem
- lg: 1.5rem
- xl: 2rem
- xxl: 3rem

## Component Rules

### Cards/Containers
```css
.card {
    background: var(--accent);
    border: 1px solid var(--border);
    padding: 1.5rem;
    /* radius: 0 implied */
}
```

### Buttons
```css
.button {
    background: var(--text);
    color: var(--bg);
    border: 1px solid var(--text);
    padding: 0.75rem 1.5rem;
    /* radius: 0 implied */
}
```

### Progress/Bar Elements
- Use native `<progress>` or `<meter>`
- Or div with inline `width: X%` style
- NO Chart.js, D3, canvas-based libs

### Tables
- 1px solid borders
- Header: var(--accent) background
- Monospace cells

## Valid Elements

**ALLOWED:**
- `<div>`, `<span>`, `<p>`, `<h1-h6>`
- `<table>`, `<thead>`, `<tbody>`, `<tr>`, `<th>`, `<td>`
- `<ul>`, `<ol>`, `<li>`
- `<pre>`, `<code>`
- `<progress>`, `<meter>`
- `<details>`, `<summary>`
- `<hr>`
- Input elements (styled flat)

**FORBIDDEN:**
- `<canvas>` for charts
- SVG for data viz
- Complex CSS animations
- Decorative pseudo-elements (::before/::after for visuals only)

## Mermaid Diagrams

Follow `mermaid_rules.md`. Nodes limited to 3 words max.

## Presentation Slides

Reveal.js CDN loaded. Override theme with:
- font-family: monospace
- radius: 0
- flat transitions
- left-aligned content