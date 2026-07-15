import Mathlib
import CondensedPhases.Basic
import CondensedPhases.Interactions

/-!
# CondensedPhases.Gap — systems, the spectral gap, and the uniformly gapped substack

A `System` bundles on-site dimensions, an interaction, and a spectral gap valued in
`ℝ≥0∞` (`⊤ = +∞`). The uniformly gapped substack is the union over `Δ > 0` of
families with `inf_s gap(H_s) ≥ Δ` (Paper III, `spectral-gap-stability`).
-/

namespace CondensedPhases

open scoped ENNReal

/-- A quantum lattice system on `L`, with spectral gap valued in `ℝ≥0∞`. -/
structure System (L : SiteSpace) where
  onSiteDim : L.Site → ℕ
  interaction : Interaction L
  gap : ℝ≥0∞

/-- A system is gapped when its spectral gap is strictly positive. -/
def System.Gapped {L : SiteSpace} (H : System L) : Prop := 0 < H.gap

/-- A family of systems over a probe `S`. -/
def Family (L : SiteSpace) (S : Type) : Type := S → System L

/-- The family has uniform gap at least `Δ`. -/
def UniformGapAtLeast {L : SiteSpace} {S : Type} (Δ : ℝ≥0∞) (f : Family L S) : Prop :=
  ∀ s, Δ ≤ (f s).gap

/-- The uniformly gapped substack: some positive `Δ` bounds all gaps from below. -/
def UniformlyGapped {L : SiteSpace} {S : Type} (f : Family L S) : Prop :=
  ∃ Δ : ℝ≥0∞, 0 < Δ ∧ UniformGapAtLeast Δ f

/-- The gapped substack as a set of families. -/
def GappedSubstack (L : SiteSpace) (S : Type) : Set (Family L S) :=
  {f | UniformlyGapped f}

/-- The frustration-free / LTQO stratum on which Paper III's stability theorems hold. -/
def Stratum (L : SiteSpace) : Type := System L → Prop

/-- A quasi-local perturbation of size at most `ε` in the `F`-seminorm between two families. -/
def PerturbationBounded {L : SiteSpace} {F : FFunction} (N : FSeminorm L F) (ε : ℝ≥0∞)
    {S : Type} (f fNew : Family L S) : Prop :=
  ∀ s, N.toFun ((fNew s).interaction - (f s).interaction) ≤ ε

/-- Monotonicity in the gap bound. -/
theorem UniformGapAtLeast.mono {L : SiteSpace} {S : Type} {Δ Δ' : ℝ≥0∞} {f : Family L S}
    (h : Δ' ≤ Δ) (hf : UniformGapAtLeast Δ f) : UniformGapAtLeast Δ' f :=
  fun s => le_trans h (hf s)

/-- A constant family is uniformly gapped iff its single system is gapped, assuming the probe is nonempty. -/
theorem uniformlyGapped_const {L : SiteSpace} {S : Type} [Nonempty S] (H : System L) :
    UniformlyGapped (fun _ : S => H) ↔ H.Gapped := by
  constructor
  · rintro ⟨Δ, hΔ, hf⟩
    exact lt_of_lt_of_le hΔ (hf (Classical.arbitrary S))
  · intro h
    exact ⟨H.gap, h, fun _ => le_refl _⟩

end CondensedPhases
