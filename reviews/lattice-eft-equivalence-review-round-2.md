---
reviewer: gemini-3.1-pro
paper: lattice-eft-equivalence
round: 2
date: 2026-07-14T21:38:43Z
---

Here is a peer review of the manuscript, evaluating it against the requested criteria.

### **Critical Issues**
*None.*

### **Major Issues**
* **Mathematical Correctness (Section 2, Definition 2.2 and Lemma 2.2):** 
  There is a flaw in how the gap of the trivial system is defined, which breaks the mathematics of stacking. In **Definition 2.2**, the trivial system $\mathbf{1}$ is defined as having a "unit gap by convention" (i.e., $\Delta = 1$). However, **Lemma 2.2** rigorously establishes the gap of a stacked system as $\min(\Delta_1, \Delta_2)$. If the trivial system has $\Delta = 1$, then stacking any system $H$ (with a gap $\Delta_H > 1$) with $\mathbf{1}$ will artificially lower the gap of the stacked system to $\min(\Delta_H, 1) = 1$. This contradicts the physical reality that adding a decoupled, single-state ancilla does not introduce new excited states or lower the gap. The correct mathematical convention for a 1-dimensional Hilbert space with a zero Hamiltonian (which possesses no excited states) is an *infinite* gap ($\Delta = \infty$). This natively ensures that $\min(\Delta_H, \infty) = \Delta_H$, perfectly preserving the gap of $H$ under stabilization.

### **Minor Issues**
* **Mathematical Correctness / Clarity (Section 4, Example 4.4):** 
  There is a direct notation clash in the non-cancellative monoid toy model. The monoid is defined and operated using additive notation ($t+a=t$, "commutative monoid $(M,+,0)$"). However, the text immediately refers to the elements as "powers of $t$" and denotes them as $[t^n]$. To maintain consistency with the additive Grothendieck group formalism, these must be referred to as "multiples of $t$" and denoted as $[nt]$.
* **Completeness (Section 3, Proof of Proposition 3.1):** 
  The proof states that the canonical associator and swap operator $\sigma_{h,h'}$ are depth-zero quasi-local isomorphisms. Because the paper explicitly incorporates free-fermion systems later (Section 6), it would be highly beneficial to add a brief sentence clarifying that $\sigma$ includes the Koszul sign rule for super-Hilbert spaces (graded vector spaces) when fermions are present. This prevents ambiguity for readers coming from the condensed matter fermion literature.
* **Clarity (Section 5.2, Conjecture IV-1):** 
  The phrase "*whose underlying spectrum of spaces is a connective cover of Kubota's $\mathit{IP}^\ast$ after realification*" appears to contain a typo. If the intent is to describe the passage from a condensed spectrum to its underlying classical topological space, the standard condensed mathematics term is "after realization" (or taking the shape). If "realification" refers to $K$-theory, it conflicts with the fact that Kubota's spectrum already natively models both complex and real Altland-Zirnbauer classes without needing to strip complex structures.
* **Logical Structure (Sections 5, 6, 7, and 9):** 
  The central conjectures are presented out of numerical order: IV-1 (Section 5.2), IV-5 (Section 6.1), IV-4 (Section 6.2), IV-2 (Section 7.2), and IV-3 (Section 9.3). While the introduction notes these are stable IDs from a wider series, introducing IV-5 and IV-4 before IV-2 abruptly disrupts the numerical sequence and narrative flow. Consider either renumbering the stable IDs to reflect their order of appearance in this specific paper, or adding a brief sentence at the start of Section 6 explicitly explaining the narrative reason for the numbering jump.

### **LaTeX Quality**
* **Excellent.** The LaTeX quality is outstanding and ready for publication. Custom macros (e.g., `\Phase`, `\cond`, `\IPcond`) are utilized consistently and correctly throughout the document. The commutative diagram in Section 7.3 is well-constructed using `tikz-cd`, and the tenfold-way table (Table 1) is cleanly formatted using `booktabs`. The implementation of `\AddToHook` for the sidebar and `cleveref` for referencing is modern, bug-free, and correctly executed.

VERDICT: MAJOR REVISIONS
