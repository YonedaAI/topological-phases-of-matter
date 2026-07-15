import Mathlib
import CondensedPhases.Basic
import CondensedPhases.Interactions
import CondensedPhases.Gap
import CondensedPhases.Stacking
import CondensedPhases.PhaseMonoid

/-!
# CondensedPhases.FiveProblems — the five central problems, stated formally

The program's five analytic inputs, one per paper, as Prop-valued statements. These are
definitions naming the program's theorem or conjecture statements.
-/

namespace CondensedPhases

open scoped ENNReal

/-- **Problem I — Locality / Lieb-Robinson uniformity for families.**
Source: Paper I, `lieb-robinson-locality`. For every profinite probe and uniformly
`F`-bounded family, there is a Lieb-Robinson witness controlling the family uniformly, and
the family is detected by finite quotients. -/
def ProblemLocality {L : SiteSpace} {F : FFunction} (N : FSeminorm L F) : Prop :=
  ∀ (P : ProfiniteProbe) (fam : P.Point → Interaction L),
    UniformlyFBounded N fam →
      (∃ lr : LRWitness, lr.Controls N fam) ∧ FactorsThroughFiniteQuotient P fam

/-- **Problem II — Positivity / C*-norm compatibility of the state functor.**
Source: Paper II, `positivity-cstar-norms`. The state locus is closed in the product
topology, and the C*-identity `‖a*a‖ = ‖a‖²` holds. -/
def ProblemPositivity {L : SiteSpace} (A : CStarSystem L) : Prop :=
  IsClosed {phi : A.Obs → ℝ | (∀ a, 0 ≤ phi (A.sq a)) ∧ phi A.unit = 1}
    ∧ (∀ a, A.cnorm (A.sq a) = (A.cnorm a) ^ 2)

/-- **Problem III — Existence and stability of the uniform thermodynamic gap.**
Source: Paper III, `spectral-gap-stability`. On the frustration-free/LTQO stratum, every
uniformly gapped family admits a quasi-local perturbation threshold within which uniform
gappedness persists. -/
def ProblemGap {L : SiteSpace} {F : FFunction} (N : FSeminorm L F) (str : Stratum L) : Prop :=
  ∀ {S : Type} (f : Family L S), (∀ s, str (f s)) → UniformlyGapped f →
    ∃ ε : ℝ≥0∞, 0 < ε ∧ ∀ (fNew : Family L S),
      (∀ s, str (fNew s)) → PerturbationBounded N ε f fNew → UniformlyGapped fNew

/-- **Problem IV — Lattice ↔ EFT comparison.**
Source: Paper IV, `lattice-eft-equivalence`. The group completion of the phase monoid is
isomorphic, via the microscopic-to-field-theoretic comparison map, to the classification
group `C`. -/
def ProblemLatticeEFT {L : SiteSpace} (W : PhaseEquiv L)
    (C : Type) [CommGroup C] (cmp : GrothendieckGroup (Phases W) →* C) : Prop :=
  Function.Bijective cmp

/-- **Problem V — Realizability.**
Source: Paper V, `bordism-realizability`. The realization map from phases lands in the
physically realizable subgroup and surjects onto it. -/
def ProblemRealizability {L : SiteSpace} (W : PhaseEquiv L)
    (C : Type) [CommGroup C] (realizable : Subgroup C) (realize : Phases W → C) : Prop :=
  (∀ p, realize p ∈ realizable) ∧ (∀ c ∈ realizable, ∃ p, realize p = c)

end CondensedPhases
