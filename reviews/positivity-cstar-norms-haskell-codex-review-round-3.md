---
reviewer: codex (gpt-5.5)
type: haskell
paper: positivity-cstar-norms
round: 3
final_round: 3
date: 2026-07-14
sandbox: read-only
---

# Codex Haskell review — round 3 (final)

Reviewing the round-2 fix pass (shape-safe `CrossedProduct.XP` mirroring
`Core.Matrix`'s round-1 treatment; PD-vs-PSD wording fix in `Properties.hs`).

## Findings

None. Zero blocking issues.

Reviewer's own words: "`XP` is abstract and shape-carrying; construction goes
through `mkXP`/`xpUnsafe`, and the crossed-product operations now check
shapes before indexing. `xpApprox` rejects mismatched shapes, and `includeXP`
checks source level. The PD-vs-PSD distinction is now explicit in
`Properties.hs`, `Proofs.hs`, and `Core.hs`, with boundary coverage via
`diag(1,0)`."

"The property/proof labels are honest: II-A is covered only by finite
matrix/state-space witnesses, II-B is explicitly out of executable scope, and
II-C is represented by finite crossed-product algebra/functoriality checks."

The reviewer's own sandbox could not re-run `cabal test`/`cabal run` (read-only
workspace, local Cabal version mismatched against the package's stated
`cabal-version`), so the verdict rests on source-level review; this agent
independently re-ran a full clean `cabal build` + `cabal run` + `cabal test`
+ `cabal clean` after this round with a working GHC 9.14.1/cabal 3.16.1.0
toolchain and confirmed: `-Wall -Wextra -Werror` clean, exit 0, 15/15
QuickCheck properties, 18/18 deterministic checks, `cabal test` PASS.

VERDICT: PASS
