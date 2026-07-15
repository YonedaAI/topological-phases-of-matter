# Part II — positivity-cstar-norms

**Title:** Positivity, C*-Norms, and Condensed State Spaces of Quasi-Local Algebras
**Companion key:** `paperPositivity`
**Author:** Matthew Long / The YonedaAI Collaboration
**Category:** math.OA · **DOI slug:** 2026.07.positivity-cstar-norms · **Date:** 2026-07-14

## Abstract

The observable side of a quantum lattice system is a quasi-local C*-algebra; its
states, positivity structure, and K-theory are the data from which topological
invariants are built. We recast this data in condensed mathematics. For a spin
system with finite on-site dimension the quasi-local algebra `A` is a separable
unital AF algebra (UHF in the homogeneous case), and its condensation
`underline(A)(S) = C(S,A)` is a sheaf of C*-algebras on the site of profinite
sets, *light* because `A` is separable. We prove that the weak-* compact convex
state space `S(A)` condenses to a compact Hausdorff condensed set on which the
condensation functor is fully faithful, and that positivity and normalization cut
it out as a closed condensed subobject of the condensed dual ball; the GNS
construction is a functor on pointed C*-algebras, and on a uniformly gapped family
the ground-state section is weak-* continuous by the
Bachmann–Michalakis–Nachtergaele–Sims spectral-flow cocycle, giving a genuine
point of the condensed state space over the gapped locus (the interface with
Parts I and III). The load-bearing bridge is Aoki's solidification theorem: for a
real Banach algebra, solidification of the algebraic K-theory of the condensed
algebra recovers the topological (operator) K-theory, so the operator-K invariants
of free-fermion and disordered topological phases are values of an intrinsically
condensed-mathematical functor — stated with its real-algebra and
connective/periodic hypotheses, and drawn as a corollary without overclaiming
(the invariant is unchanged; its provenance is condensed). For disorder we recall
Bellissard's crossed product `C(Omega) x Z^d` over a profinite hull
`Omega = F^{Z^d}` and show its condensation is functorial in the finite quotients
of `Omega`, so profinite probes match the physical configuration space rather than
repackage it. Five numbered conjectures record what remains open.

## Section outline

1. Introduction (incl. "Relation to companion papers")
2. Condensed mathematics and quasi-local C*-algebras (framework, notation, macros)
3. The condensed quasi-local algebra (sheaf of C*-algebras; separable ⇒ light)
4. Positivity and the condensed state space
5. The GNS construction as a functor; ground-state continuity on gapped families
6. The solidification bridge: operator K-theory as a condensed invariant
7. Disorder, crossed products, and profinite probes
8. Conjectures
9. Discussion and limitations
10. Conclusion

## Planned Theorem / Conjecture labels

Headline (program-labelled, matching `.knowledge-base.md` §3):
- **Theorem II-A** — Condensed state space: `S(A)` compact-Hausdorff condensed,
  `(-)`-condensation fully faithful; positivity + normalization a closed condensed
  subobject of the condensed dual ball. (Banach–Alaoglu + Clausen–Scholze.)
- **Theorem II-B** — Solid K-theory invariant: Aoki's `K_op(A) ≃ Solid(K_alg(underline A))`
  for real Banach `A`, stated with hypotheses; corollary that free-fermion/disorder
  invariants are condensed-mathematical.
- **Theorem II-C** — Crossed-product disorder algebra: `C(Omega) x Z^d` (Bellissard),
  condensation functorial in finite quotients of the profinite hull.

Supporting (auto-numbered):
- Prop. — UHF/AF structure of the quasi-local algebra.
- Prop. — Condensation of a C*-algebra is a sheaf of C*-algebras; separable ⇒ light.
- Prop. — GNS is a functor on pointed C*-algebras.
- Thm. — Ground-state section is weak-* continuous on uniformly gapped families
  (via `bmns-automorphic`); interface with Parts I, III.
- Prop. — `C(Omega) = colim C(Omega_i)` for profinite `Omega = lim Omega_i` (AF).

Conjectures (stable numbering):
- **Conjecture II-1** — positivity + C*-identity cut `Ham` out as a closed condensed
  substack of a formal-interaction stack.
- **Conjecture II-2** — solid invariant = operator-K of the crossed product, naturally in `Omega`.
- **Conjecture II-3** — Real/KKO refinement matching the Kitaev `KO`-degrees.
- **Conjecture II-4** — solid structure on `S(A)` as a classifying object for condensed representations.
- **Conjecture II-5** — condensed enhancement of the split property / DHR superselection structure.

## Key citations
aoki-solidification (load-bearing), clausen-scholze-condensed/-analytic/-analytic-stacks,
bmns-automorphic, bellissard-ncg-qhe, prodan-sb, thiang-ktheory, kellendonk-tilings,
bourne-kellendonk-rennie, kubota-controlled, ogata-classification-review, denittis-states.
