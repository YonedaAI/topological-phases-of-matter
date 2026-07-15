---
reviewer: gemini-3.1-pro
paper: lieb-robinson-locality
round: 1
date: 2026-07-14T21:34:01Z
---

Here is a peer review for the manuscript "Condensed Locality: Lieb--Robinson Estimates and Quasi-Local Dynamics on the Moduli Stack of Hamiltonians".

### General Overview
This paper provides an exceptionally well-written, rigorous bridge between the operator-algebraic foundations of quantum lattice systems (Lieb-Robinson bounds, $\Ffun$-functions, quasi-local algebras) and the Clausen-Scholze condensed mathematics program. The author's editorial discipline—strictly delineating established analytical results (Theorems/Propositions) from open topological assembly questions (Conjectures)—is commendable and sets a gold standard for clarity in mathematical physics. The mathematical framework is completely solid, correctly leveraging the compactly generated nature of the Banach space of interactions to promote the Heisenberg dynamics to a morphism of condensed sets.

Below is the structured feedback organized by severity.

### Critical Issues
*None.* The analytical proofs (e.g., completeness of the Banach space, Lipschitz continuity of the dynamics, and uniform light cone estimates) are mathematically sound and correctly apply standard operator algebraic techniques (Duhamel's formula, Nachtergaele-Sims-Young bounds) to the new condensed setting. 

### Major Issues
*None.* The logical structure smoothly carries the reader from the physical lattice setup to Banach spaces, into condensation, and finally to profinite uniformities and quasi-adiabatic continuation. The scope of the paper is well-defined and completely satisfied.

### Minor Issues (Suggestions for Polish)
**1. Code Availability and Reproducibility (Section 7, Line 482)**
*   **Context:** In Section 7, the text references the Haskell simulation via a local file path: `src/lieb-robinson-locality/`. 
*   **Feedback:** In a published paper or arXiv preprint, readers will not have access to your local directory structure. Please provide a public URL (e.g., a GitHub repository, Zenodo DOI) or explicitly state that the code is bundled in the arXiv source/supplementary materials.

**2. Notation Consistency in $\ell^1$ metric (Lemma 2.3, Lines 245-257)**
*   **Context:** Definition 2.1 establishes the metric as $\dist(x,y)$. In Lemma 2.3, the proof switches to the $\ell^1$-norm notation $\lvert x-y \rvert_1$ and $\lvert y \rvert_1$ (implicitly setting $x=0$). 
*   **Feedback:** While mathematically trivial due to the earlier mention of the $\ell^1$ metric, introducing $\lvert y \rvert_1$ abruptly as the distance from the origin slightly breaks the otherwise flawless notational discipline. Consider adding a brief inline definition (e.g., "...where $\lvert y \rvert_1 \eqdef \dist(0, y)$...") for absolute clarity.

**3. Generator/Flow Sign Convention (Proposition 6.2, Line 442)**
*   **Context:** The flow derivative is given as $\tfrac{d}{dr}\alpha_r=i\,\alpha_r\circ[\mathcal D(r),\,\cdot\,]$.
*   **Feedback:** This is completely correct under the standard Heisenberg picture convention where $\tau_t(A) = e^{iHt}Ae^{-iHt}$ differentiates to $i[H, \tau_t(A)] = i\tau_t([H, A])$. However, because sign conventions for derivations vary widely between the math and physics communities, it could be helpful to add a one-sentence reminder that you are working in the Heisenberg picture where automorphisms act as $U^* A U$ rather than $U A U^*$, which justifies the positive sign in the commutator. 

**4. Minor LaTeX / Typographical Observations**
*   **Line 183:** The abstract states "first paper supplies the analytic ground floor." Consider capitalizing "First" or adjusting the punctuation for flow.
*   **Macros:** The LaTeX source is of very high quality. The use of a canonical macro block (`\cond`, `\BF`, `\Phase`) is excellent practice for a multi-part series.

VERDICT: MINOR REVISIONS

