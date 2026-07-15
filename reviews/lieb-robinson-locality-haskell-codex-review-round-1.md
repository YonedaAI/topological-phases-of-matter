---
reviewer: codex (OpenAI, gpt-5.5, reasoning effort xhigh)
type: haskell
topic: lieb-robinson-locality
round: 1
date: 2026-07-15T00:46:45Z
---

# Codex Haskell review — round 1 — lieb-robinson-locality

Reviewed: `src/lieb-robinson-locality/{FFunction,LinAlg,Ising,Properties,Proofs,Main}.hs` and
`lieb-robinson-locality.cabal`, for type safety, QuickCheck property correctness,
equational-proof soundness (`Proofs.hs`), missing coverage vs the paper's Theorems
I-A/I-B/I-C and Lemma 2.4, and idiomatic style.

## Findings

- **High**: `LinAlg.hs:65` uses `foldl'` but `LinAlg.hs:35` imports only `transpose`. Fresh GHC
  reports `Variable not in scope: foldl'`. Fix: `import Data.List (foldl', transpose)`.

- **High**: `Main.hs:78` calls `2 * exp 1 * max J h` an "analytic LR upper bound," but the
  paper's velocity is `v = 2 B_a C_{F_a} / a` in `prop:velocity` / I-C. Fix: compute `B_a`
  from the TFIM `F_a`-norm, compute `C_{F_a}`, call `analyticVelocity`, and test the pointwise
  LR inequality for disjoint supports.

- **High**: `Ising.hs:64` includes `x = 0` in the commutator cone, but the LR theorem is
  stated for disjoint `X,Y`. `Main.hs:93` then uses that row to fit the front. Fix: exclude
  `x=0` from LR checks or label it as non-LR diagnostic only.

- **High**: `Proofs.hs:168` claims Lemma 2.4 coverage for `Z^d`, but it uses the 1D truncation
  functions `FFunction.hs:62` and `FFunction.hs:67`, even for `d = 2,3`, and only separation
  `1`. Fix: implement actual `Z^d` `l1` shell/truncated convolution over multiple separations,
  or restrict the proof to a clearly named 1D sanity check.

- **Medium**: `Properties.hs:54` tests `C_{F_a} <= C_F` only through `convFTrunc` at
  separation `1`, not the supremum in Definition 2.2. Fix: parameterize convolution by
  separation and test/sup over a bounded set of separations.

- **Medium**: `Properties.hs:62` describes an `F`-norm property, but only tests a generic
  `sup_i a_i/w_i` list inequality, not interactions, supports, or operator norms from
  Definition 2.5. Fix: either rename it as an algebraic helper property or add a finite-chain
  interaction model and test the actual `F`-norm.

- **Medium**: I-A/I-B/I-C coverage is missing or overstated. `Proofs.hs:286` only checks
  monotonicity of the Lipschitz constant, not I-A's infinite-volume dynamics; nothing models
  I-B's condensed morphism or I-C's profinite family/uniform bound. Fix: add an explicit
  coverage matrix and tests for finite-volume approximants, parameter-family uniform
  velocities, and mark true analytic/condensed obligations as non-computational if they remain
  out of scope.

- **Medium**: stale paper citations appear in public comments/output: `FFunction.hs:11`,
  `Properties.hs:42`, `Ising.hs:9`, `Main.hs:64`, and `.cabal:6`. Fix: reweighting is Lemma
  2.3, polynomial `Z^d` is Lemma 2.4, interaction norm is Definition 2.5, velocity is
  Proposition 3.2, TFIM is Example 3.6; prefer label names in comments.

- **Medium**: `FFunction.hs:30` exports an unconstrained constructor, and `FFunction.hs:50` /
  `FFunction.hs:76` accept invalid `a <= 0` cases. Fix: make `FFunction` opaque and use smart
  constructors/newtypes for `Positive`, `NonNegative`, and positive dimension.

- **Medium**: matrix operations are not type safe. `LinAlg.hs:40`, `LinAlg.hs:52`, and
  `LinAlg.hs:68` allow ragged/mismatched matrices with silent truncation; `Ising.hs:43` and
  `Ising.hs:48` use partial `foldr1`. Fix: introduce a dimension-checked `Matrix` type and
  return `Either`/`Maybe` for invalid dimensions/sites.

- **Medium**: `LinAlg.hs:113` computes `opNorm` by fixed power iteration, which can
  underestimate the true norm; `LinAlg.hs:89` uses a fixed Taylor cutoff for `expm` with no
  error bound. Fix: use a certified upper bound for theorem checks, or an eigensolver/SVD with
  residual checks.

- **Low**: `.cabal:18` and `.cabal:31` duplicate modules between executable and test-suite and
  use `Main.hs` as the test driver. Fix: add a `library` stanza and a separate lightweight
  test main.

Existing prebuilt `lr-demo` and `properties` binaries exit successfully, but that does not
clear the source/build issues above; fresh GHC probing was blocked by the read-only sandbox
after confirming `foldl'` is not in scope.

VERDICT: NEEDS_FIX

## Fixes applied (round 1 → round 2)

- **High / foldl'**: `LinAlg.hs` now has `import Prelude hiding (foldl')` plus
  `import Data.List (foldl', transpose)` — explicit and portable, and non-redundant on this
  toolchain (whose `Prelude` already re-exports `foldl'`, confirmed by a `-Wunused-imports`
  hit when the `hiding` clause was first omitted).
- **High / analytic LR bound**: `Main.hs`'s `v_up` now calls `Proofs.analyticUpperBoundTFIM`,
  which computes the TFIM `F_a`-norm (`tfimFnormAt`, Example 3.6) and `C_{F_a}`
  (`FFunction.convFTrunc`) and calls `analyticVelocity`, numerically optimized over the
  reweighting parameter `a` — a genuine `Proposition 3.2` computation, not a disconnected
  formula. **This changes the printed `v_up` from 5.437 to 31.551** (`v_fit = 2.564` is
  unchanged; the sanity check `0 <= v_fit <= v_up` still holds, now with more headroom). A
  pointwise Theorem 3.1 check (`c(x,t) <=` the theorem's RHS, for disjoint supports `x >= 1`)
  was added and passes at every simulated point.
- **High / x=0 in the cone**: `Main.hs`'s front-position fit now filters `x >= 1` before
  calling `frontPosition` (`X = Y = {0}` are not disjoint, so Theorem 3.1 does not apply
  there); the full row (including `x=0`) is still printed for diagnostic display. `v_fit`
  is numerically unchanged for this demo's parameters.
- **High / Lemma 2.4 Z^d overclaim**: `Proofs.hs` now enumerates genuine `Z^d` lattice points
  (`zdBall`/`normZdTrunc`/`convZdTruncAt`) for `d = 1, 2, 3` at two separations each, replacing
  the 1D-only `normFTrunc`/`convFTrunc` that were previously reused unchanged regardless of
  `d`.
- **Medium / separation-parameterized conv test**: `FFunction.hs` gained `convFTruncAt`
  (separation-parameterized; `convFTrunc` is now its `m=1` case), and
  `Properties.prop_reweightConv` tests the sup over seven separations.
- **Medium / honest F-norm property naming**: `Properties.prop_fnormSubadditive`'s docstring
  now says plainly it is an algebraic sup-of-ratios helper, not yet an interaction; a new
  `Properties.prop_tfimFnormRandom` tests the actual Definition 2.5 F-norm on a finite-chain
  TFIM interaction with random couplings.
- **Medium / I-A/I-B/I-C coverage**: `Proofs.hs` now has an explicit coverage-matrix comment
  enumerating each theorem's sub-claims as COMPUTATIONAL or NOT COMPUTATIONAL (with a reason),
  plus a new `proof_uniformOverParameterBox` exercising I-C's one computational piece — the
  velocity staying bounded over a compact `(J,h)` box.
- **Medium / stale citations**: all cited locations (and others found by grep) now read Lemma
  2.3 (reweight), Lemma 2.4 (`Z^d`), Definition 2.5 (interaction/F-norm), Proposition 2.6 (`BF`
  Banach space), Proposition 3.2 (velocity), Example 3.6 / Section 8 (TFIM). These corrected
  numbers were counted directly and exhaustively from the paper's `\section` markers and
  shared `[theorem]` counter, not estimated.
- **Medium / FFunction smart constructors**: `FFunction` is now an opaque type (constructor
  not exported); `powerLaw`, `exponential`, `reweight` clamp invalid parameters (`eps <= 0`,
  `theta <= 0`, `a < 0`, `d < 0`) to the nearest valid value instead of accepting them.
- **Medium / matrix type safety**: given the size and numerical sensitivity of a full
  dimension-indexed `Matrix` rewrite, `LinAlg.isWellFormedMatrix` was added (checks
  rectangularity/squareness) plus documentation of the precondition on `Matrix`/`mmul`/`addM`/
  `subM`; `Proofs.proof_matricesWellFormed` checks it holds for the demo's actual matrices.
  `Ising.siteOp`/`tfimH` now guard `n <= 0` with a clear error instead of a bare `foldr1`
  crash.
- **Medium / opNorm certificate**: `LinAlg.opNormConverged` (additive; does not change
  `opNorm` itself) re-runs the power iteration one step further and compares, as a residual
  convergence check; `Proofs.proof_opNormCertified` exercises it. `expm`'s fixed Taylor cutoff
  is now documented as an uncertified (magnitude-argument) truncation.
- **Low / cabal duplication**: a `library` stanza sharing `hs-source-dirs` with the executable
  caused a `-Wmissing-home-modules` build failure (cabal tried to recompile the library's
  modules again for the executable) unless the executable's sources live in a separate
  directory — a larger file-layout change than this Low finding warrants, so it was reverted.
  `Test.hs` (a lightweight test-suite entry point running only `Properties`/`Proofs`, without
  the full demo) was kept; the module list is still duplicated per stanza.

VERDICT: NEEDS_FIX (round 1) → fixes applied, see round 2 for re-review.
