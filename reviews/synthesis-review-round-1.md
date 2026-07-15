---
reviewer: gemini-3.1-pro
paper: synthesis
round: 1
date: 2026-07-14T23:41:34Z
---

**Critical**

No critical issues were found. The manuscript flawlessly adheres to the required parameters of the program: the boundaries between modules are respected, the two hard walls (Cubitt--Pérez-García--Wolf undecidability and the Kapustin--Fidkowski no-go) are rigorously acknowledged without exception, and the proved-vs-conjectured boundary is maintained with exemplary honesty. The program-level claims are strictly presented as conjectures (VI-1 to VI-4), and no claims of lattice-to-EFT equivalence or gap-openness beyond the physical stratum are smuggled in as proven. The required structural elements—the boxed sequence, the homotopy dictionary, the modular-composition diagram, the consolidated open-problems table, and the "Relation to companion papers" subsection—are all present, complete, and correct. Notation is perfectly consistent with the canonical macros.

**Major**

- **Algebraic Topology in Section 6.3:** Equation (13) states the isomorphism $E^{q+1}(N_\alpha, N_\alpha\setminus\Sig_f^{(\alpha)}) \cong \widetilde E^{\,q+1-c}(\Sig_f^{(\alpha)}{}_+\wedge S^{c-1}_{\mathrm{link}}\text{-datum})$. This formula is algebraically garbled. By the Thom isomorphism for a codimension-$c$ normal bundle $N_\alpha$, the relative cohomology is isomorphic to $E^{q+1-c}(\Sig_f^{(\alpha)})$. This comes from the equivalence of the Thom space to $\Sig_f^{(\alpha)}{}_+ \wedge S^c$. The linking sphere $S^{c-1}$ is integrated out (suspended to $S^c$) in this process, so it should not appear as a smash factor on the right-hand side. If your intent is to evaluate the local charge on the linking sphere itself, that involves the restriction map to the fiber $E^q(S^{c-1}_{\mathrm{link}})$, not the Thom isomorphism. Please rewrite this equation to correctly reflect the standard Thom isomorphism.
- **Terminology in Section 3.2 (Recollection 3.3):** The text refers to $\beta$ as "the order-eight real Bott class in the $KO$ case." This is a mathematical misnomer. The real Bott element $\beta_{KO} \in KO_8(\RR) \cong \ZZ$ has *degree* (or period) eight, but its order as a group element is infinite. Calling it "order-eight" implies that $8\beta = 0$, which is false for the periodic generator. Please correct this to "degree-eight" or "period-eight".

**Minor**

- **SSH Discriminant Singularity (Section 7):** In the SSH worked example, the parameter space $B$ is the real $(t_1,t_2)$-plane. The discriminant $\Sig = \{ |t_1|=|t_2| \}$ consists of two intersecting lines ($t_1=t_2$ and $t_1=-t_2$). While this is indeed codimension 1 almost everywhere—and the linking sphere $S^0$ correctly yields the $\pm 1$ winding jump across the walls—it has a singularity at the origin $(0,0)$ where the gap closes for $k=0$ and $k=\pi$ simultaneously and the codimension is 2. Adding a brief mention of this origin crossing would make the topological description strictly rigorous.
- **LaTeX formatting in Eq (13):** The inclusion of `\text{-datum}` directly inside the smash product argument looks typographically awkward and mathematically informal. 
- **Table 1 Construction:** The `longtable` environment is beautifully crafted, and the column width (`p{6.9cm}`) compiles cleanly within the 1-inch margins. The dependencies explicitly map the root structure (anchored at I-1) perfectly.

VERDICT: MINOR REVISIONS
