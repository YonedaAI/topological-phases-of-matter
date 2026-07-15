---
reviewer: gemini-3.1-pro
paper: spectral-gap-stability
round: 1
date: 2026-07-14T21:34:04Z
---

**Critical**
* None. The mathematical framework and the careful handling of the Cubitt-Pérez-García-Wolf undecidability wall are exceptionally rigorous and conceptually sound.

**Major**
* **Section 5.1 (Def 5.1):** Consider briefly discussing whether the stability stratum could theoretically be expanded to include exactly solvable *non-frustration-free* models (e.g., free fermion topological insulators), or if the lack of local projector bounds strictly prevents applying these specific condensed-openness arguments.

**Minor**
* **Section 2.2 (Eq. 2):** Clarify how the fixed index $n$ for the $n$-gap is managed in practice if exact level crossings or accidental degeneracies occur as the finite volume $\Lambda$ grows.
* **Section 4.3 (Prop 4.3):** You correctly establish lower semicontinuity. Explicitly noting the failure of *upper* semicontinuity (where eigenvalues can suddenly plummet in the limit) would further reinforce your arguments about thermodynamic limit pathologies.
* **Section 7.1 (Eq. 4):** Briefly note why open boundary conditions (OBC) were chosen over periodic boundary conditions (PBC) for the transverse-field Ising model, as PBCs typically reduce finite-size edge effects in exact diagonalization gap studies.
* **Section 7.2:** The exact trace identities (Eq. 7) are an excellent algorithmic sanity check. It may be worth adding a single sentence regarding the floating-point precision limits of the cyclic Jacobi routine as $N$ scales up.

VERDICT: MINOR REVISIONS
