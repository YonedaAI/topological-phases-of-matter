---
reviewer: codex (OpenAI, gpt-5.5, reasoning effort xhigh)
type: haskell
topic: lieb-robinson-locality
round: 2
date: 2026-07-15T01:31:19Z
---

# Codex Haskell review — round 2 — lieb-robinson-locality

Re-review of `src/lieb-robinson-locality/{FFunction,LinAlg,Ising,Properties,Proofs,Main,
Test}.hs` and `.cabal` after the round-1 fix pass, checking that each round-1 finding was
actually resolved in the current source (not just claimed). Codex independently confirmed the
prebuilt binaries run clean (`v_up=31.551`, `v_fit=2.564`, 8/8 QuickCheck, 12/12 proofs) and
that the paper citations agree across `FFunction`, `Properties`, `Ising`, and `Main`.

## Findings

1. `LinAlg.hs:36`: current source fails `-Wall -Wextra -Werror` typecheck on the reviewer's
   toolchain. `import Prelude hiding (foldl')` triggers `-Wdodgy-imports` because that
   Prelude does not export `foldl'`, so hiding it hides nothing. Fix: remove that import or
   change it to plain `import Prelude`; `Data.List (foldl', transpose)` already supplies the
   strict fold.

2. `Proofs.hs:25`: the module-header paragraph still describes the round-1 citation mismatch
   (`Lemma 2.4`/`Definition 2.7`/`Proposition 2.9`/`Example 3.9, Section 9`) as a live
   discrepancy, even though those citations were corrected elsewhere in this same fix pass —
   the paragraph itself is now the only stale thing left.

VERDICT: NEEDS_FIX

## Fixes applied (round 2 → round 3)

- **Finding 1**: resolved empirically per the team lead's guidance rather than by inspection
  alone. The reviewer's sandbox GHC/base predates the point where `Prelude` re-exports
  `foldl'` (a `base >= 4.20` / GHC >= 9.10 change), so on that toolchain `hiding (foldl')`
  is genuinely dodgy — nothing to hide. This project's actual toolchain (GHC 9.14.1,
  base-4.22.0.0) already has the re-export, confirmed by a fresh `cabal build` under
  `-Wall -Wextra -Werror` with the `hiding` clause removed entirely: `LinAlg.hs` now imports
  only `Data.Complex (...)` and `Data.List (transpose)` (dropping the explicit `foldl'`
  import too, since it is unused with the `hiding` clause gone) and relies on `foldl'`
  resolving through `Prelude`, with a comment at the import site documenting the base version
  boundary and that this was verified against the actual toolchain, so a future reviewer on
  an older toolchain understands why no explicit import is needed here rather than re-flagging
  it as the round-1 "missing import" bug.
- **Finding 2**: rewritten in the past tense — the paragraph now states plainly that the
  citation mismatch was found in an earlier revision and has since been corrected in the other
  four modules to match this module's recount, rather than describing an open discrepancy.

Full clean rebuild (`rm -rf dist-newstyle`, `cabal build` and `cabal test`) after both fixes:
`-Wall -Wextra -Werror` clean on both `lr-demo` and the `properties` test-suite, both exit 0,
8/8 QuickCheck properties, 12/12 equational proofs, `v_fit = 2.564`, `v_up = 31.551`
(unchanged from round 1 — these two fixes touch only an import and a comment, not any
numerics).

VERDICT: NEEDS_FIX (round 2) → fixes applied, see round 3 for re-review.
