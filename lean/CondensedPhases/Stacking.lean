import Mathlib
import CondensedPhases.Basic
import CondensedPhases.Interactions
import CondensedPhases.Gap

/-!
# CondensedPhases.Stacking — the stacking product `⊠` and the trivial system

Stacking (Paper IV `lattice-eft-equivalence`): tensor the on-site spaces, add the
interactions, and take the gap to be the `min` of the two gaps. The trivial system has
gap `⊤`, so stacking with it never lowers a gap.
-/

namespace CondensedPhases

open scoped ENNReal

/-- The trivial system: one-dimensional on-site spaces, zero interaction, and gap `⊤ = +∞`. -/
def triv (L : SiteSpace) : System L where
  onSiteDim := fun _ => 1
  interaction := 0
  gap := ⊤

/-- Stacking of systems `H ⊠ K`: dimensions multiply, interactions add, and gaps combine by `min`. -/
def stack {L : SiteSpace} (H K : System L) : System L where
  onSiteDim := fun x => H.onSiteDim x * K.onSiteDim x
  interaction := H.interaction + K.interaction
  gap := min H.gap K.gap

/-- The gap of a stacked system is the minimum of the two gaps. -/
@[simp] theorem stack_gap {L : SiteSpace} (H K : System L) :
    (CondensedPhases.stack H K).gap = min H.gap K.gap := rfl

/-- The trivial system has gap `⊤`. -/
@[simp] theorem triv_gap (L : SiteSpace) : (triv L).gap = ⊤ := rfl

/-- The trivial system is gapped. -/
theorem gapped_triv (L : SiteSpace) : (triv L).Gapped := by
  simp [System.Gapped, triv]

/-- Stacking with the trivial system on the right leaves the gap unchanged. -/
@[simp] theorem stack_gap_triv_right {L : SiteSpace} (H : System L) :
    (CondensedPhases.stack H (triv L)).gap = H.gap := by
  rw [stack_gap, triv_gap, min_eq_left le_top]

/-- Stacking with the trivial system on the left leaves the gap unchanged. -/
@[simp] theorem stack_gap_triv_left {L : SiteSpace} (H : System L) :
    (CondensedPhases.stack (triv L) H).gap = H.gap := by
  rw [stack_gap, triv_gap, min_eq_right le_top]

/-- Family-level gap stacking: uniform gaps `Δ` and `Δ'` stack to uniform gap `min Δ Δ'`. -/
theorem UniformGapAtLeast.stack {L : SiteSpace} {S : Type} {Δ Δ' : ℝ≥0∞}
    {f g : Family L S} (hf : UniformGapAtLeast Δ f) (hg : UniformGapAtLeast Δ' g) :
    UniformGapAtLeast (min Δ Δ') (fun s => CondensedPhases.stack (f s) (g s)) := by
  intro s
  rw [stack_gap]
  exact le_min (le_trans (min_le_left Δ Δ') (hf s))
    (le_trans (min_le_right Δ Δ') (hg s))

/-- Stacking preserves the uniformly gapped substack. -/
theorem UniformlyGapped.stack {L : SiteSpace} {S : Type} {f g : Family L S}
    (hf : UniformlyGapped f) (hg : UniformlyGapped g) :
    UniformlyGapped (fun s => CondensedPhases.stack (f s) (g s)) := by
  obtain ⟨Δ, hΔ, hfΔ⟩ := hf
  obtain ⟨Δ', hΔ', hgΔ'⟩ := hg
  exact ⟨min Δ Δ', lt_min hΔ hΔ', UniformGapAtLeast.stack hfΔ hgΔ'⟩

/-- Stacking with the trivial system never lowers a family's uniform gap. -/
theorem UniformGapAtLeast.stack_triv {L : SiteSpace} {S : Type} {Δ : ℝ≥0∞}
    {f : Family L S} (hf : UniformGapAtLeast Δ f) :
    UniformGapAtLeast Δ (fun s => CondensedPhases.stack (f s) (triv L)) := by
  intro s
  rw [stack_gap, triv_gap, min_eq_left le_top]
  exact hf s

/-- A system is invertible up to a phase relation when a stacking partner returns it to trivial. -/
def InvertibleUpTo {L : SiteSpace} (rel : System L → System L → Prop) (H : System L) : Prop :=
  ∃ K, rel (CondensedPhases.stack H K) (triv L)

end CondensedPhases
