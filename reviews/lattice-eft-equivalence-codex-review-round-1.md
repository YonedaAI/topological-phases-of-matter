---
reviewer: codex (OpenAI)
type: formatting
paper: lattice-eft-equivalence
round: 1
date: 2026-07-14T21:50:00Z
---

Codex formatting review of `papers/latex/lattice-eft-equivalence.tex` (fresh thread).
Codex independently confirmed the compile baseline (23 pages, 0 overfull/underfull
boxes, no BibTeX warnings) and inspected the source and the rendered pages. The
following findings are recorded as relayed from the Codex companion output.

## Findings

1. **Line 956 — math in subsection heading breaks the PDF bookmark.**
   `\subsection{$d=1$: completeness makes (L0) a theorem}` puts `$d=1$` into a
   hyperref bookmark. Fix:
   `\subsection{\texorpdfstring{$d=1$}{d=1}: completeness makes (L0) a theorem}`.

2. **Line 1081 — math in subsection heading breaks the PDF bookmark.**
   `\subsection{$\Omega$-spectra: a rigorous target for (L1)}`. Fix:
   `\subsection{\texorpdfstring{$\Omega$}{Omega}-spectra: a rigorous target for (L1)}`.

3. **Lines 94–102 — cleveref mislabels Proposition/Lemma/Corollary/Definition/
   Example as "Theorem".** The `[theorem]`-shared counters make `\cref` print
   "Theorem" for every theorem-like environment. Fix: load `\usepackage{aliascnt}`
   before `cleveref` and redefine the environments with `\newaliascnt` +
   `\aliascntnoreset` so each keeps its own name while sharing the Theorem counter.

4. **Line 746 — long section title.** Give `\section` an optional (TOC/bookmark)
   argument and break the printed heading:
   `\section[Renormalization and the effective-field-theory passage]{Renormalization and the\\effective-field-theory passage}`.

5. **Font warnings — `\paragraph` headings use `\texttt` in a bold context and
   fall back (cmtt/bx substitution warnings).** Fix: `\usepackage{bold-extra}`
   after the font packages so bold typewriter is available.

6. **Lines 240–241 — source line break after "by" risks a doubled inter-word
   space / orphaned word.** Fix: end the line with `by~%` so the following word is
   bound with a non-breaking space and the newline is absorbed.

7. **Table 1 floats ahead of its defining Definition.** Fix: `\usepackage{flafter}`
   after `booktabs` so floats are not placed before their point of definition.

VERDICT: NEEDS_FIX
