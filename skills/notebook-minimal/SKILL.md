---
name: notebook-minimal
description: Replicates NotebookLM core capabilities (persistent memory, RAG, visual artifacts) via CLI. Use when user wants local knowledge base, query answering, or presentation slides.
allowed-tools: Read, Grep, Glob, Write, Edit, Bash
---

# Notebook Minimal Skill

CLI-based persistent memory, RAG, and artifact generation. Token-efficient, Technical Brutalist-Minimalist aesthetic.

## Core Principles

- **Query/Add Information:** ALWAYS execute `scripts/query_engine.py`. NEVER read the database file directly. Script handles encoding and context management.
- **Design References:** Load `references/css_rules.md` and `references/mermaid_rules.md` ONLY on-demand for artifact generation.
- **Token Efficiency:** Write compact JSON payloads, parse script output, retain only final results in context.

## Architecture

```
notebook-minimal/
├── SKILL.md              # This file
├── scripts/
│   └── query_engine.py   # CLI query/add engine (args: --action, --payload)
├── assets/
│   ├── presentation.html   # Reveal.js slides template
│   └── chart.html          # KPIs/progress template
└── references/
    ├── css_rules.md       # Visual aesthetic guidelines
    └── mermaid_rules.md  # Diagram syntax rules
```

## Commands

### Add Knowledge
```bash
python scripts/query_engine.py --action add --payload '{"text": "your content", "tags": ["topic"]}'
```

### Query Knowledge
```bash
python scripts/query_engine.py --action query --payload '{"query": "your question"}'
```

### Generate Slides
Inject markdown content between `<!-- {{SLIDES_CONTENT}} -->` markers in `assets/presentation.html`.

### Generate Charts
Use native HTML5 (`<progress>`, `<meter>`, div-width) as specified in `references/css_rules.md`. NO Chart.js or complex SVGs.

## Visual Aesthetic (Technical Brutalist-Minimalist)

- Background: #FBFBFB (off-white)
- Text: #111111 (near-black)
- Secondary: #666666 (muted gray)
- Accent: #F0F0F0 (light gray)
- Borders: 1px solid #111111 or #EEEEEE
- Font: System monospace only (ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas)
- NO border-radius, NO box-shadow, NO gradients
- Flat, sharp, asymmetrical, whitespace-heavy layout

## Workflow

1. User requests info → Execute query_engine.py with --action query
2. User provides new info → Execute query_engine.py with --action add
3. User wants slides → Edit presentation.html, inject markdown
4. User wants charts → Build with HTML5 native elements per css_rules.md
5. User wants diagrams → Use Mermaid per mermaid_rules.md

## Limits

- SKILL.md under 500 lines (this file)
- Keep payloads under 2KB JSON
- Mermaid nodes: max 3 words each
- Slides: left-aligned, no decorative transitions