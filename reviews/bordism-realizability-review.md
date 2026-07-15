---
reviewer: gemini-3.1-pro
paper: bordism-realizability
round: 3
date: 2026-07-14T21:47:52Z
---

**General Feedback:**
The author has executed a flawless round of revisions. The major issues raised in Round 2 have been thoroughly and rigorously addressed. The correction to the Pauli commutation logic in the cluster-state proof (Proposition 3.3) is mathematically exact, and the clarification in Theorem V-A(i) accurately captures the distinction between SRE phases and non-trivial SPTs via the symmetry constraint on finite-depth circuits. Furthermore, the requested stylistic and notational fixes—distinguishing the pairing amplitude $\Delta_{\mathrm{p}}$ from the uniform gap bound $\gapbound$, fixing the table float and caption, and noting the vanishing $d_x$ component—greatly improve the clarity of the manuscript.

The paper's conceptual framework, specifically the stark differentiation between general gapped-realizability and commuting-projector ($\CP$) realizability using the Kapustin–Fidkowski no-go theorem, is a highly valuable contribution to the literature. It brings precision to concepts that are too often conflated. The mathematical correctness, logical structure, completeness, and LaTeX quality of this manuscript are all exceptional. 

---

**Critical Issues:**
None.

**Major Issues:**
None.

**Minor Issues & Recommendations:**

*   **LaTeX Table Formatting (Section 7, Table 1):** 
    The explicit `p{...}` column widths in your `tabular` environment sum to `0.91\textwidth`. While `\centering` handles this gracefully and it compiles cleanly, if you wish for the table to span exactly the full text width in its final published form, you might consider using the `tabularx` package (with `X` columns) or adjusting the sum of your widths to account for `\tabcolsep`. This is purely a typographic preference and requires no mandatory action.
*   **Mathematical Clarity (Section 3.2 & 4.3):**
    No corrections needed, but I want to commend the exceptional clarity of the derivations provided in this revision. The telescoping identity in the cluster-state string order proof tracking the even-offset $Z^2=1$ cancellations is elegantly written. Likewise, the topological winding invariant logic mapping to the origin-inclusion of the ellipse (Proposition 4.3) is highly intuitive and pedagogically excellent.
*   **Completeness Warning (Remark 5.2):**
    The explicit guardrails cautioning the reader not to extrapolate the completeness theorem beyond on-site finite symmetries and low dimensions are highly appreciated and excellent practice for a mathematically rigorous physics paper.

VERDICT: ACCEPT
