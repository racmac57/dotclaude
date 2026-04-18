---
name: html-report
description: Generate a self-contained, HPD-branded HTML report with inline styles, print rules, and sensitivity markings from data or analysis provided by the user.
---

# HTML Report Generation - HPD Branded

## When to Use

When generating any HTML report for Hackensack PD output - monthly reports,
Clery reports, methodology documents, map companions, analysis summaries, or
ad-hoc styled documents.

## Canonical Exemplar

The reference implementation that defines the current house style is bundled
with this skill:

`skills/html-report/reference_example.html`

Treat it as the source of truth for structure, tokens, components, and print
rules. When in doubt, match it.

A project-level copy may also exist at
`08_Templates/Report_Styles/html/HPD_Report_Style_Prompt.md` (resolved from
OneDrive root `C:\Users\carucci_r\OneDrive - City of Hackensack\`). If the
project `CLAUDE.md` specifies a different source, prefer that.

## Required Document Structure

Every report must include, in order:

1. **Leading HTML comments** - timestamp, relative path, author, purpose.
2. **`<!DOCTYPE html>`** with `<html lang="en">`.
3. **`<head>`** - charset, viewport, title, single inline `<style>` block.
4. **`<body>` > `.page`** wrapper (max-width 900px, centered).
5. **`.header`** - `.dept` kicker, `<h1>`, `.subtitle`.
6. **`.meta-bar`** - prepared by, run date/time, horizon, classification
   (wrap "Law Enforcement Sensitive" in `.status-les`).
7. **`.content`** - all report sections.
8. **`.footer`** - classification, analyst, generated date, data horizon,
   distribution restriction.

## Design Tokens

- **Fonts:** `'Segoe UI', Arial, sans-serif`; code `'Cascadia Code','Consolas',monospace`.
- **Base size:** 13.5px body; h1 20px; h2 15px uppercase; h3 13px.
- **Palette:**
  - Navy `#1a2744` (header, h2 text, table th, primary accents)
  - Gold `#c8a84b` (rules, borders, left-accents)
  - Body text `#2c2c3e`; dark body `#1a1a2e`
  - Page background `#f5f5f0`; content background `#fff`
  - Meta/footer bg `#eef0f5`; card bg `#fafbfd`; border `#d0d4de` / `#ccc`
  - Success `#2e7d32`; error `#b71c1c`; info-blue `#1565c0`; warn-orange `#e65100`
  - Panel image scaffold: bg `#0f1320`, border `#3a4260`
- **Score color classes:** `.score-high` (red), `.score-mid` (orange), `.score-low` (blue).
- **Sensitivity flag:** `.status-les` (red, bold) - always used for LES/FOUO marking.

## Component Library

Use these components; do not invent parallel ones:

- `.alert` with optional `.green` / `.red` / `.blue` variant - left-accent
  callout for guardrails, warnings, or info.
- Tables - navy `th`, alternating row shading, `.center` modifier, score-color
  cells for numeric severity.
- `.panels` > `.panel` > `.panel-body` > (`.shot-col` with `.shot-wrap` +
  `.guidance`) + `.notes` - screenshot + operator-notes layout. Use
  `.shot-empty` + `.shot-placeholder` for reserved slots.
- `.two-col` > `.box` - side-by-side reference boxes (methodology, criteria).
- `.stat-row` > `.stat` with `.num` + `.lbl` - headline metric strip.
- `.checklist` - square-bullet list for pre-briefing / validation steps.
- `.signoff-grid` with `label` + `.field` (and `.full` for full-width) - sign-off block.
- `.part-divider` with inner `h2` + `.part-sub` - major section break; forces
  page-break in print.

## Print Rules

Always include `@page { size: letter portrait; margin: 18mm 16mm }` and an
`@media print` block that:

- Removes page background, border, and shadow.
- Reduces footer size and padding.
- Tightens `.panels` gap and `.shot-wrap` min-height.
- Adds `page-break-inside:avoid` / `break-inside:avoid` to `.panel`, `.alert`,
  `table`, `.box`, `.stat-row`.
- Adds `page-break-after:avoid` to `h2` and `h3`.
- Forces `page-break-before:always` on `.part-divider`.

## Content Rules

- **Self-contained:** no external stylesheets, fonts, scripts, or CDN links
  unless the user explicitly permits a one-off exception.
- **Images:** reference via `file:///` paths on the OneDrive workspace when
  embedding screenshots; never hotlink external URLs.
- **Author block:** always name R. A. Carucci #261 unless the user specifies
  otherwise.
- **Status / sensitivity:** include Draft / For Review / Final where relevant,
  and mark LES/FOUO when the data is operational.
- **Semantic headings and tables;** keep layout readable when printed.
- **No em-dashes or en-dashes** anywhere - not in `<title>`, headings, body
  text, or the footer. Do not use `&mdash;`, `&ndash;`, the Unicode characters
  `—` or `–`, or any dash entity wider than a hyphen. Use a plain
  hyphen-minus ` - ` (space-hyphen-space) for separators and `-` for ranges.

## Output

Deliver a single `.html` file (or the snippet the user asked for) with inline
`<style>` matching `reference_example.html`. Do not split CSS into external
files. Do not introduce frameworks.
