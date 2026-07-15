---
reviewer: codex (gpt-5.5)
type: formatting
paper: bordism-realizability
round: 1
date: 2026-07-14T21:55:00Z
---

Checked the current source against the existing `bordism-realizability.log`, `.aux`, `.blg`,
and `papers/latex/references.bib`. No fatal compilation errors, missing cited keys, missing
`\label` targets, or deprecated `everypage` usage found.

Issues:

- Line 399: overfull `\hbox` from the long section heading.
  Fix: use an optional ToC title plus an explicit break, e.g.
  `\section[Positive realizability I: group-cohomology SPT phases]{Positive realizability I:\\ group-cohomology SPT phases}`.

- Line 543: overfull `\hbox` from the long section heading.
  Fix: `\section[Positive realizability II: beyond cohomology]{Positive realizability II:\\ beyond cohomology and topological order}`.

- Line 579: `hyperref` PDF-string warnings from math in the subsection title `$E_8$`.
  Fix: `\subsection{Chiral invertible phases: the \texorpdfstring{$E_8$}{E8} state}`.

- Line 593: `hyperref` PDF-string warnings from math in the subsection title `$\Ztwo$`.
  Fix: `\subsection{Fermionic \texorpdfstring{$\Ztwo$}{Z2}: the Kitaev Majorana chain}`.

- Lines 817-869: table `p{...}` columns produce many underfull `\hbox` warnings.
  Fix: make the columns ragged-right, e.g. define
  `\newcolumntype{L}[1]{>{\raggedright\arraybackslash}p{#1}}` and use `L{...}` columns.

- Lines 897-903: overfull `\hbox` in the opening of Conjecture V-1, caused by the theorem
  heading plus a long inline map.
  Fix: move the map to display math,
  `The image of the comparison map \[ \real\colon\Phases_{d,G}\to\mathcal{C}_{d,G} \] restricted to ...`.

- Lines 728-729: unbraced custom macro argument split across lines: `\quotstack{Y}{\cg G}`.
  Fix: `\quotstack{Y}{\cg{G}}`.

- Lines 522, 528, 529: inconsistent unbraced `\mathcal S`.
  Fix: use `\mathcal{S}` to match the rest of the file.

VERDICT: NEEDS_FIX
