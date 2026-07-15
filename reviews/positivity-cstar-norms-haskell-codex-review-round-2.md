---
reviewer: codex (gpt-5.5)
type: haskell
paper: positivity-cstar-norms
round: 2
date: 2026-07-14
sandbox: read-only
notes: >-
  Reviewer verified round-1 Matrix work by typechecking with GHC 9.10.1
  (-fno-code -Wall -Wextra -Werror). Cabal execution was blocked in the
  reviewer's sandbox (`dist: createDirectory: permission denied` under
  read-only), but source-level typechecking succeeded.
---

# Codex Haskell review — round 2

Reviewing the round-1 fix pass (shape-safe `Core.Matrix`, `GNS.gnsRank`,
PSD/PD split, II-B scope note, 6 new QuickCheck properties, cabal
`test-suite` stanza, tightened dependency bounds).

## Findings

- **Medium** — [CrossedProduct.hs:48](/Users/mlong/Documents/Development/topological-phases-of-matter/src/positivity-cstar-norms/CrossedProduct.hs)
  still exposes `XP = [[Complex Double]]` with unchecked dimensions. `xpAdd`
  and `xpApprox` use `zipWith`, so malformed or mismatched crossed-product
  values can silently truncate; `xpMul`/`xpAdjoint` can crash via `!!`. That
  left Theorem II-C coverage shape-safe only for the generators, not the
  public API — the round-1 `Matrix` treatment was never applied to `XP`.

- **Low** — [Properties.hs:28](/Users/mlong/Documents/Development/topological-phases-of-matter/src/positivity-cstar-norms/Properties.hs)
  still said the eigenvalue and Cholesky positivity tests "agree" as a
  closed positivity condition. The implementation correctly tests
  positive-definiteness away from the singular boundary, but the module
  summary had not been updated to match the newer PSD-vs-PD split introduced
  in round 1's fixes.

Verified: full source typechecks with GHC 9.10.1 using `-fno-code -Wall
-Wextra -Werror`.

VERDICT: NEEDS_FIX
