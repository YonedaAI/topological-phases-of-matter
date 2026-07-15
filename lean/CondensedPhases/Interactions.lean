import Mathlib
import CondensedPhases.Basic

/-!
# CondensedPhases.Interactions — F-functions, interactions, and the locality seminorm

The interaction Banach-space apparatus of Paper I (`lieb-robinson-locality`): an
`F`-function decay profile, interactions as strength assignments on finite regions, the
`F`-seminorm axiomatized as a normed-space-style structure, uniform `F`-bounds for
families, and a Lieb-Robinson witness.
-/

namespace CondensedPhases

open scoped ENNReal

/-- An `F`-function: a positive interaction-decay profile with a finite convolution constant. -/
structure FFunction where
  toFun : ℝ → ℝ
  pos : ∀ r, 0 < toFun r
  Cconv : ℝ
  Cconv_nonneg : 0 ≤ Cconv

/-- An interaction assigns to each finite region the strength of a local term. -/
abbrev Interaction (L : SiteSpace) : Type := Region L → ℝ

/-- An `F`-seminorm on interactions, valued in `ℝ≥0∞`. -/
structure FSeminorm (L : SiteSpace) (F : FFunction) where
  toFun : Interaction L → ℝ≥0∞
  map_zero : toFun 0 = 0
  add_le : ∀ Φ Ψ : Interaction L, toFun (Φ + Ψ) ≤ toFun Φ + toFun Ψ
  smul_le : ∀ (r : ℝ) (Φ : Interaction L), toFun (r • Φ) ≤ ENNReal.ofReal |r| * toFun Φ

/-- Observable-side data attached to a system by Paper II: a formal unital C*-algebra interface. -/
structure CStarSystem (L : SiteSpace) where
  Obs : Type
  sq : Obs → Obs
  unit : Obs
  cnorm : Obs → ℝ
  cnorm_nonneg : ∀ a, 0 ≤ cnorm a

/-- A family of interactions is uniformly `F`-bounded when one finite bound controls all members. -/
def UniformlyFBounded {L : SiteSpace} {F : FFunction} (N : FSeminorm L F)
    {S : Type} (fam : S → Interaction L) : Prop :=
  ∃ C : ℝ≥0∞, C ≠ ⊤ ∧ ∀ s, N.toFun (fam s) ≤ C

/-- Uniform `F`-boundedness is closed under pointwise sums. -/
theorem UniformlyFBounded.add {L : SiteSpace} {F : FFunction} {N : FSeminorm L F}
    {S : Type} {f g : S → Interaction L}
    (hf : UniformlyFBounded N f) (hg : UniformlyFBounded N g) :
    UniformlyFBounded N (fun s => f s + g s) := by
  obtain ⟨C, hC, hfC⟩ := hf
  obtain ⟨D, hD, hgD⟩ := hg
  refine ⟨C + D, ENNReal.add_ne_top.mpr ⟨hC, hD⟩, fun s => ?_⟩
  exact le_trans (N.add_le _ _) (add_le_add (hfC s) (hgD s))

/-- A Lieb-Robinson witness: group velocity and prefactor for quasi-local dynamics. -/
structure LRWitness where
  velocity : ℝ
  prefactor : ℝ≥0∞
  velocity_pos : 0 < velocity
  prefactor_ne_top : prefactor ≠ ⊤

/-- `lr` uniformly controls a family when every member's `F`-seminorm is within the prefactor. -/
def LRWitness.Controls {L : SiteSpace} {F : FFunction} (lr : LRWitness)
    (N : FSeminorm L F) {S : Type} (fam : S → Interaction L) : Prop :=
  ∀ s, N.toFun (fam s) ≤ lr.prefactor

end CondensedPhases
