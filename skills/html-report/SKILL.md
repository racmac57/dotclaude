---
name: html-report
description: Generate a self-contained, HPD-branded HTML report with inline styles, print rules, and sensitivity markings from data or analysis provided by the user.
---

# HTML Report Generation — HPD Branded

## When to Use

When generating any HTML report for Hackensack PD output — monthly reports,
Clery reports, analysis summaries, or ad-hoc styled documents.

## Canonical Style Source

On this OneDrive workspace, use the design system and CSS from:

`08_Templates/Report_Styles/html/HPD_Report_Style_Prompt.md`

(Resolved from OneDrive root: `C:\Users\carucci_r\OneDrive - City of Hackensack\`.)

A parallel copy may exist under `06_Workspace_Management/docs/templates/`; prefer the `08_Templates` path unless the project `CLAUDE.md` states otherwise.

## Design Rules

- Self-contained HTML: **no** external stylesheets, fonts, or scripts unless the user explicitly allows CDN use for a one-off.
- Palette (typical HPD): Navy `#1a2744`, Gold `#c8a84b`, success `#2e7d32`, error `#b71c1c` - follow the prompt file for full tokens.
- Include author block, status (Draft / For Review / Final), FOUO or sensitivity language when appropriate, and `@media print` rules per the style prompt.
- Use semantic headings and tables; keep layout readable when printed.
- **No em-dashes or en-dashes** anywhere in the output - not in `<title>`, headings, body text, or the footer. Do not use `&mdash;`, `&ndash;`, the Unicode characters `—` or `–`, or any dash entity wider than a hyphen. Use a plain hyphen-minus ` - ` (space-hyphen-space) for separators and `-` for ranges.

## Output

Deliver a single `.html` file (or the snippet the user asked for) with inline `<style>` as specified in the style prompt.
