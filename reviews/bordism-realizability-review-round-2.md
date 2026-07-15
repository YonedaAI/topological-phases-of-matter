---
reviewer: gemini-3.1-pro
paper: bordism-realizability
round: 2
date: 2026-07-14T21:41:00Z
---

Here is a peer review of the revised research paper, evaluating mathematical correctness, clarity, completeness, logical structure, and LaTeX quality.

### **Critical Issues**
*(None)*

### **Major Issues**
1. **Mathematical Correctness (Line 321):** There is a mathematical error in the proof of Proposition 3.3 regarding Pauli string commutation relations. The text states: *"The single-site $Z_j$ (resp. $X_j$) anticommutes with $K_{j\pm 1}$ (resp. with the stabilizer supported through $j$)"*. This is exactly backward. $Z_j$ anticommutes with $K_j = Z_{j-1}X_j Z_{j+1}$ (because it anticommutes with the central $X_j$), and $X_j$ anticommutes with $K_{j-1}$ and $K_{j+1}$ (because it anticommutes with their $Z_j$ terms). The sentence should be swapped: "$Z_j$ (resp. $X_j$) anticommutes with $K_j$ (resp. with $K_{j\pm 1}$)".
2. **Clarity / Correctness (Line 264):** In Theorem V-A (i), the statement reads: *"and the ground state is a fixed point of a finite-depth G-symmetric circuit"*. This is confusing and mathematically incorrect for non-trivial SPT phases. By definition, a non-trivial SPT phase *cannot* be prepared from a trivial product state by a *G-symmetric* finite-depth circuit. The phrasing "fixed point of a finite-depth circuit" is also non-standard (every state is trivially a fixed point of the identity circuit). If the intention was to describe the state as short-range entangled, it should say "prepared by a finite-depth circuit" (without the G-symmetric requirement). If it was meant to refer to RG properties, it should say "is a fixed point of a symmetric local RG transformation." Please revise for precision.

### **Minor Issues**
1. **Notation Clash (Lines 44 & 254):** The macro `\gapbound` is defined as `\Delta` in the preamble. Later, on line 254, the text reads: `with $p$-wave pairing $\Delta$ (distinct from the uniform gap bound $\gapbound$ of \Cref{sec:framework})`. Because both macros render identically as $\Delta$, the resulting PDF literally reads *"...pairing $\Delta$ (distinct from the uniform gap bound $\Delta$ of Section 2)"*, which defeats the purpose of the parenthetical clarification. Please use a different symbol for the pairing (e.g., $\Delta_p$ or $\delta$) or redefine the gap bound macro (e.g., $E_g$ or $\gamma$).
2. **LaTeX Quality (Line 413):** The status table is built using a raw `\begin{center} \begin{tabular} ... \end{tabular} \end{center}` block. While readable, best LaTeX practices dictate that this should be wrapped in a proper floating `\begin{table}[htbp]` environment, given a descriptive `\caption{}`, assigned a `\label{}`, and formally referenced in the preceding text (e.g., "Table 1").
3. **Typography (Line 350):** In the Bloch Hamiltonian $h(k)=d_z(k)\,\tau_z+d_y(k)\,\tau_y$, the text notes the Nambu basis without fully specifying that $\tau_x$ is strictly zero here due to the real $p$-wave pairing. It is mathematically fine and implied, but adding a brief note that $d_x(k) \equiv 0$ would improve completeness for readers unfamiliar with the Kitaev chain conventions.

### **General Feedback**
- **Completeness & Logical Structure:** Excellent. The paper maintains a very clear progression, systematically walking from exactly solvable models (group cohomology, Walker-Wang) into the firm Kapustin-Fidkowski obstruction, and culminating in the three well-motivated conjectures. 
- **Code & Verification:** The inclusion of exact stabilizer calculations to verify the string-order degradation cleanly supports the theoretical claims and is highly commendable.

VERDICT: MAJOR REVISIONS
