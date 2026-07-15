# Part III — spectral-gap-stability

**Title:** The Uniformly Gapped Substack: Existence and Stability of the Thermodynamic Spectral Gap

**Companion key:** `paperGap` · **Author:** Matthew Long / The YonedaAI Collaboration · **Date:** 2026-07-14

## Abstract

Fix a spatial dimension, a lattice, local Hilbert spaces, a locality class, and a
symmetry group `G`. The condensed moduli stack of `G`-symmetric quasi-local
Hamiltonians `Ham_{d,G}` carries a distinguished substack `Gap_{d,G}`, the
*uniformly* gapped systems: over a profinite probe `S`, a family belongs to
`Gap_{d,G}(S)` when `inf_{s in S} gap(H_s) >= Delta` for some `Delta > 0`. We take
the word *uniformly* seriously — a family whose pointwise gaps degenerate to zero
is excluded — and study the resulting substack as the object on which the whole
phase functor rests. The organizing constraint is a hard theorem: by
Cubitt–Pérez-García–Wolf the spectral gap is undecidable, so there is no algorithm
and no uniform criterion that decides membership in `Gap_{d,G}` for general
translation-invariant families. We therefore do not attempt to *decide* the gap.
Existence of a thermodynamic gap is treated as a hypothesis that *defines* the
substack, and the mathematical content of the paper is **stability and structure**,
not decidability. On the provable side we establish three results with complete
proofs from cited present-day technology: (III-A) at fixed finite volume the
`n`-gap is `2`-Lipschitz in the interaction norm, so the gapped locus is open at
every finite resolution and the gap is jointly continuous along continuous
families; (III-B) on the frustration-free / LTQO stratum the
Bravyi–Hastings–Michalakis and Michalakis–Zwolak stability theorems, together with
the Nachtergaele–Sims–Young infinite-volume bulk-gap result, supply a
volume-independent perturbation threshold, which we recast as: `Gap_{d,G}` contains
a condensed-open neighborhood of each stratum point along quasi-local perturbation
directions; (III-C) a uniform gap forces uniform exponential clustering, with a
correlation length bounded uniformly over the profinite base. Beyond the stratum we
record what we cannot prove as three numbered conjectures: openness of `Gap_{d,G}`
in the full condensed topology on the physically relevant stratum with the
uniform-gap sheaf condition detected by finite quotients (III-1); descent of uniform
gappedness along profinite covers, i.e. disorder hulls `Omega = F^{Z^d}` (III-2); and
the identification of quasi-adiabatic continuation with the internal path components
realizing the equivalence class `W`, so that `pi_0 Shape(Gap[W^{-1}])` equals the
operator-algebraic set of gapped ground-state phases (III-3). A transverse-field
Ising computation renders the gapless discriminant `Sigma = {g = 1}` as a numerical
picture and exhibits gap persistence — and the Lipschitz bound of III-A — away from
criticality.

## Section outline

1. Introduction (gapped substack; the undecidability wall; contributions; relation to companion papers)
2. Mathematical framework (condensed probes and `Ham_{d,G}`; finite-volume and thermodynamic gap; the uniformly gapped substack; the condensed topology and "open substack")
3. The undecidability wall and the definitional stance (CPW; no uniform criterion; the substack is defined by the gap hypothesis; the decidable/undecidable boundary)
4. Finite-volume gap continuity — Theorem III-A (Weyl/Lipschitz; `n`-gap; openness at finite resolution; semicontinuity)
5. Stability on the frustration-free / LTQO stratum — Theorem III-B (precise hypotheses; BHM/MZ/NSY; recast as condensed-openness; spectral-flow consequences)
6. Uniform clustering from a uniform gap — Theorem III-C (Hastings–Koma; uniformity over the base; structural corollaries)
7. Structure of the gapped substack — Conjectures III-1, III-2, III-3
8. Numerical illustration: the transverse-field Ising chain (exact diagonalization; the discriminant `Sigma`; perturbative stability; what finite volume cannot decide)
9. Discussion (what the paradigm contributes; the two walls; the profinite-disorder thread)
10. Conclusion

## Planned Theorem / Conjecture labels

- **Definition** 2.x: uniformly gapped substack `Gap_{d,G}`; FF/LTQO stratum; condensed openness.
- **Theorem III-A** (finite-volume `n`-gap is Lipschitz; gapped locus open at finite resolution). Complete elementary proof (Weyl inequalities + finite-volume norm equivalence).
- **Proposition** (union-over-`Delta` structure; lower semicontinuity of the thermodynamic gap along GNS limits).
- **Theorem III-B** (stability ⇒ conditional condensed-openness on the FF/LTQO stratum). Proof by reduction to `bhm-stability`, `bravyi-hastings-shortproof`, `michalakis-zwolak`, `nsy-bulkgap`.
- **Proposition** (spectral flow / automorphic equivalence inside a uniformly gapped neighborhood; interface with Part I via `bmns-automorphic`, `hastings-wen-qac`, `nsy-quasilocality-2`).
- **Theorem III-C** (uniform gap ⇒ uniform exponential clustering). Proof from `hastings-koma`, `nachtergaele-sims-clustering` + Part I uniformity.
- **Conjecture III-1** (openness on the physical stratum; sheaf condition detected by finite quotients).
- **Conjecture III-2** (uniform-gap descent along profinite covers / disorder hulls).
- **Conjecture III-3** (QAC realizes `W`; `pi_0 Shape(Gap[W^{-1}])` = operator-algebraic gapped phases, `ogata-classification-review`).

## Hard walls respected

- **CPW undecidability** (`cpw-undecidable`): no claim of a general algorithm, decision procedure, or uniform criterion for the gap. Gap-existence is an assumption defining `Gap_{d,G}`. The paper is framed around stability, not decidability. Any openness/descent claim is scoped to the stratum where the stability hypotheses hold with uniform constants.
- Frustration-freeness is a genuine restriction; the FF/LTQO theorems are never silently extended to general gapped systems.
- `inf_{s in S}` is kept explicit throughout; pointwise gaps that degenerate are excluded.
