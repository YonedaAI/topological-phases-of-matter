---
reviewer: gemini-3.1-pro
paper: bordism-realizability
round: 1
date: 2026-07-14T21:34:19Z
---

Here is the peer review for the submitted manuscript:

### Critical Issues
*(None found)*

### Major Issues
*(None found)*

### Minor Issues
*   **Preamble (LaTeX Quality):** The packages `amsmath` and `amssymb` are imported twice—once under the `% ---- core math ----` block and again under the `% ==== topological-phases-of-matter ====` block. This does not break the build but clutters the preamble.
*   **Preamble (LaTeX Quality):** The `everypage` package is considered obsolete in modern LaTeX2e (post-2020 releases). Consider replacing `\AddEverypageHook` with the native modern hook system, such as `\AddToHook{shipout/background}`, to ensure long-term compatibility.
*   **Section 2.1 & Section 4.3 (Notation / Clarity):** The macro `\gapbound` is defined in the preamble as `\Delta` and used to represent the uniform gap bound in the definition of $\Gap_{d,G}(S)$ (Section 2.1). However, in Section 4.3, $\Delta$ is used as the $p$-wave pairing potential in the Kitaev chain Hamiltonian. While physically standard and easily disambiguated by context, introducing a distinct macro for the pairing potential (or using a different symbol for the gap bound) would prevent any formal symbol collision.
*   **Section 6 (LaTeX Quality):** The `longtable` environment relies on fixed `p{...}` column widths that sum to 12.65 cm. Depending on the exact margin size and engine rendering, the table might not span the text width optimally. Utilizing the `tabularx` package or specifying relative column widths (e.g., `p{0.2\textwidth}`) provides more robust and scalable formatting.

### Evaluation Categories

*   **Mathematical Correctness:** Excellent. The manuscript's distinction between general gapped realizability and exact commuting-projector ($\CP$) realizability is a rigorously handled nuance that accurately reflects the constraints of the Kapustin-Fidkowski theorem. The derivation of the Kitaev chain $\Ztwo$ invariant (Proposition 4.2) and the exact stabilizer computation of the cluster-state string order (Proposition 3.3) are flawlessly executed. The reasoning regarding the expectation of Pauli strings within the stabilizer group is highly precise.
*   **Clarity:** Very high. The exposition seamlessly integrates condensed mathematics terminology (profinite hulls, condensed spectra) with physics standard models (cluster states, $E_8$ state, Walker-Wang models). The status table in Section 6 is exceptionally clear and provides a sharp, heavily informative summary of the current landscape.
*   **Completeness:** Comprehensive. The manuscript thoroughly maps out the known constructive and obstructed regions before stating formal conjectures for the open regions. It fairly and explicitly bounds the limits of its completeness theorem (Theorem V-B) in Remark 5.2, preventing over-extrapolation.
*   **Logical Structure:** Superb. The transition from established index theorems and strict obstructions to well-defined global conjectures perfectly separates known rigorous statements from hypothesized topological properties.
*   **LaTeX Quality:** High. The source code is beautifully formatted, heavily documented, and uses excellent semantic macros (e.g., `\Phase`, `\Gap`, `\cond`), barring the minor package redundancies mentioned above. 

VERDICT: MINOR REVISIONS
