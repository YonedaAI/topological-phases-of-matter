---
reviewer: codex (OpenAI, gpt-5.5 via codex exec read-only, xhigh)
type: formatting
paper: synthesis
round: 1
date: 2026-07-14T18:05:00Z
---

# Codex LaTeX formatting review — round 1

Codex independently rebuilt `papers/latex/synthesis.tex` (pdflatex + bibtex + pdflatex x2).
`synthesis.log` is in sync with the source: no compile errors, missing packages,
unresolved refs/cites, duplicate labels, overfull boxes, or BibTeX warnings. The one
math-containing subsection title already uses `\texorpdfstring`, and the aliascnt/cleveref
theorem naming is correct. Findings (formatting only):

## Findings

1. **Lines 1140–1181 — starred conjecture environments break cross-references.** The four
   `conjVI*` environments are `\newtheorem*` (unnumbered), so their `\label`s bind to
   `section.9` in the `.aux`; any `\Cref{conj:VI1}` would print "Section 9". Fix: make them
   a numbered theorem-like `conjecture` environment with
   `\renewcommand{\theconjecture}{VI-\arabic{conjecture}}` plus `\crefname`/`\Crefname`, and
   replace the four starred environments.

2. **Line 651 — manual `\ref` inconsistent with the cleveref/aliascnt setup.**
   `Recollections~\ref{rec:III} and \ref{rec:IIIc}` should be `\Cref{rec:III,rec:IIIc}`.

3. **Lines 1202, 1225, 1226, 1228, 1232, 1238, 1241 — longtable underfull hboxes (badness up
   to 10000).** The justified `p{6.9cm}` statement column is too narrow for these entries.
   Fix: use a ragged paragraph column, e.g. `>{\raggedright\arraybackslash}p{7.1cm}`.

4. **Lines 1223, 1229, 1233, 1239 — "Infinite glue shrinkage found in box being split."**
   Caused by `\addlinespace` landing at a longtable page split. Fix: remove those
   `\addlinespace` separators (or replace with a fixed `\noalign{\vskip}` that cannot become
   stretch glue at a page break).

5. **Lines 658 and 1255 — long headings wrap awkwardly (line 1255 leaves a lone final
   "not").** Fix by shortening the displayed headings and/or adding short optional
   ToC/bookmark titles, e.g. `\subsection[Arrow IV: stabilization and the phase spectrum]{...}`
   and a shorter section-10 title.

VERDICT: NEEDS_FIX
