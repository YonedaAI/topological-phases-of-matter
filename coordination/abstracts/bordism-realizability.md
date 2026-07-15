# Part V — bordism-realizability

**Title:** Physical Realizability of Bordism and Homotopy Classes by Gapped Lattice Systems
**Companion key:** `paperRealizability`
**Author:** Matthew Long; The YonedaAI Collaboration (YonedaAI Research Collective, Chicago, IL)
**Category:** cond-mat.str-el · **DOI slug:** 2026.07.bordism-realizability · **Date:** 2026-07-14

## Abstract

The invertible condensed phase spectrum $\mathbf{IP}^{\mathrm{cond}}_{d,G}$ of Part IV
assigns to each short-range-entangled phase an abstract class in a bordism- or
homotopy-theoretic classification. Part V asks the converse: which of those classes are
produced by an explicit uniformly gapped lattice Hamiltonian? We formalize realizability
as the essential surjectivity, on $\pi_0$, of the comparison map from the stabilized stack
of lattice models to the abstract spectrum, and we separate two nested notions —
realizability by *some* gapped local Hamiltonian and realizability by a local
*commuting-projector* model. On the positive side we record, in the condensed language,
three rigorous facts: every group-cohomology class in $H^{d+1}(G,U(1))$ is realized by an
explicit $G$-symmetric commuting-projector model with the prescribed edge anomaly
(Chen–Gu–Liu–Wen; Else–Nayak); in dimensions one and two Ogata's operator-algebraic index
is a complete invariant of SPT phases with on-site finite symmetry, so the realized set
coincides with the invariant set there; and the Kapustin–Fidkowski theorem is a hard
obstruction — no local commuting-projector Hamiltonian carries a nonzero Hall conductance,
so every chiral invertible class lies outside the commuting-projector image. We assemble
the constructions (group-cohomology models, Walker–Wang models for beyond-cohomology
classes in 3+1d, the $E_8$ state, the Kitaev Majorana chain, cluster states) and the
obstructions into a dimension-by-symmetry status table separating torsion from free part,
and state three numbered conjectures: the realizability image is exactly the
short-range-entangled subspectrum; chiral classes are realizable by non-commuting gapped
Hamiltonians though never by commuting projectors; and realizability descends over
profinite disorder hulls $\Omega=F^{\mathbb{Z}^d}$ precisely when a condensed-cohomological
obstruction vanishes.

## Section outline

1. Introduction (with §1.4 "Relation to companion papers")
2. The realizability question in the condensed program
3. Positive realizability I: group-cohomology SPT phases
4. Positive realizability II: beyond cohomology and topological order
5. Completeness in low dimension
6. The obstruction: the Kapustin–Fidkowski no-go
7. A status table for realizability
8. The realizability image: conjectures
9. Disorder-robust realizability over profinite hulls
10. Computational verification (Haskell)
11. Discussion
12. Conclusion

## Planned Theorem / Proposition / Conjecture labels

- **Definition 2.x** — comparison/realizability map $\rho$; commuting-projector vs gapped realizability; SRE image.
- **Theorem V-A** (group-cohomology classes are realized) — via `cglw-cohomology`, `else-nayak`.
- **Proposition 3.x** (cluster-state $\mathbb{Z}_2\times\mathbb{Z}_2$ SPT string order = 1) — elementary, stabilizer proof.
- **Proposition V-D** (Kitaev-chain winding/Majorana $\mathbb{Z}_2$ invariant is quantized and jumps at $|\mu|=2t$) — elementary proof; matches Haskell.
- **Theorem V-B** (completeness in $d=1,2$ for on-site finite symmetry) — via `ogata-h3-index`, `ogata-classification-review`.
- **Theorem V-C** (Kapustin–Fidkowski no-go: commuting projectors have zero Hall conductance) — via `kapustin-fidkowski`.
- **Conjecture V-1** (realizability image = SRE subspectrum; obstruction subgroup).
- **Conjecture V-2** (chiral classes realizable by non-commuting gapped, not commuting-projector).
- **Conjecture V-3** (profinite-family realizability / condensed descent obstruction).

## Hard constraints honored

- Kapustin–Fidkowski bounds every realizability claim; CP-realizability of chiral phases is never asserted.
- Ogata completeness stated for on-site finite symmetry in $d=1,2$ ONLY.
- `aasen-wang-hastings` $\pi_1,\pi_2,\pi_3$ cited as conjectural.
- Beyond-cohomology classes (`kapustin-cobordism`) explicitly outside Theorem V-A.

## New bib key added (verified)

- `kitaev-majorana-wire` — Kitaev, "Unpaired Majorana fermions in quantum wires", Phys.-Usp. 44 (2001), arXiv:cond-mat/0010440. Appended to both `references.bib` files with `% verified:` comment.
