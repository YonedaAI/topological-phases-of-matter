# CondensedPhases — Lean 4 formalization

A Lean 4 library formalizing the framework of the *topological-phases-of-matter in a
condensed-mathematics paradigm* research program, with the program's **five central
problems** stated as honest, Prop-valued propositions and the framework's **core algebraic
lemmas proven** (zero `sorry`, zero `axiom`).

This library represents the modular tower of the program

```
local interactions  ⟶  condensed moduli stack of Hamiltonians  ⟶  uniformly gapped substack
                    ⟶  stabilized phase ∞-groupoid  ⟶  invertible condensed phase spectrum
```

at the level a proof assistant can carry rigorously today: the metric/locality geometry, the
interaction locality (`F`-)seminorm, the spectral-gap predicate and its *uniform* version over
a probe, the stacking commutative monoid on phases, and the Grothendieck group completion with
its universal property and functoriality. The physics-analytic content (actual Hilbert spaces,
Lieb–Robinson dynamics, spectra of operators) is deliberately abstracted: those are the
program's open analytic inputs, and they appear here as the *statements* (Papers I–V), not as
claimed theorems.

## Toolchain and dependencies

- **Lean** `4.32.0` (via `elan`; see `lean-toolchain`).
- **Mathlib** `v4.32.0` (pinned in `lakefile.toml`, exact match to the toolchain).

## Build

```sh
# elan provides the pinned Lean/Lake toolchain automatically from lean-toolchain
export PATH="$HOME/.elan/bin:$PATH"

cd lean
lake exe cache get     # download prebuilt Mathlib oleans (large; do once)
lake build             # builds CondensedPhases and all modules
```

`lake update` (run once during setup) resolves the Mathlib dependency and, via Mathlib's
post-update hook, already fetches the olean cache; `lake exe cache get` is the explicit form.

## Module map

| Module | Contents |
|---|---|
| `CondensedPhases/Basic.lean` | `SiteSpace` (a coarse metric space of lattice sites), `Region` (finite regions), `Region.WithinRadius` (locality radius), `Probe`/`ProfiniteProbe` (parameter and profinite disorder probes), `FactorsThroughFiniteQuotient` (detection by finite quotients). |
| `CondensedPhases/Interactions.lean` | `FFunction` (interaction-decay profile), `Interaction` (strength assignment on regions; a real vector space), `FSeminorm` (the locality `𝓑_F`-seminorm, normed-space-style), `UniformlyFBounded` families, `LRWitness` (Lieb–Robinson data), `CStarSystem` (observable-side interface for Paper II). |
| `CondensedPhases/Gap.lean` | `System` (on-site dims, interaction, gap in `ℝ≥0∞`), `System.Gapped`, `Family`, `UniformGapAtLeast`/`UniformlyGapped` (the `inf_s gap ≥ Δ` substack), `GappedSubstack`, `Stratum`, `PerturbationBounded`. |
| `CondensedPhases/Stacking.lean` | `triv` (gap `⊤`), `stack` (gap `= min`), gap lemmas including the *trivial-never-lowers-gap* guard, family-level `lem:gapstack`, `InvertibleUpTo`. |
| `CondensedPhases/PhaseMonoid.lean` | `PhaseEquiv` (axiomatized `𝓦`), `Phases` quotient + `CommMonoid` instance, units `(Phases W)ˣ` as the invertible sector, and the full `GrothendieckGroup` construction (`CommGroup`, unit `γ`, universal property, functoriality). |
| `CondensedPhases/FiveProblems.lean` | The five central problems `P1…P5` as Prop-valued `def`s, each doc-comment citing its source paper. |
| `CondensedPhases.lean` | Root: imports all six modules. |

## Statement inventory

**Legend.** *proven* = a lemma/instance/definition with a complete proof (no `sorry`);
*stated* = a Prop-valued definition naming a program statement (not proved — these are the
open analytic inputs / conjectures of the program).

### The five central problems (`FiveProblems.lean`, all *stated* as `def … : Prop`)

| Name | Paper | Renders |
|---|---|---|
| `ProblemLocality` | I — `lieb-robinson-locality` | Lieb–Robinson uniformity + finite-quotient descent for uniformly `F`-bounded families (Thm I-B / Conj I-3). |
| `ProblemPositivity` | II — `positivity-cstar-norms` | State locus is closed (Thm II-A) and the C*-identity `‖a*a‖=‖a‖²` holds (Conj II-1). |
| `ProblemGap` | III — `spectral-gap-stability` | Uniform-gap stability under a quasi-local perturbation threshold on the FF/LTQO stratum (Thm III-B; respects CPW undecidability). |
| `ProblemLatticeEFT` | IV — `lattice-eft-equivalence` | Group completion of the phase monoid `≅` the EFT classification group (Conj IV-2). |
| `ProblemRealizability` | V — `bordism-realizability` | Realization map lands in and surjects onto the realizable subgroup (Conj V-1; bounded by Kapustin–Fidkowski). |

### Core lemmas and constructions (proven)

| Name | Module | Paper | Status |
|---|---|---|---|
| `UniformlyFBounded.add` | Interactions | I | proven |
| `UniformGapAtLeast.mono` | Gap | III | proven |
| `uniformlyGapped_const` | Gap | III | proven |
| `stack_gap`, `triv_gap` | Stacking | IV | proven |
| `gapped_triv` | Stacking | IV | proven |
| `stack_gap_triv_left` / `_right` | Stacking | IV | proven |
| `UniformGapAtLeast.stack` | Stacking | IV (`lem:gapstack`) | proven |
| `UniformlyGapped.stack` | Stacking | IV (`lem:gapstack`) | proven |
| `UniformGapAtLeast.stack_triv` | Stacking | IV | proven (the trivial-never-lowers-gap guard) |
| `instCommMonoidPhases` | PhaseMonoid | IV (`prop:monoid`) | proven |
| `(Phases W)ˣ : CommGroup` | PhaseMonoid | IV (`prop:sre`) | proven (inferred) |
| `grothRel_refl/symm/trans` | PhaseMonoid | IV (`def:groth`) | proven |
| `instCommGroupGrothendieckGroup` | PhaseMonoid | IV (`thm:groth` i) | proven |
| `groth_gamma` | PhaseMonoid | IV (`thm:groth` ii) | proven |
| `groth_lift`, `groth_lift_comp_gamma`, `groth_lift_unique` | PhaseMonoid | IV (`thm:groth` iii) | proven |
| `groth_map`, `groth_map_id`, `groth_map_comp` | PhaseMonoid | IV (functoriality) | proven |

## Design notes

- **Gap values live in `ℝ≥0∞`** so that the trivial system can carry gap `⊤ = +∞`. This makes
  `stack`'s gap `min H.gap K.gap` behave correctly: `min ⊤ g = g`, so stacking with the
  trivial system provably never lowers a family's uniform gap (`UniformGapAtLeast.stack_triv`).
  A prior paper review caught exactly the bug this convention prevents.
- **The phase equivalence `𝓦` is axiomatized** as a bundled `PhaseEquiv` structure (an
  equivalence relation that is a stacking congruence and makes stacking associative/commutative/
  unital). The commutative monoid on the quotient `Phases W` is then *derived* — these are
  hypotheses (structure fields), not global `axiom`s, exactly as Mathlib bundles algebraic laws.
- **The Grothendieck completion is constructed by hand** as `(M × M)/∼` with
  `(a,b) ∼ (c,d) ↔ ∃ e, a·d·e = c·b·e`, matching Paper IV `def:groth` verbatim (multiplicative
  form), rather than via a Mathlib black box, so the universal property is proven explicitly.

## Gates

- `lake build` completes with no errors.
- `grep -rn "sorry" CondensedPhases/ --include='*.lean'` → nothing.
- `grep -rnE "^\s*axiom" CondensedPhases/ --include='*.lean'` → nothing.
- Every `FiveProblems` definition is Prop-valued with a doc-comment naming its source paper.
