---
reviewer: codex (gpt-5.5, xhigh)
type: haskell
topic: bordism-realizability
round: 2
date: 2026-07-15T02:44:03Z
---

**Findings**

Medium: [Kitaev.hs](/Users/mlong/Documents/Development/topological-phases-of-matter/src/bordism-realizability/Kitaev.hs:158) conflates "in the proposition domain" with "physically gapped." `isGapped` intentionally rejects all `Delta ~= 0`, but [phaseLabel](/Users/mlong/Documents/Development/topological-phases-of-matter/src/bordism-realizability/Kitaev.hs:193) turns every `not isGapped` point into `"gapless"`. For `KitaevParams 3 1 0`, the closed-form [bulkGap](/Users/mlong/Documents/Development/topological-phases-of-matter/src/bordism-realizability/Kitaev.hs:75) is `2.0`, yet the label is `"gapless"`. That is a false phase classification for the normal-chain `Delta = 0, |mu| > 2|t|` region. Separate "prop-domain" from "bulk-gapped," or label excluded-but-gapped points as outside-domain/trivial-normal instead of gapless.

The stabilizer abstraction, window validation, Pauli phase algebra, string order checks, and Majorana endpoint computation look sound. I ran the existing built executable: exit 0, 10/10 QuickCheck properties and 21/21 deterministic checks passed. Cabal's cached plan shows `QuickCheck-2.18.0.0`; I could not do fresh `ghc -e`/rebuild work because this sandbox blocks compiler temp/cache writes.

VERDICT: NEEDS_FIX

---

**Fix applied:** `phaseLabel` in `Kitaev.hs` now reports the physical truth of
whether the bulk gap closes (`bulkGap p < gapTolerance`), not merely whether
`isGapped` (Prop. kitaev's narrower winding-number domain hypothesis) holds.
`isGapped` itself is unchanged and still gates `mkGapped` /
`windingNumberG` / `majoranaNumberG` exactly as before. Three cases are now
distinguished: `bulkGap` closes -> `"gapless"`; `bulkGap` open and in the
proposition's domain -> `"topological"`/`"trivial"` (via `isTopological`);
`bulkGap` open but outside the domain (i.e. `Delta_p ~= 0` away from the
discriminant) -> `"trivial-normal (outside invariant domain)"`, no longer
silently mislabelled `"gapless"`. Added `gappedOutsideDomainCheck` in
`Proofs.hs`, pinning `KitaevParams 3 1 0` (`Delta_p = 0`, `|mu| = 3 > 2|t| =
2`) to `bulkGap = 2.0`, `not isGapped`, and
`phaseLabel = "trivial-normal (outside invariant domain)"`. Rebuilt clean
(`-Wall -Wextra -Werror`, 0 warnings); `cabal run` and `cabal test` both exit
0; the published demo sweep (Demonstration 1, `t=1, Delta=1`, none of whose
`mu` values are `Delta=0` or exactly on the discriminant) is byte-identical
to before the fix; 10/10 QuickCheck properties; 22/22 deterministic/exhaustive
checks (21 + the new pinned check).
