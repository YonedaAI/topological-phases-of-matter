---
reviewer: codex (OpenAI)
type: formatting
paper: lieb-robinson-locality
round: 1
date: 2026-07-14T21:40:40Z
---

- Lines 59, 98: `everypage` is deprecated and emits two warnings. Remove `\usepackage{everypage}` and replace `\AddEverypageHook` with `\AddToHook{shipout/foreground}`.
- Lines 252–253: newline whitespace before `~\cite{paperGap}` creates doubled spacing. Write `Substack}~\cite{paperGap}` without intervening whitespace.
- Lines 610–611, 624, 848, 935, 1193, 1199: inconsistent unbraced `\norm` arguments. Replace `\norm A`/`\norm B` with `\norm{A}`/`\norm{B}`.

The current build log records successful PDF generation with no missing packages, undefined references, or overfull/underfull boxes.

VERDICT: NEEDS_FIX
