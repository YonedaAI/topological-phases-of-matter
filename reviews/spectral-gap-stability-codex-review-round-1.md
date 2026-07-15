---
reviewer: codex (OpenAI, gpt-5.x via codex:rescue)
type: formatting
paper: spectral-gap-stability
round: 1
date: 2026-07-14T21:53:06Z
---

# Codex LaTeX formatting review — round 1

1. Lines 23 and 110–124: the legacy `everypage` package produces two compiler warnings. Remove `\usepackage{everypage}` and replace `\AddEverypageHook` with the current LaTeX hook `\AddToHook{shipout/foreground}{...}`.

2. Lines 253, 369, 713, 862, and 992: sentence-ending uppercase abbreviations receive interword rather than intersentence spacing. Use `Part III\@. Any`, `Part II\@. We`, `Part II\@. If`, `LTQO\@. The`, and `Part I\@. The`.

3. Line 294: `i.e. disorder` receives intersentence spacing after the abbreviation. Use `i.e.\ disorder`.

4. Lines 203, 402, 437, 657, 660, 897, and 1244: set-builder colons use inconsistent spacing—either `\ :\ ` or no explicit spacing. Standardize them, for example as `\,:\,`, throughout.

5. Lines 207–213: known overfull `\hbox`, 2.37965 pt too wide; `$\infty$-groupoid` reaches x=542.38 pt beyond the 540 pt text boundary. Start "Everything downstream" as a new paragraph using `\par\noindent` after "uniformly gapped systems."

6. Lines 898–906: known overfull `\hbox`, 2.74005 pt too wide; "condensed-" reaches x=542.73 pt. Insert `\par\noindent` after "throughout." so "Consequently" begins a separately reflowed paragraph.

7. Lines 1167–1171: known overfull `\hbox`, 8.59833 pt too wide; "Quasi-adiabatic" reaches x=548.56 pt. Insert `\par\noindent` after `\label{conj:III3}` so the conjecture body starts below the long theorem heading.

8. Line 1205: known overfull `\hbox`, 12.08678 pt too wide; "chain" reaches x=552.05 pt. Give `\section` an unchanged optional one-line ToC title and add a balanced manual `\\` break in the printed title, such as after "the".

VERDICT: NEEDS_FIX
