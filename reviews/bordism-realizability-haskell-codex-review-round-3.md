---
reviewer: codex (gpt-5.5, xhigh)
type: haskell
topic: bordism-realizability
round: 3
date: 2026-07-15T02:52:22Z
---

**Findings**

High: [Kitaev.hs](/Users/mlong/Documents/Development/topological-phases-of-matter/src/bordism-realizability/Kitaev.hs:84) can produce `NaN` for mathematically gapless `Delta=0, |mu|<2|t|` points because the quadratic minimum can round slightly negative before `sqrt`. Then [Kitaev.hs](/Users/mlong/Documents/Development/topological-phases-of-matter/src/bordism-realizability/Kitaev.hs:218) treats `NaN < gapTolerance` as false and falls through to `"trivial-normal (outside invariant domain)"`.

Concrete reproducer from the same arithmetic: `KitaevParams (sqrt 3) (sqrt 2) 0` gives `g(x*) ~= -4.44e-16`, so `bulkGap` becomes `NaN`; physically this is the gapless normal-metal subcase because `Delta=0` and `|mu| < 2|t|`. The pinned `KitaevParams 3 1 0` check is good, but coverage still misses this gapless-normal numeric corner. Fix by clamping the squared minimum before `sqrt`, e.g. `sqrt (max 0 (minimum candidates))`, and add a deterministic `phaseLabel` check for an irrational-ish `Delta=0, |mu|<2|t|` point.

I also verified the rest of the requested surface: `gappedOutsideDomainCheck` is present and included in `allChecks`; smart constructors preserve the invariant-domain guard; stabilizer construction remains type-safe via `PauliLetter`, abstract `Pauli`, and `StringWindow`; fresh `ghc -fno-code -Wall -Wextra -Werror` succeeds. Full `cabal run`/`cabal test` are blocked by the read-only sandbox, but the cached binaries are newer than the source and run cleanly: 10/10 QuickCheck and 22/22 deterministic checks.

VERDICT: NEEDS_FIX

---

**Fix applied (post-cap, per pipeline policy — 3-round cap reached):**
`bulkGap` in `Kitaev.hs` now clamps the quadratic minimum to `>= 0` before
`sqrt` — `2 * sqrt (max 0 (minimum candidates))` instead of
`2 * sqrt (minimum candidates)` — so a tiny negative rounding artifact at a
perfect-square root (the `Delta_p = 0` case) can no longer produce `NaN`.
Independently reproduced the bug pre-fix (`KitaevParams (sqrt 3) (sqrt 2) 0`:
`g(x*) = -4.440892098500626e-16`, `bulkGap = NaN`, `phaseLabel =
"trivial-normal (outside invariant domain)"`) and confirmed the fix
(`bulkGap = 0.0`, `isNaN = False`, `phaseLabel = "gapless"`) via a standalone
script before and after the patch. Added `bulkGapNoNaNCheck` in `Proofs.hs`,
pinning exactly this reproducer (`KitaevParams (sqrt 3) (sqrt 2) 0`:
`bulkGap` non-negative and `< 1e-6`, not `NaN`; `phaseLabel = "gapless"`).
Rebuilt clean (`-Wall -Wextra -Werror`, 0 warnings); `cabal run` and
`cabal test` both exit 0; the published Demonstration-1 sweep table (`t=1,
Delta=1`, no `Delta=0` or on-discriminant points) is byte-identical; 10/10
QuickCheck properties; 23/23 deterministic/exhaustive checks (22 + the new
pinned check). Verified with 5 repeated runs, no flakiness.
