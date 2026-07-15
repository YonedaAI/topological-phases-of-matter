---
reviewer: codex (OpenAI, gpt-5.5, reasoning effort xhigh)
type: haskell
topic: spectral-gap-stability
round: 2
date: 2026-07-14T18:55:00Z
---

Prompt: RE-REVIEW (round 2) of the Haskell in src/spectral-gap-stability/. Round-1
fixes applied: symEigenvalues -> Either String EigenReport (validates m>0,
length==m*m, finiteness, symmetry via O(m^2) row-chunk compare; reports
residual+sweeps); Config raw constructor hidden behind mkConfig (rejects nSites<1,
>12, non-finite field); hamiltonianWithField requires length vs == nSites; Jacobi
returns (residual, sweeps, converged) with tolerance relative to Frobenius norm, Left
on cap; gapAt/twoGapAt/perturbedGap return Maybe (all ~10 call sites updated);
closed-form solver validation (diagonal 4x4, symmetric 2x2 quadratic formula, TFIM
g=0 and N=1 corners); solver-based trace identities at N=6,7,8; 'equational proof'
renamed 'theorem instance' with exact paper labels; g in {0,1,2} frequency-weighted
generator + 3 exact freeFermionGap anchors; TestMain.hs test driver (library stanza
deliberately skipped: flat hs-source-dirs triggers -Wmissing-home-modules -
documented in .cabal comment). Suite: -Wall -Wextra -Werror clean, QuickCheck 7/7,
theorem instances 127/127, exit 0, base-only preserved, gap-table output
byte-identical at 4 decimals. Verify the fixes and check fresh for type safety,
property correctness, instance-labeling honesty, numerical soundness, coverage,
style. End with exactly one line: VERDICT: PASS or VERDICT: NEEDS_FIX

Verification note from the reviewer: it ran in a read-only sandbox this round, so
`cabal test`/`runghc` could not execute (Cabal/GHC needed writable build/temp
directories); it instead confirmed `ghc -fno-code -fno-write-interface -Wall
-Wextra -Werror` on both TestMain.hs and Main.hs passed.

**Findings**

- **High**: [TFIM.hs](../src/spectral-gap-stability/TFIM.hs#L256) still trusts
  `m * m` in `Int` before validating the exported `symEigenvalues` input. For very
  large `m`, that product can overflow; if the supplied list length matches the
  overflowed value, the guard can pass and
  [runJacobi](../src/spectral-gap-stability/TFIM.hs#L290) /
  [idx](../src/spectral-gap-stability/TFIM.hs#L313) then operate as if a real
  `m x m` buffer exists. Fix by rejecting `m > floor (sqrt maxBound)` or using an
  overflow-safe expected-size calculation before `length`, `allocaArray`, and
  indexing.

- **Medium**: [maxSites = 12](../src/spectral-gap-stability/TFIM.hs#L92) makes
  `mkConfig 12 g` valid, but the paper and deterministic solver coverage stop at
  `N <= 8`, and `N=12` implies a `4096 x 4096` dense matrix plus cyclic Jacobi
  sweeps. Either cap the solver-backed config at 8, or split construction from
  solver support and return `Either` from `spectrum` for unsupported sizes.

- **Low**: [Proofs.hs](../src/spectral-gap-stability/Proofs.hs#L237) has an
  arithmetic comment drift: `6 sites * 2 * perSite` with `perSite = g0 / 24` is
  `g0 / 2`, not `g0 / 4`. The check still satisfies `< g0`, but the explanation
  should be corrected.

VERDICT: NEEDS_FIX
