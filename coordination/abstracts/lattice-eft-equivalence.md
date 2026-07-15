# Part IV — lattice-eft-equivalence

**Title:** From Lattice Models to Effective Field Theories: Stabilization and the Invertible Condensed Phase Spectrum

**Companion key (how peers cite me):** `paperEFT`

**Author:** Matthew Long; The YonedaAI Collaboration, YonedaAI Research Collective; Chicago, IL.

## Abstract

We study the fourth analytic input to the condensed-mathematics program for
topological phases: the relationship between microscopic lattice systems and
their effective field theories. Over the stabilized phase ∞-groupoid
`Phase_{d,G}` of Part III we make the stacking operation `⊠` explicit as a
symmetric-monoidal structure and record what follows formally. On components,
stacking makes the set of phases a commutative monoid; the trivial product state
is its unit and short-range-entangled phases are exactly its invertible elements.
Group completion of this monoid is governed by a universal property that we
prove, and its explicit presentation exposes a *stabilization element* whose
physical content is the addition of trivial ancillas. Restricting to the
invertible sector and applying the recognition principle for grouplike
E∞-spaces yields a connective spectrum, the invertible condensed phase spectrum
`IP^cond_{d,G}`; Kubota's operator-algebraic Ω-spectrum is a rigorous carrier for
its homotopy groups, and Aoki's solidification bridge supplies the analytic
completion a condensed refinement requires. Against this we set the
effective-field-theory (bordism/Anderson-dual) classification of Freed–Hopkins.
The organizing claim of the program — that the microscopic and field-theoretic
classifications agree — is stated as a comparison conjecture at three
increasingly strong levels (π₀ of phase sets; spectra; families over condensed
probes). We do not prove it; we assemble the evidence that constrains it: in
d=1 Ogata's index is complete and the π₀ comparison is a theorem, and for free
fermions the tenfold-way K-theory of Kitaev realizes it, with 8-fold real /
2-fold complex Bott periodicities verified by machine. We frame renormalization
as a filtered/pro-completion and conjecture the lattice→EFT passage is computed
by solidification, that solidification is compatible with group completion, and
that the relative transition charge is the boundary map of the cofiber sequence
for `IP^cond`. Two limitations bound the paper: the equivalence is proven only
under short-range-entanglement (EFT) hypotheses, and noninvertible order lies
outside the invertible spectrum.

## Section outline

1. Introduction (problem; proved vs conjectured; three levels of equivalence; relation to companion papers)
2. The stabilized phase stack and its stacking product (recollections; canonical macros)
3. Stacking as a symmetric monoidal structure
4. Group completion and the stabilization element
5. The invertible condensed phase spectrum `IP^cond`
6. Renormalization and the effective-field-theory passage
7. The comparison conjecture (lattice ↔ EFT)
8. Evidence: d=1 completeness and free-fermion Bott periodicity
9. Lattice invariants, the SSH example, and transitions
10. Formal verification (Haskell)
11. Discussion and limitations
12. Conclusion

## Planned Theorem / Proposition labels (provable from cited results today)

- Prop. (monoid): `Phases_{d,G}` with `⊠` is a commutative monoid; unit = trivial phase; SRE = invertible elements.
- Thm. (group completion): universal property of the Grothendieck group of a commutative monoid; existence + uniqueness.
- Prop. (construction): explicit presentation of the group completion; the stabilization element `e` and non-cancellativity.
- Thm. (recognition, conditional): a Picard ∞-groupoid / grouplike E∞-space is the infinite loop space of a connective spectrum (as applied here by beaudry-etal, kubota-omega-spectrum).
- Thm. IV-B (target exists): Kubota's Ω-spectrum `IP*` of invertible gapped spin systems.
- Prop. (Bott): 8-fold real / 2-fold complex periodicity of the free-fermion tenfold-way table (Kitaev); dimension-shift functoriality.
- Thm. IV-C (lattice invariant): 2D Hall conductance of an SRE state is locally computable, integer × e²/h, a phase invariant (Kapustin–Sopenko); higher Berry class for families.
- Thm. (d=1 completeness): Ogata's index is complete for on-site finite G in d=1, so the π₀ comparison holds there.

## Planned numbered Conjectures (stable IDs; IV-1..IV-3 inherit KB meanings)

- **Conjecture IV-1** (condensed/solid refinement): `IP^cond_{d,G}` is a connective condensed/solid spectrum whose underlying spectrum is a connective cover of Kubota's `IP*` / the Freed–Hopkins bordism target after realification.
- **Conjecture IV-2** (lattice–EFT comparison equivalence — the paper's organizing conjecture): the comparison map `IP^cond_{d,G} → I_{FH}` to the Freed–Hopkins invertible-TQFT spectrum is an equivalence after appropriate completion; equivalently the microscopic invariant equals the deformation class of the associated invertible TQFT under SRE/EFT hypotheses. Stated at π₀, spectrum, and family levels.
- **Conjecture IV-3** (relative charge = spectral boundary map): the transition charge `∂ν ∈ E^{q+1}(B,U_f)` is the connecting map of the cofiber sequence for `IP^cond`.
- **Conjecture IV-4** (solidification ↔ group completion): solidification commutes with group completion of the invertible monoid, so the analytic and algebraic completions are compatible.
- **Conjecture IV-5** (renormalization functor): coarse-graining is a filtered/pro-system on `Ham_{d,G}` whose colimit/limit computes the EFT, and the lattice→EFT passage is a pro-completion compatible with `⊠`.

## Haskell (`src/lattice-eft-equivalence/`)

- `Monoid.hs`: finitely presented commutative monoids; Grothendieck group completion (algorithmic).
- `TenfoldWay.hs`: the free-fermion periodic table in low d; Bott periodicities (mod-8 real, mod-2 complex).
- `Main.hs`: group completion demos incl. a non-cancellative toy monoid; exits 0.
- `Properties.hs`: QuickCheck — monoid laws, group-completion universal property, table periodicity.

*Status: outline settled 2026-07-14; body drafting begins.*
