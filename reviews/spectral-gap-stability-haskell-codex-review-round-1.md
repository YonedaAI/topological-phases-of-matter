---
reviewer: codex (OpenAI, gpt-5.5, reasoning effort xhigh)
type: haskell
topic: spectral-gap-stability
round: 1
date: 2026-07-14T18:01:00Z
---

Prompt: Review the Haskell in src/spectral-gap-stability/ (TFIM.hs with self-contained
Jacobi eigensolver, Properties.hs, Proofs.hs, Main.hs, .cabal) for: type safety,
QuickCheck property correctness, equational proof soundness in Proofs.hs (proofs
should cite theorems of papers/latex/spectral-gap-stability.tex: III-A Lipschitz
bound, Weyl instances, Kramers-Wannier duality, trace identities), numerical-method
soundness of the Jacobi eigensolver, missing coverage, idiomatic style. The suite is
deliberately base-only (no array/containers). List issues with file:line and concrete
fixes. End with exactly one line: VERDICT: PASS or VERDICT: NEEDS_FIX

Verification note from the reviewer: it ran the existing compiled test executable
before writing findings; it completed successfully (QuickCheck 7/7, deterministic
checks 94/94). The findings below are API/soundness/coverage problems the passing
suite does not itself catch.

**Findings**

- **High**: [TFIM.hs](../src/spectral-gap-stability/TFIM.hs#L167) exposes
  `symEigenvalues :: Int -> [Double] -> [Double]` with no length or dimension check.
  `pokeArray p xs` can write past the `m*m` allocation, and too-short input leaves
  unread initialized memory. Fix by making the raw solver internal or returning
  `Either EigenError [Double]` after checking `m > 0`, `length xs == m*m`, finite
  entries, and symmetry.

- **High**: [TFIM.hs](../src/spectral-gap-stability/TFIM.hs#L70) and
  [TFIM.hs](../src/spectral-gap-stability/TFIM.hs#L64) allow invalid site counts.
  `dim n = 2 ^ n` can throw for negative `n`, overflow for large `n`, and
  `expectedTraceSq (Config 0 g)` becomes nonsensical. Fix with a smart constructor
  such as `mkConfig :: Int -> Double -> Either String Config`, hide `Config(..)`, and
  bound `n` to the supported dense-diagonalization range.

- **High**: [TFIM.hs](../src/spectral-gap-stability/TFIM.hs#L97) accepts perturbation
  vectors of any length. Extra entries beyond `nSites` are interpreted as constant
  identity shifts because `testBit b i` is false for `i >= n`; then
  [TFIM.hs](../src/spectral-gap-stability/TFIM.hs#L112)'s exact `sum_i |v_i|`
  operator-norm claim is no longer exact. Fix by requiring
  `length vs == nSites cfg` before building the perturbed Hamiltonian.

- **High**: [TFIM.hs](../src/spectral-gap-stability/TFIM.hs#L181) returns eigenvalues
  even if Jacobi did not converge. The pivot skip
  [TFIM.hs](../src/spectral-gap-stability/TFIM.hs#L196), off-diagonal cutoff
  [TFIM.hs](../src/spectral-gap-stability/TFIM.hs#L239), and sweep cap
  [TFIM.hs](../src/spectral-gap-stability/TFIM.hs#L243) are absolute,
  scale-dependent, and silent. Fix by returning a convergence report with final
  residual/sweep count, using a relative tolerance like `eps * max 1 frobeniusNorm`,
  and failing rather than returning a diagonal after the cap.

- **Medium**: [Properties.hs](../src/spectral-gap-stability/Properties.hs#L63) and
  [Properties.hs](../src/spectral-gap-stability/Properties.hs#L70) do not validate
  the eigensolver strongly enough. Trace and trace-square are only two spectral
  moments; many wrong spectra preserve both. Add closed-form solver tests for
  diagonal matrices, generic `2x2` symmetric matrices, `g=0` TFIM where the matrix is
  already diagonal, and `N=1` with spectrum `[-abs g, abs g]`.

- **Medium**: [Properties.hs](../src/spectral-gap-stability/Properties.hs#L27) only
  samples `N=2..5`, while the demo and paper discuss `N<=8`;
  [Proofs.hs](../src/spectral-gap-stability/Proofs.hs#L15) explicitly avoids the
  solver for the `N=8` trace checks. Add deterministic eigensolver trace/moment cases
  at `N=6..8`, especially `g = 0, 1, 2`.

- **Medium**: [Proofs.hs](../src/spectral-gap-stability/Proofs.hs#L9),
  [Proofs.hs](../src/spectral-gap-stability/Proofs.hs#L24), and
  [Proofs.hs](../src/spectral-gap-stability/Proofs.hs#L145) call finite numerical
  checks "equational proofs." The Weyl and III-A checks depend on the same numerical
  eigensolver and finite samples, so they are theorem instances, not proofs.
  Rename/output them as instances, and cite exact paper labels: `\Cref{lem:weyl}`,
  `\Cref{thm:IIIA}`, `\eqref{eq:disp}`, and `\eqref{eq:traces}` from
  [spectral-gap-stability.tex](../papers/latex/spectral-gap-stability.tex#L642).

- **Medium**: [TFIM.hs](../src/spectral-gap-stability/TFIM.hs#L136) and
  [TFIM.hs](../src/spectral-gap-stability/TFIM.hs#L144) return `0` when a requested
  gap is undefined. That masks invalid dimensions as a real zero gap. Fix
  `gapAt`/`twoGapAt` to return `Maybe Double` or `Either String Double`, and
  pattern-match in callers.

- **Low**: [Properties.hs](../src/spectral-gap-stability/Properties.hs#L25) uses
  continuous generators, so exact boundary cases `g=0`, `g=1`, and `g=2` are almost
  never sampled. [Properties.hs](../src/spectral-gap-stability/Properties.hs#L112)'s
  Kramers-Wannier property is also self-referential and would pass for some wrongly
  scaled gap functions. Add explicit boundary cases and anchor checks such as
  `freeFermionGap 1 == 0`, `freeFermionGap 0 == 2`, and `freeFermionGap 2 == 2`.

- **Low**:
  [spectral-gap-stability.cabal](../src/spectral-gap-stability/spectral-gap-stability.cabal#L22)
  uses the same `Main.hs` for the executable and test suite. This makes `cabal test`
  run the demo table and pulls `QuickCheck` into the executable. More idiomatic:
  split a small base-only library, a demo executable, and a separate `TestMain.hs`;
  keep `QuickCheck` test-only unless the demo intentionally runs tests.

VERDICT: NEEDS_FIX
