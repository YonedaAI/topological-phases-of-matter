# Notation & Cross-Reference Audit — topological-phases-of-matter series

**Auditor:** notation warden · **Date:** 2026-07-14
**Scope:** `papers/latex/{lieb-robinson-locality, positivity-cstar-norms, spectral-gap-stability,
lattice-eft-equivalence, bordism-realizability}.tex` checked against `coordination/notation.md`
and `coordination/abstracts/*.md`. No paper files were edited; this document only.

## Verdict

| Paper (companion key) | Verdict | Blocking findings |
|---|---|---|
| I — lieb-robinson-locality (`paperLocality`) | **FAIL** | B1 |
| II — positivity-cstar-norms (`paperPositivity`) | PASS | — |
| III — spectral-gap-stability (`paperGap`) | **FAIL** | B2 |
| IV — lattice-eft-equivalence (`paperEFT`) | **FAIL** | B4 |
| V — bordism-realizability (`paperRealizability`) | PASS | — |
| `coordination/notation.md` (reference doc itself) | **FAIL** | B3 (root cause of B1/B2) |

**4 blocking findings (B1–B4), 5 advisory findings (A1–A5).** Details and proposed fixes below.

---

## 1. Macro block fidelity — PASS (all 5 papers)

Diffed the `% ==== topological-phases-of-matter : canonical macros ====` … `% ==== end
canonical macros ====` block against `coordination/notation.md` §2, verbatim, in all 5 `.tex`
files. Byte-identical in every paper — all 23 `\newcommand`s present with identical expansions
and comments: `\cond \cg \Cont \Shape \Int \Ffun \BF \Ham \Gap \Phase \Phases \Weq \st \hfix
\quotstack \gapof \gapbound \IPcond \Sig \rc \Kop \Kalg \Solid \dis`. Confirmed zero downstream
`\renewcommand` touching any of these 23 names in any paper, and each canonical `\newcommand` is
defined exactly once per file (no duplicate/competing redefinition later in body or preamble).
Clean across the board — this is the one check with no notes at all.

## 2. Symbol collisions

### 2.1 Disorder alphabet ($\Omega$'s base set) — BLOCKING (Papers I, III) + root cause in notation.md

`notation.md` §1/§2 canonically defines $\Omega=F^{\mathbb{Z}^d}$ ("$F$ = finite
local-configuration set"), reusing the same letter $F$ that the shared `\Ffun` macro uses for
the Nachtergaele–Sims–Young interaction-decay function. `board.md`'s Part II log entry records
that Part II deliberately renamed its disorder alphabet to $Q$ "to avoid clash with Part I's
F-function" — but that decision was never folded back into `notation.md`, which still documents
plain $F$ with no note of the exception. Checked paper-by-paper:

| Paper | Disorder-alphabet letter used | Substantively uses `\Ffun`/F-function elsewhere? | Verdict |
|---|---|---|---|
| I — lieb-robinson-locality | **Both**: bare `\Ffun^{\Z^d}` (line 236), *and* `\Ffun_0^{\Z^d}` — subscripted, with an explicit "not to be confused with the $\Ffun$-function" remark (lines 894, 1066) | Yes — the F-function is the paper's central object | **BLOCKING (B1)** — self-contradictory within one document |
| II — positivity-cstar-norms | $Q^{\mathbb{Z}^d}$ (line 950 def., used throughout §7) | No (`\Ffun` never invoked) | Clean — this is the fix everyone else should match |
| III — spectral-gap-stability | bare literal `F^{\Z^d}` (lines 205, 325, 1164, 1171, 1437), never disambiguated | Yes — `\Ffun` used 30+ times, incl. the FF/LTQO stratum $\mathfrak S(\gamma,\Omega_{\mathrm{LTQO}},\Ffun)$ and the Theorem III-A/B proofs | **BLOCKING (B2)** — undisambiguated same-glyph collision, no remark anywhere |
| IV — lattice-eft-equivalence | bare literal `F^{\mathbb{Z}^d}` / `F^{\Zp^d}` | No (`\Ffun` never invoked) | Advisory (A1) — inconsistent with Part II's choice, but no in-document clash |
| V — bordism-realizability | bare literal `F^{\Zint^d}`, with a parenthetical gloss "($F$ a finite local-configuration set)" | No (`\Ffun` never invoked) | Advisory (A1) — same as IV |

**B1 fix:** in `lieb-robinson-locality.tex:236`, change `$\dis=\Ffun^{\Z^d}$` to
`$\dis=\Ffun_0^{\Z^d}$` — the paper's own later convention (lines 894/1066) already does this
correctly; the intro just needs to match it. (Superseded if B3 below is resolved series-wide.)

**B2 fix:** in `spectral-gap-stability.tex`, subscript every disorder-hull `F` to `F_0` (or
switch to `Q` to match Part II) and add one clarifying remark at first use (~line 205 or 1164),
mirroring Paper I's Corollary-level disambiguation.

**B3 fix (notation.md, root cause):** append a note to `notation.md` §1 recording the Part II
deviation, and pick one of: **(a)** formally bless $Q$ series-wide and patch the disorder-hull
letter in Papers I, III, IV, V to match — this closes B1, B2, and A1 in one pass; or **(b)** keep
$F$ canonical but mandate Paper I's $F_0$-plus-remark disambiguation wherever `\Ffun` is also in
play. Either way, `notation.md`'s own stated policy — "if a paper genuinely needs a new symbol,
add it to this file first (append-only) and note it on board.md" — was only half-followed for
this exact case (noted on board.md, never appended to notation.md), which is what let Papers I
and III walk into the exact collision Part II was created to avoid.

### 2.2 Uniform gap: $\Delta$ vs $\gamma$ — advisory only (Paper III)

All 5 papers use `\gapbound` ($=\Delta$) exclusively and correctly for the profinite-family
uniform gap bound ($\inf_{s\in S}\mathrm{gap}(H_s)\ge\Delta$); no paper redefines or substitutes
it. Paper III additionally uses bare $\gamma$ as (a) the bound variable inside the definition
$\mathrm{gap}(H)=\sup\{\gamma\ge0:\ldots\}$ (standard, harmless), and (b) a *finite-volume*
uniform-gap threshold — "$\mathrm{gap}_{\Lambda,m}(H)\ge\gamma$ for all $\Lambda$, $\gamma$
independent of $\Lambda$"; the FF/LTQO stratum $\mathfrak S(\gamma,\Omega_{\mathrm{LTQO}},\Ffun)$.
Usage (b) is conceptually prior to, and distinct in scope from, $\Delta$'s profinite-family
uniformity (single-Hamiltonian/finite-volume vs. family-over-profinite-$S$), so this is not a
rendering error — but the "uniform ... gap $\ge$" phrasing echoes $\Delta$'s job closely enough
that a fast reader could conflate the two symbols. **Advisory (A2)**: optional one-line remark
in Part III distinguishing "$\gamma$: finite-volume/single-system threshold" from "$\Delta$:
profinite-family bound" at first occurrence (~line 437). No other paper reuses $\gamma$ this way.

### 2.3 Stacking symbol $\boxtimes$ — PASS (all 5 papers)

`\boxtimes` used consistently for the stacking product everywhere it appears (occurrence counts
I:1, II:1, III:1, IV:27, V:3 — frequency tracks each paper's proximity to the stacking topic, as
expected). Every `\otimes` occurrence was checked in context and is an unrelated, legitimate
Hilbert-space/operator/matrix-algebra tensor product (GNS/AF-algebra inductive limits in II,
Hamiltonian-sum embeddings and the group-completion proof in IV) — none substitutes for or
competes with $\boxtimes$. No alternate stacking notation found anywhere. Clean.

### 2.4 Phase label $\nu$ / relative transition charge $\partial\nu$ (`\rc`) — PASS, two footnotes

Usage matches `notation.md`'s own sanctioned dual sense — general phase label
$\nu_f:U_f\to\pi_0\Phase_{d,G}$, and its SSH-winding-number instance (both explicitly licensed by
the same symbol-table row in `notation.md` §1) — in Papers II, III, IV. `\rc` is used only in
Papers IV and V, correctly, exactly where transitions/the comparison map are discussed; no
false-positive collisions with `\rceil` or anything else. Two harmless, self-contained footnotes,
neither a fix item: Paper I uses bare $\nu$ once as a generic polynomial-growth exponent unrelated
to phases (line 295–297); Paper V uses $\nu_{d+1}$ for a group-cohomology SPT cocycle (line 434,
the standard Chen–Gu–Liu–Wen convention), not the phase-label $\nu_f$.

## 3. Conjecture numbering — PASS (all 5 papers)

In-body labels and counts match `coordination/abstracts/*.md` exactly:

- **I:** I-1, I-2, I-3 — `\begin{conjecture}[…, I-N]`, plain shared `theorem` counter.
- **II:** II-1…II-5 — auto-numbered via `\renewcommand{\theconjecture}{II-\arabic{conjecture}}`.
- **III:** III-1, III-2, III-3 — `conjone/conjtwo/conjthree`, unnumbered named envs titled
  "Conjecture III-N".
- **IV:** IV-1…IV-5 — `\begin{conjecture}[\textbf{IV-N}: …]`, unnumbered shared env, manual bold tag.
- **V:** V-1, V-2, V-3 — `\begin{conjecture}[…; V-N]`, plain shared `theorem` counter.

Cross-paper citations were checked for *content* accuracy, not just presence: Paper IV cites
"Conjecture~I-1" twice (lines 724, 934) for the higher-stack-structure hypothesis on
$\Ham_{d,G}$ — matches Paper I's actual Conjecture I-1 ("condensed higher stack"). Paper V cites
"Conjecture~IV-2" (line 919, the lattice–EFT comparison equivalence) and "Conjecture~III-2"
(line 1037, uniform-gap descent) — both match the target papers' actual definitions verbatim in
spirit. **No dangling or mismatched conjecture cross-references found anywhere in the series.**
(The three different LaTeX mechanisms listed above are a maintainability wrinkle, not a numbering
bug — see A3/A5 below.)

## 4. "Relation to companion papers" subsection — PASS (all 5 papers)

All 5 papers carry a dedicated, labelled `\subsection{Relation to companion papers}` in the
introduction, each citing the other four `\paperXXX` sibling keys plus `\paperSynthesis`:

| Paper | Subsection start | paperLocality | paperPositivity | paperGap | paperEFT | paperRealizability | paperSynthesis |
|---|---|---|---|---|---|---|---|
| I | line 244 | (self) | ✓ | ✓ | ✓ | ✓ | ✓ (line 264) |
| II | line 291 | ✓ | (self) | ✓ | ✓ | ✓ | ✓ (line 316) |
| III | line 338 | ✓ | ✓ | (self) | ✓ | ✓ | ✓ (lines 369–372, immediately before the `\section{Mathematical framework}` break at line 374 — confirmed inside the subsection, not orphaned in a later section) |
| IV | line 321 | ✓ | ✓ | ✓ | (self) | ✓ | ✓ (line 342) |
| V | line 250 | ✓ | ✓ | ✓ | ✓ | (self) | ✓ (line 271) |

No missing sibling citations in any paper's companion-papers subsection.

## 5. Theorem naming — 1 blocking (Paper IV), 2 advisory

| Paper | Mechanism | Roman-Letter labels present in rendered text? |
|---|---|---|
| I | Shared `theorem` counter; tag embedded in the title bracket at definition (`[…, I-A]`); later references via `\Cref{thm:x} (labelled I-A)` | Yes, but only via a parenthetical gloss — lighter-weight than II/III/V (Advisory **A4**) |
| II | Dedicated auto-numbered `progthm` env, `\theprogthm = II-\Alph{progthm}` | Yes — auto-numbered, and restated directly in the abstract ("Theorem~II-A/B/C") |
| III | Dedicated unnumbered named envs `thmA/thmB/thmC` titled "Theorem III-A/B/C" | Yes, and restated directly in running prose 30+ times |
| IV | Plain `theorem` env, **no tag at all** | **No — confirmed absent everywhere (BLOCKING, B4)** |
| V | Shared `theorem` counter; tag embedded in the title bracket (`[…; V-A]`) | Yes, and restated directly in running prose |

**B4:** `coordination/abstracts/lattice-eft-equivalence.md` designates "Thm. IV-B" (Kubota's
Ω-spectrum, `\label{thm:kubota}`, line 748) and "Thm. IV-C" (Hall conductance as a phase
invariant, `\label{thm:hall}`, line 1153). An exhaustive search of `lattice-eft-equivalence.tex`
for the literal strings "IV-A", "IV-B", "IV-C" returns **zero matches anywhere in the 1374-line
file** — not in the theorem title brackets, not in surrounding prose, not in the conclusion.
Every other paper in the series carries its Roman-letter headline tags somewhere reader-visible;
Part IV is the sole exception. Nothing in its own text lets a reader (or a future citing paper)
confirm which theorem is "IV-B" vs. "IV-C" beyond inferring it from content — which happens to be
checkable here since only two theorems match the abstract's descriptions, but would not survive
any future edit that reorders or adds theorems.

**B4 fix:** add `, IV-B` and `, IV-C` to the two theorem title brackets at
`\label{thm:kubota}` (line 747–748) and `\label{thm:hall}` (line 1152–1153) respectively. While
there, decide whether `thm:groth` (universal property of group completion, line 559) should
retroactively become "IV-A" — the abstract's own "Planned Theorem" list never assigns IV-A to
anything, so the series' otherwise-uniform A/B/C-starting-at-A convention is currently broken at
its root in the coordination doc, not just in the paper. Recommend assigning IV-A to `thm:groth`
for parity with how every other paper's headline sequence starts at A.

**A4:** Paper I's headline tags are present but not restated in running prose the way II/III/V
do (see table). Cosmetic only, no fix required.

**A5:** Three distinct LaTeX mechanisms (auto-numbered env / named unnumbered envs / manual
bracket tag) implement the nominally-identical "Roman-Letter" headline convention across the 5
papers. None is wrong in isolation, but the inconsistency is what let B4 slip through unnoticed —
a manual-tag-in-bracket approach (I, IV, V) has no safety net if the tag is simply never typed, 
whereas II's auto-numbered `\theprogthm` counter cannot silently omit a label. Consider
standardizing on Part II's mechanism in any future revision pass; not urgent for the current
release.

---

## Consolidated fix list (blocking only)

1. **B1** — `lieb-robinson-locality.tex:236` — bare `\Ffun^{\Z^d}` → `\Ffun_0^{\Z^d}`
   (self-consistency with the paper's own line 894/1066).
2. **B2** — `spectral-gap-stability.tex` (lines 205, 325, 1164, 1171, 1437) — subscript
   disorder-hull `F` to `F_0` (or switch to `Q`) + one disambiguating remark at first use.
3. **B3** — `coordination/notation.md` §1 — append a note resolving the F-vs-Q disorder-alphabet
   deviation (root cause of B1/B2/A1); recommend standardizing on `Q` series-wide.
4. **B4** — `lattice-eft-equivalence.tex:748,1153` (and abstract) — add the missing `IV-B`/`IV-C`
   tags to the Kubota and Hall-conductance theorems; assign `IV-A` to `thm:groth` for parity.

No paper files were modified as part of this audit.
