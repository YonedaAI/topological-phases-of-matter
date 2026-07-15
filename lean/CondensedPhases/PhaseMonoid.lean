import Mathlib
import CondensedPhases.Basic
import CondensedPhases.Gap
import CondensedPhases.Stacking

/-!
# CondensedPhases.PhaseMonoid — the phase monoid and its Grothendieck completion

The phase equivalence is bundled with the hypotheses needed to derive the commutative
monoid `(Phases, ⊠, [triv])` (Paper IV `prop:monoid`). The Grothendieck group
completion of a commutative monoid is constructed explicitly (Paper IV `def:groth`,
`thm:groth`) with its universal property and functoriality.
-/

namespace CondensedPhases

/-- The phase equivalence `𝓦`, bundled with the properties Paper IV `prop:monoid` establishes. -/
structure PhaseEquiv (L : SiteSpace) where
  rel : System L → System L → Prop
  refl : ∀ H, rel H H
  symm : ∀ {H K}, rel H K → rel K H
  trans : ∀ {H K M}, rel H K → rel K M → rel H M
  congr : ∀ {H H2 K K2}, rel H H2 → rel K K2 →
    rel (CondensedPhases.stack H K) (CondensedPhases.stack H2 K2)
  stack_assoc : ∀ H K M,
    rel (CondensedPhases.stack (CondensedPhases.stack H K) M)
      (CondensedPhases.stack H (CondensedPhases.stack K M))
  stack_comm : ∀ H K, rel (CondensedPhases.stack H K) (CondensedPhases.stack K H)
  stack_triv : ∀ H, rel (CondensedPhases.stack H (triv L)) H

/-- The setoid underlying a phase equivalence. -/
def PhaseEquiv.setoid {L : SiteSpace} (W : PhaseEquiv L) : Setoid (System L) :=
  ⟨W.rel, W.refl, fun {_ _} h => W.symm h, fun {_ _ _} h1 h2 => W.trans h1 h2⟩

/-- The set of phases, the quotient of systems by the phase equivalence. -/
def Phases {L : SiteSpace} (W : PhaseEquiv L) : Type := Quotient W.setoid

/-- The class of a system as a phase. -/
def Phases.mk {L : SiteSpace} (W : PhaseEquiv L) (H : System L) : Phases W :=
  Quotient.mk W.setoid H

/-- The commutative monoid of phases `(Phases W, ⊠, [triv])`. -/
instance instCommMonoidPhases {L : SiteSpace} (W : PhaseEquiv L) : CommMonoid (Phases W) where
  mul := Quotient.lift₂ (fun H K => Phases.mk W (CondensedPhases.stack H K))
    (by intro a1 b1 a2 b2 h1 h2; exact Quotient.sound (W.congr h1 h2))
  one := Phases.mk W (triv L)
  mul_assoc := by
    intro x y z
    refine Quotient.inductionOn₃ x y z ?_
    intro H K M
    exact Quotient.sound (W.stack_assoc H K M)
  one_mul := by
    intro x
    refine Quotient.inductionOn x ?_
    intro H
    exact Quotient.sound (W.trans (W.stack_comm (triv L) H) (W.stack_triv H))
  mul_one := by
    intro x
    refine Quotient.inductionOn x ?_
    intro H
    exact Quotient.sound (W.stack_triv H)
  mul_comm := by
    intro x y
    refine Quotient.inductionOn₂ x y ?_
    intro H K
    exact Quotient.sound (W.stack_comm H K)

example {L : SiteSpace} (W : PhaseEquiv L) : CommGroup (Phases W)ˣ := inferInstance

section Grothendieck

variable (M : Type*) [CommMonoid M]

/-- The Grothendieck relation on `M × M`: `(a,b) ~ (c,d)` iff `∃ e, a*d*e = c*b*e`. -/
def GrothRel : (M × M) → (M × M) → Prop :=
  fun p q => ∃ e : M, p.1 * q.2 * e = q.1 * p.2 * e

/-- Reflexivity of the Grothendieck relation. -/
theorem grothRel_refl (p : M × M) : GrothRel M p p := ⟨1, rfl⟩

/-- Symmetry of the Grothendieck relation. -/
theorem grothRel_symm {p q : M × M} (h : GrothRel M p q) : GrothRel M q p := by
  obtain ⟨e, he⟩ := h
  exact ⟨e, he.symm⟩

/-- Transitivity of the Grothendieck relation, using witness `q.2 * e * e'`. -/
theorem grothRel_trans {p q r : M × M}
    (h1 : GrothRel M p q) (h2 : GrothRel M q r) : GrothRel M p r := by
  obtain ⟨e, he⟩ := h1
  obtain ⟨e2, he2⟩ := h2
  refine ⟨q.2 * e * e2, ?_⟩
  calc
    p.1 * r.2 * (q.2 * e * e2) = (p.1 * q.2 * e) * r.2 * e2 := by ac_rfl
    _ = (q.1 * p.2 * e) * r.2 * e2 := by rw [he]
    _ = (q.1 * r.2 * e2) * p.2 * e := by ac_rfl
    _ = (r.1 * q.2 * e2) * p.2 * e := by rw [he2]
    _ = r.1 * p.2 * (q.2 * e * e2) := by ac_rfl

/-- The Grothendieck setoid. -/
def grothSetoid : Setoid (M × M) :=
  ⟨GrothRel M, grothRel_refl M, fun {_ _} h => grothRel_symm M h,
    fun {_ _ _} h1 h2 => grothRel_trans M h1 h2⟩

/-- The Grothendieck group completion `K(M)` of a commutative monoid. -/
def GrothendieckGroup : Type _ := Quotient (grothSetoid M)

/-- The Grothendieck completion is a commutative group. -/
instance instCommGroupGrothendieckGroup : CommGroup (GrothendieckGroup M) where
  mul := Quotient.lift₂
    (fun p q : M × M => Quotient.mk (grothSetoid M) (p.1 * q.1, p.2 * q.2))
    (by
      rintro ⟨a, b⟩ ⟨c, d⟩ ⟨a2, b2⟩ ⟨c2, d2⟩ ⟨e, he⟩ ⟨e2, he2⟩
      apply Quotient.sound
      refine ⟨e * e2, ?_⟩
      calc
        (a * c) * (b2 * d2) * (e * e2) = (a * b2 * e) * (c * d2 * e2) := by ac_rfl
        _ = (a2 * b * e) * (c * d2 * e2) := by rw [he]
        _ = (a2 * b * e) * (c2 * d * e2) := by rw [he2]
        _ = (a2 * c2) * (b * d) * (e * e2) := by ac_rfl)
  one := Quotient.mk (grothSetoid M) (1, 1)
  inv := Quotient.lift (fun p : M × M => Quotient.mk (grothSetoid M) (p.2, p.1))
    (by
      rintro ⟨a, b⟩ ⟨c, d⟩ ⟨e, he⟩
      apply Quotient.sound
      refine ⟨e, ?_⟩
      calc
        b * c * e = c * b * e := by ac_rfl
        _ = a * d * e := he.symm
        _ = d * a * e := by ac_rfl)
  mul_assoc := by
    intro x y z
    refine Quotient.inductionOn₃ x y z ?_
    rintro ⟨a, b⟩ ⟨c, d⟩ ⟨e, f⟩
    apply Quotient.sound
    refine ⟨1, by simp [mul_comm, mul_left_comm]⟩
  one_mul := by
    intro x
    refine Quotient.inductionOn x ?_
    rintro ⟨a, b⟩
    apply Quotient.sound
    refine ⟨1, by simp⟩
  mul_one := by
    intro x
    refine Quotient.inductionOn x ?_
    rintro ⟨a, b⟩
    apply Quotient.sound
    refine ⟨1, by simp⟩
  inv_mul_cancel := by
    intro x
    refine Quotient.inductionOn x ?_
    rintro ⟨a, b⟩
    apply Quotient.sound
    refine ⟨1, by simp [mul_comm]⟩
  mul_comm := by
    intro x y
    refine Quotient.inductionOn₂ x y ?_
    rintro ⟨a, b⟩ ⟨c, d⟩
    apply Quotient.sound
    refine ⟨1, by simp [mul_comm, mul_left_comm]⟩

/-- The canonical monoid homomorphism `γ_M : M →* K(M)`, `a ↦ ⟦(a,1)⟧`. -/
def groth_gamma : M →* GrothendieckGroup M where
  toFun := fun a => Quotient.mk (grothSetoid M) (a, 1)
  map_one' := rfl
  map_mul' := by
    intro a b
    apply Quotient.sound
    refine ⟨1, by simp⟩

end Grothendieck

private theorem groth_lift_respects {M A : Type*} [CommMonoid M] [CommGroup A] (f : M →* A)
    {p q : M × M} (hrel : GrothRel M p q) :
    f p.1 * (f p.2)⁻¹ = f q.1 * (f q.2)⁻¹ := by
  rcases p with ⟨a, b⟩
  rcases q with ⟨c, d⟩
  change ∃ e : M, a * d * e = c * b * e at hrel
  rcases hrel with ⟨e, he⟩
  have h : f a * f d * f e = f c * f b * f e := by
    simpa [map_mul, mul_assoc] using congrArg f he
  have hcancel : f a * f d = f c * f b := mul_right_cancel h
  have hfa : f a = f c * f b * (f d)⁻¹ := eq_mul_inv_of_mul_eq hcancel
  calc
    f a * (f b)⁻¹ = (f c * f b * (f d)⁻¹) * (f b)⁻¹ := by rw [hfa]
    _ = f c * (f b * (f d)⁻¹) * (f b)⁻¹ := by
      rw [mul_assoc (f c) (f b) ((f d)⁻¹)]
    _ = f c * ((f d)⁻¹ * f b) * (f b)⁻¹ := by
      rw [mul_comm (f b) ((f d)⁻¹)]
    _ = (f c * (f d)⁻¹ * f b) * (f b)⁻¹ := by
      rw [← mul_assoc (f c) ((f d)⁻¹) (f b)]
    _ = f c * (f d)⁻¹ * (f b * (f b)⁻¹) := by
      rw [mul_assoc (f c * (f d)⁻¹) (f b) ((f b)⁻¹)]
    _ = f c * (f d)⁻¹ := by simp

private theorem grothRel_map {M N : Type*} [CommMonoid M] [CommMonoid N] (φ : M →* N)
    {p q : M × M} (h : GrothRel M p q) :
    GrothRel N (φ p.1, φ p.2) (φ q.1, φ q.2) := by
  rcases p with ⟨a, b⟩
  rcases q with ⟨c, d⟩
  change ∃ e : M, a * d * e = c * b * e at h
  rcases h with ⟨e, he⟩
  refine ⟨φ e, ?_⟩
  simpa [map_mul, mul_assoc] using congrArg φ he

/-- Universal lift from `K(M)` to a commutative group, sending `⟦(a,b)⟧` to `f a * (f b)⁻¹`. -/
def groth_lift {M A : Type*} [CommMonoid M] [CommGroup A] (f : M →* A) :
    GrothendieckGroup M →* A where
  toFun := Quotient.lift (s := grothSetoid M)
    (fun p : M × M => f p.1 * (f p.2)⁻¹)
    (fun _ _ hrel => groth_lift_respects f hrel)
  map_one' := by
    show f 1 * (f 1)⁻¹ = 1
    simp
  map_mul' := by
    intro x y
    refine Quotient.inductionOn₂ x y ?_
    rintro ⟨a, b⟩ ⟨c, d⟩
    change f (a * c) * (f (b * d))⁻¹ = (f a * (f b)⁻¹) * (f c * (f d)⁻¹)
    calc
      f (a * c) * (f (b * d))⁻¹ = (f a * f c) * (f (b * d))⁻¹ := by
        simp [map_mul]
      _ = (f a * f c) * (f b * f d)⁻¹ := by simp [map_mul]
      _ = (f a * (f b)⁻¹) * (f c * (f d)⁻¹) := by
        rw [mul_inv_rev]
        ac_rfl

/-- The universal lift composed with `γ_M` is the original monoid homomorphism. -/
theorem groth_lift_comp_gamma {M A : Type*} [CommMonoid M] [CommGroup A] (f : M →* A) :
    (groth_lift f).comp (groth_gamma M) = f := by
  ext a
  simp [groth_lift, groth_gamma]

/-- Uniqueness in the universal property of the Grothendieck completion. -/
theorem groth_lift_unique {M A : Type*} [CommMonoid M] [CommGroup A] (f : M →* A)
    (g : GrothendieckGroup M →* A) (hg : g.comp (groth_gamma M) = f) :
    g = groth_lift f := by
  ext x
  refine Quotient.inductionOn x ?_
  rintro ⟨a, b⟩
  have hcomp : ∀ x : M, g (groth_gamma M x) = f x := by
    intro x
    simpa using congrArg (fun h : M →* A => h x) hg
  have hrepr :
      Quotient.mk (grothSetoid M) (a, b) = groth_gamma M a * (groth_gamma M b)⁻¹ := by
    apply Quotient.sound
    refine ⟨1, by simp [mul_comm]⟩
  calc
    g (Quotient.mk (grothSetoid M) (a, b)) =
        g (groth_gamma M a * (groth_gamma M b)⁻¹) := by rw [hrepr]
    _ = g (groth_gamma M a) * (g (groth_gamma M b))⁻¹ := by simp
    _ = f a * (f b)⁻¹ := by simp [hcomp]
    _ = groth_lift f (Quotient.mk (grothSetoid M) (a, b)) := by simp [groth_lift]

/-- Functoriality of Grothendieck completion on monoid homomorphisms. -/
def groth_map {M N : Type*} [CommMonoid M] [CommMonoid N] (φ : M →* N) :
    GrothendieckGroup M →* GrothendieckGroup N where
  toFun := Quotient.map (sa := grothSetoid M) (sb := grothSetoid N)
    (fun p : M × M => (φ p.1, φ p.2))
    (fun _ _ h => grothRel_map φ h)
  map_one' := by
    show Quotient.mk (grothSetoid N) (φ 1, φ 1) = Quotient.mk (grothSetoid N) (1, 1)
    simp
  map_mul' := by
    intro x y
    refine Quotient.inductionOn₂ x y ?_
    rintro ⟨a, b⟩ ⟨c, d⟩
    apply Quotient.sound
    refine ⟨1, by simp [map_mul, mul_comm, mul_left_comm]⟩

/-- Grothendieck functoriality respects identity maps. -/
theorem groth_map_id (M : Type*) [CommMonoid M] :
    groth_map (MonoidHom.id M) = MonoidHom.id (GrothendieckGroup M) := by
  ext x
  refine Quotient.inductionOn x ?_
  rintro ⟨a, b⟩
  rfl

/-- Grothendieck functoriality respects composition. -/
theorem groth_map_comp {M N P : Type*} [CommMonoid M] [CommMonoid N] [CommMonoid P]
    (φ : M →* N) (ψ : N →* P) :
    groth_map (ψ.comp φ) = (groth_map ψ).comp (groth_map φ) := by
  ext x
  refine Quotient.inductionOn x ?_
  rintro ⟨a, b⟩
  rfl

end CondensedPhases
