---
reviewer: codex (gpt-5.5, model_reasoning_effort=xhigh)
type: haskell
paper: positivity-cstar-norms
round: 1
date: 2026-07-14
sandbox: read-only
command: >-
  codex exec -m gpt-5.5 -c 'model_reasoning_effort="xhigh"' --sandbox read-only
  -C /Users/mlong/Documents/Development/topological-phases-of-matter
  "Review the Haskell in src/positivity-cstar-norms/ for: type safety,
  QuickCheck property correctness, equational proof soundness (Proofs.hs),
  missing coverage vs the paper's theorems (II-A/II-B/II-C), idiomatic style."
---

# Codex Haskell review — round 1

Full reviewer output (findings section), reviewing `src/positivity-cstar-norms/`
as it stood after the initial build-out (Core, GNS, CrossedProduct, Properties,
Proofs, Main; 9 QuickCheck properties, 13 deterministic checks, `-Wall -Wextra
-Werror` clean, exit 0).

## Findings

1. **Core.hs:68** — `Matrix = [[Complex Double]]` gives no shape safety.
   `mmul`, `mtrace`, `setEntry`, `gnsRepresent`, etc. can silently truncate via
   `zipWith`/`transpose` or crash via `!!`. Fix with a smart `Matrix` type
   carrying dimensions, checked constructors, and dimension-checked operations
   returning `Either DimensionError` or `Maybe`.

2. **Core.hs:119** — `approxEqMat` ignores extra rows/columns, so
   unequal-shaped matrices can compare equal. This also weakens `isHermitian`
   at Core.hs:124. Fix by checking row counts and every row length before
   elementwise comparison.

3. **Core.hs:235, Properties.hs:162, Proofs.hs:84** — Cholesky is
   positive-definite only, but comments/properties describe agreement with
   "positivity" and cite II-A's closed positive cone, which is semidefinite.
   `diag(1,0)` is positive in II-A but rejected by `cholesky`. Fix by either
   renaming the claims to positive-definiteness/interior-cone checks, or
   implementing semidefinite positivity coverage and adding boundary tests.

4. **GNS.hs:12** — GNS claims to model `M_n / N_phi`, but the implementation
   keeps the full `n^2` prequotient with a possibly degenerate Gram matrix.
   Main.hs:69 also reports `n^2` as the GNS Hilbert-space dimension. For pure
   states this is false. Fix by quotienting null directions or explicitly
   renaming this as pre-GNS Gram data.

5. **Proofs.hs:14** — `Proofs.hs` cites GNS, II-A, and II-C, but never cites or
   covers II-B/Aoki. The paper's II-B is Aoki solidification/Bott inversion,
   not represented by these checks. Fix by adding an explicit II-B section
   saying it is non-computational/out of scope, or adding a separate
   symbolic/provenance check if that is intended.

6. **Properties.hs:145** — there is no randomized C*-identity property, only a
   single demo in Main.hs:96. Add `prop_cstarIdentity`: `||a* a|| ~= ||a||^2`.

7. **Properties.hs:128** — missing state-space coverage for
   `mkDensity`/`stateEval`: `isDensity (mkDensity m)`, `phi(1)=1`,
   `phi(a* a) >= 0`, and GNS Gram positive semidefiniteness. These are closer
   to II-A/GNS than several current example checks.

8. **Proofs.hs:177** — deterministic checks are fixed examples, not equational
   proofs of the cited theorem statements. Keep them, but label them as finite
   sanity checks and add explicit equational derivations in comments where the
   paper theorem is being mirrored.

9. **positivity-cstar-norms.cabal:17** — verification is only an executable,
   not a Cabal test suite. Add a `library` plus `test-suite` so `cabal test`
   runs `Properties`/`Proofs`; keep `Main` as the demo runner.

10. **positivity-cstar-norms.cabal:25** — dependency bounds are too loose for
    code using modern warning flags and QuickCheck behavior. Bound
    `QuickCheck`, set a realistic `base` lower bound, and import `foldl'`
    explicitly in Core.hs:65.

Verification note (from the reviewer): the already-built executable passes its
own 9 QuickCheck properties and 13 deterministic checks. `cabal check` could
not run in the reviewer's sandbox because PATH there resolves to
`cabal-install 2.2.0.0`, which rejects `cabal-version: 2.4`.

VERDICT: NEEDS_FIX
