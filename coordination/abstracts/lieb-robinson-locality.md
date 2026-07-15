# Part I — lieb-robinson-locality

**Title:** Condensed Locality: Lieb–Robinson Estimates and Quasi-Local Dynamics on the Moduli Stack of Hamiltonians

**Companion key:** `paperLocality`. Program input #1 (analytic backbone; ground floor of `\Ham_{d,G}`).

**Abstract (settled).**
The condensed-mathematics program for topological phases replaces the topological space
of admissible interactions by a condensed object probed by profinite sets, so that
continuous families, profinite disorder hulls, and inverse limits are handled in one
category with exact homological algebra. This first paper supplies the analytic ground
floor. Fixing a Nachtergaele–Sims–Young `F`-function on a lattice, we recall that the
`G`-symmetric interactions of finite `F`-norm form a Banach space `B_F`, and we condense
it: `\cond{B_F}(S)=\Cont(S,B_F)` on profinite probes. We prove three theorems with
complete proofs assembled from present-day results. (I-A) `B_F` is a real Banach space and
Heisenberg dynamics is a strongly continuous one-parameter group of `*`-automorphisms of
the quasi-local algebra obeying a Lieb–Robinson bound. (I-B) `\cond{B_F}` is a condensed
`\mathbb{R}`-vector space and the assignment of dynamics is a morphism of light condensed
sets `\mathbb{R}\times\cond{B_F}\to\cond{\mathrm{Aut}(\mathcal A)}`, by full faithfulness of
condensation on compactly generated spaces. (I-C) An `S`-continuous family of interactions
over a profinite base is exactly a norm-convergent system of locally constant families over
finite quotients, and — this is the load-bearing point — a uniform `F`-norm bound forces a
Lieb–Robinson velocity and constants that are uniform over the base. Quasi-adiabatic
continuation and Bachmann–Michalakis–Nachtergaele–Sims automorphic equivalence are then the
morphism-level tools that generate the equivalence class `\Weq` inverted by companion
papers. We close with three numbered conjectures: that `\Ham_{d,G}` is a condensed higher
stack (I-1), that time-dependent `F`-function interactions generate a condensed group with
quasi-adiabatic continuation as internal path-lifting (I-2), and that Lieb–Robinson
estimates satisfy descent along finite quotients of a disorder hull (I-3). A Haskell
simulation of the transverse-field Ising chain exhibits the light cone and fits the velocity.

**Section outline.**
1. Introduction (1.1 the locality problem in the condensed program; 1.2 results and stance;
   1.3 Relation to companion papers)
2. Quantum lattice systems and interaction spaces (lattice, quasi-local algebra, `F`-functions, `B_F`)
3. The Heisenberg dynamics and the Lieb–Robinson bound
4. Condensation of the interaction space
5. Uniform Lieb–Robinson bounds for `S`-parametrized families
6. The condensed Heisenberg flow
7. Quasi-adiabatic continuation and the equivalence class `\Weq`
8. Conjectures: toward the condensed stack
9. Numerical illustration: the light cone in the transverse-field Ising chain
10. Discussion
11. Conclusion

**Planned Theorem/Proposition labels (provable today, cited proofs).**
- Theorem I-A — Banach interaction space and strongly continuous Lieb–Robinson dynamics (repackages `nsy-quasilocality-1`, `lieb-robinson-1972`).
- Proposition I-A′ — `F`-function reweighting `F_a(r)=e^{-ar}F(r)` and the velocity formula `v=2\|\Phi\|_{F_a}C_{F_a}/a`.
- Theorem I-B — Condensed dynamics morphism (uses `clausen-scholze-condensed`, `barwick-haine-pyknotic`).
- Theorem I-C — Profinite family = compatible finite data; `S`-uniform Lieb–Robinson bound.
- Proposition I-D — Uniform exponential clustering from a uniform gap (from `hastings-koma`, `nachtergaele-sims-clustering`; used by Part III).
- Proposition I-E — Quasi-adiabatic continuation generates `\Weq` (from `hastings-wen-qac`, `bmns-automorphic`).

**Planned Conjecture labels (open; stable numbering).**
- Conjecture I-1 — `\Ham_{d,G}` is a condensed higher stack (gluing of the automorphism groupoid).
- Conjecture I-2 — Condensed group of quasi-local automorphisms; QAC as internal path-lifting.
- Conjecture I-3 — Descent of Lieb–Robinson estimates along finite quotients of a disorder hull `\dis`.

**Notation:** canonical macros from `coordination/notation.md` copied verbatim. Program objects use
`\Ham`, `\Gap`, `\Phase`, `\Weq`, `\cond{-}`, `\BF`, `\Ffun`, `\dis`. Paper-local: `\mathcal A`
(quasi-local algebra), `\mathrm{Aut}(\mathcal A)`, LR velocity `v`.
