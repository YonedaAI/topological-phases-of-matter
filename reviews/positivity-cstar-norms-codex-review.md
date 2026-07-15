---
reviewer: codex (OpenAI)
type: formatting
paper: positivity-cstar-norms
rounds: 3
final_round: 3
date: 2026-07-14
---

# Codex LaTeX formatting review — canonical record

Three rounds of external Codex formatting review (`codex exec --sandbox read-only`,
source never modified by the reviewer; verified by md5 before/after each round).

## Round 1 — VERDICT: NEEDS_FIX (7 issues, all fixed)
1. `cleveref` mislabelled non-theorem environments as "Theorem" because
   proposition/lemma/corollary/definition/example/remark shared the `theorem`
   counter. Fixed by switching to `thmtools` `\declaretheorem[...,sibling=theorem]`,
   which keeps shared numbering while registering the correct cleveref name.
2. Overfull `\hbox` (8.66 pt) at the "spectral-flow (quasi-adiabatic)" line —
   reworded to "quasi-adiabatic spectral-flow".
3. Abstract's last two lines stranded on page 2 — `\enlargethispage{2\baselineskip}`
   after `\maketitle` pulls them onto page 1.
4. Three-key citation split across pages — wrapped in `\mbox{\cite{...}}`.
5. Conjecture II-3 split across pages — `\Needspace{9\baselineskip}` before it.
6. Ordinary spaces before `\cite` — normalized to non-breaking `~\cite`.
7. Inconsistent sentence/abbreviation spacing — added `\frenchspacing`.

## Round 2 — VERDICT: NEEDS_FIX (2 issues, all fixed)
1. Duplicate hyperref destinations (`proposition.2`, `definition.1`, `remark.4`, ...)
   because the section-reset shared counter produced anchors omitting the section
   number, so links could mis-target. Fixed by redefining each `\theH<name>` to
   `\thesection.\arabic{theorem}` so every anchor is globally unique.
2. Two remaining breakable spaces before citations (`of \cite{...}`,
   `theorem {\cite{...}}`) — changed to `~\cite` / `~{\cite`.

## Round 3 — VERDICT: PASS

No issues remain in the requested checks. The 20-page build is clean: no box,
destination, reference, citation, or citation-spacing warnings.

VERDICT: PASS
