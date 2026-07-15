---
reviewer: codex (OpenAI, gpt-5.x via codex exec read-only)
type: formatting
paper: spectral-gap-stability
round: 2
date: 2026-07-14T23:07:24Z
---

# Codex LaTeX formatting review — round 2

Remaining issues in [spectral-gap-stability.tex](/Users/mlong/Documents/Development/topological-phases-of-matter/papers/latex/spectral-gap-stability.tex:91):

1. Lines 91–105: theorem-like environments share the `theorem` counter, causing `cleveref` to label definitions, propositions, lemmas, corollaries, and remarks as “Theorem.” For example, lines 462 and 467 render as “Theorem 2.2” and “Theorem 2.3.” Use `aliascnt` counters with appropriate `\crefname` definitions while preserving shared numbering.

2. Lines 95–100 and labels at 646, 888, 1044, 1105, 1139, and 1167: labels inside starred theorem environments resolve to the surrounding subsection rather than “Theorem III-A,” “Conjecture III-1,” etc. Remove the unused labels or replace the starred environments with referenceable, fixed-tag theorem counters.

3. Lines 164, 169, 171, 349, 586, 623, 729, 1348, and 1439: sentence-final uppercase identifiers still suppress intersentence spacing. Insert `\@` immediately before each final period, for example `(Theorem III-A)\@.`, `Part II\@.`, and `(Part I)\@.`.

No compilation warnings, unresolved citations/references, overfull or underfull boxes, or visual layout defects were otherwise found.

VERDICT: NEEDS_FIX
---
## Fixes applied in response (worker-gap)

- Finding 1 (VERIFIED real bug via PDF inspection: \Cref{prop:union} rendered
  'Theorem 2.3', \Cref{lem:weyl} rendered 'Theorem 4.1'): reworked the theorem
  environments with the aliascnt package so proposition/lemma/corollary/definition/
  example/remark each carry their own counter aliased to the Theorem counter for
  shared numbering, plus explicit   now render 'Proposition 2.3', 'Lemma 4.1', 'Definition 2.2', etc.; the only
  remaining 'Theorem N.M' references are the genuine cited theorems (CPW 3.1,
  BHM/MZ/NSY 5.5-5.7, Hastings-Koma 6.1).
- Finding 2 (labels in starred environments): confirmed none of thm:IIIA/IIIB/IIIC
  or conj:III1/2/3 are   e.g. 'Theorem III-A'); the labels are unused and harmless, left in place.
- Finding 3 (sentence-final uppercase spacing): inserted \@ at all nine flagged
  locations (lines 164,169,171,349,586,623,729,1348,1439).
- Re-word to clear one 3pt overfull introduced by the longer cleveref names.

Recompile: pdflatex + bibtex + pdflatex x2 -> 25 pages, 0 overfull, 0 undefined refs/cites.
