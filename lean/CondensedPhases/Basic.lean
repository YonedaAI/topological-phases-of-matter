import Mathlib

/-!
# CondensedPhases.Basic — lattice geometry and profinite probes

Ground-floor abstractions for the condensed topological-phases program: a coarse metric
space of lattice sites, finite regions, a locality radius, and the profinite parameter
probes over which families of systems are indexed. See Paper I
(`lieb-robinson-locality`) and Paper II (`positivity-cstar-norms`, profinite probes).
-/

namespace CondensedPhases

open scoped ENNReal

/-- A coarse metric space of lattice sites: the geometry underlying a quantum spin system. -/
structure SiteSpace where
  Site : Type
  dist : Site → Site → ℝ
  dist_self : ∀ x, dist x x = 0
  dist_nonneg : ∀ x y, 0 ≤ dist x y
  dist_comm : ∀ x y, dist x y = dist y x
  dist_triangle : ∀ x y z, dist x z ≤ dist x y + dist y z

/-- A finite region of the lattice. -/
def Region (L : SiteSpace) : Type := Finset L.Site

/-- A region has locality radius `r` when all its sites are within distance `r`. -/
def Region.WithinRadius {L : SiteSpace} (r : ℝ) (X : Region L) : Prop :=
  ∀ x : L.Site, x ∈ (show Finset L.Site from X) →
    ∀ y : L.Site, y ∈ (show Finset L.Site from X) → L.dist x y ≤ r

/-- A parameter probe: the underlying set of a test object indexing a family of systems. -/
structure Probe where
  Point : Type

/-- A profinite probe `S = lim Sᵢ`, presented as a system of finite quotients. -/
structure ProfiniteProbe where
  Point : Type
  Index : Type
  quotient : Index → Type
  finiteQuotient : ∀ i, Finite (quotient i)
  proj : ∀ i, Point → quotient i

/-- A function on a profinite probe is detected by finite quotients when it factors through one finite quotient. -/
def FactorsThroughFiniteQuotient (P : ProfiniteProbe) {α : Type*}
    (g : P.Point → α) : Prop :=
  ∃ (i : P.Index) (h : P.quotient i → α), g = fun p => h (P.proj i p)

end CondensedPhases
