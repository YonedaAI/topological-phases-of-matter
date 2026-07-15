---
reviewer: codex (gpt-5.5, model_reasoning_effort=xhigh)
type: haskell
paper: positivity-cstar-norms
rounds: 3
final_round: 3
date: 2026-07-14
---

# Codex Haskell review — canonical record

Three rounds of external Codex review (`codex exec -m gpt-5.5 -c
'model_reasoning_effort="xhigh"' --sandbox read-only`) of
`src/positivity-cstar-norms/` (Core, GNS, CrossedProduct, Properties, Proofs,
Main): type safety, QuickCheck property correctness, equational proof
soundness, coverage of the paper's theorems (II-A/II-B/II-C), idiomatic style.

## Round 1 — VERDICT: NEEDS_FIX (10 findings, all fixed)

1. `Matrix = [[Complex Double]]` had no shape safety (`mmul`, `mtrace`,
   `setEntry`, `gnsRepresent` could silently truncate via `zipWith` or crash
   via `!!`). Fixed: `Matrix` is now a checked, dimension-carrying type
   (`mkMatrix`/`fromRowsUnsafe` constructors; `mmulEither`/`addEither`/
   `subEither` total cores; loud-error convenience wrappers).
2. `approxEqMat` ignored shape mismatches, weakening `isHermitian`. Fixed:
   shape checked before entrywise comparison.
3. Cholesky (positive-DEFINITE only) was conflated with the paper's closed
   positive-SEMIDEFINITE cone `A_+`. Fixed: `posCheck` relabeled to
   definiteness explicitly; new `semidefCheck` tests `A_+` via `isPositiveEig`
   including the `diag(1,0)` boundary case (positive but singular).
4. GNS's Haddock and `Main.hs`'s demo falsely reported `n^2` as *the* GNS
   Hilbert-space dimension (false for non-faithful, e.g. pure, states). Fixed:
   added `GNS.gnsRank`, computing the true dimension `rank(Gram)` from its
   spectrum; verified `rank = n^2 = 4` on a faithful state and `rank = 2` (not
   4) on a pure state; `Main.hs`'s demo now shows both counts side by side.
   Confirmed the paper itself never echoes this figure (grepped for "n^2",
   "GNS Hilbert", "Hilbert space dim" — zero matches), so no paper edit needed.
5. `Proofs.hs` never addressed Theorem II-B (Aoki). Fixed: added an explicit
   module-doc note stating II-B is out of executable scope by design (a
   condensed/solid K-theory statement with no finite computational shadow).
6. No randomized C*-identity property. Fixed: added `prop_cstarIdentity`.
7. Missing state-space coverage. Fixed: added `prop_mkDensityValid`,
   `prop_stateNormalized` (phi(1)=1), `prop_statePositiveOnSquares`
   (phi(a*a)>=0), `prop_gnsGramPSD`, plus `prop_starSquarePositive`.
8. Deterministic checks not labeled as finite sanity checks. Fixed: module
   doc now states this explicitly and spells out the mirrored equation per
   check.
9. No Cabal test-suite target. Fixed: added a `test-suite properties` stanza
   (mirrors the existing sibling-topic convention); `cabal test` passes.
10. Loose dependency bounds; suggested explicit `foldl'` import. Investigated
    and fixed correctly rather than literally: on the actual toolchain (GHC
    9.14.1/base-4.22) `foldl'` is already re-exported by Prelude, so an
    explicit import is *redundant* and fails under `-Werror`. Tightened
    `base >=4.20 && <5` (the version that introduced the re-export) and
    `QuickCheck >=2.14 && <2.19` instead, with a code comment explaining why.

## Round 2 — VERDICT: NEEDS_FIX (2 findings, all fixed)

1. Medium: `CrossedProduct.hs`'s `XP` type had not received the round-1
   treatment (`xpAdd`/`xpApprox` could silently truncate; `xpMul`/`xpAdjoint`
   could crash via `!!`). Fixed: mirrored round 1 exactly — `XP` is now a
   checked, shape-carrying type (`mkXP`/`xpUnsafe`; `xpAddEither`/
   `xpMulEither`/`xpAdjointEither` total cores; loud-error wrappers);
   `includeXP` also given a shape guard proactively.
2. Low: `Properties.hs`'s module doc still described the eigenvalue/Cholesky
   agreement as testing the general closed positivity condition. Fixed:
   reworded to state the PD-vs-PSD split explicitly.

## Round 3 — VERDICT: PASS

No blocking issues. Reviewer confirmed: `XP` is abstract and shape-carrying
with checked construction and shape-checked operations; the PD-vs-PSD
distinction is explicit across `Core.hs`/`Properties.hs`/`Proofs.hs` with
`diag(1,0)` boundary coverage; the II-A/II-B/II-C labeling is honest (II-A via
finite matrix/state-space witnesses, II-B explicitly out of executable scope,
II-C via finite crossed-product algebra and functoriality checks).

Independently re-verified after round 3 with a working toolchain (GHC
9.14.1, cabal 3.16.1.0): full clean `cabal build` + `cabal run` + `cabal test`
+ `cabal clean`, all green — `-Wall -Wextra -Werror` clean, exit 0, 15/15
QuickCheck properties, 18/18 deterministic checks, `cabal test` PASS.

VERDICT: PASS
