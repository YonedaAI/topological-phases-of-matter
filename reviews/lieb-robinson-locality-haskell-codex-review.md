---
reviewer: codex (OpenAI, gpt-5.5, reasoning effort xhigh)
type: haskell
topic: lieb-robinson-locality
round: 3
date: 2026-07-15T01:35:57Z
---

# Codex Haskell review — round 3 (final) — lieb-robinson-locality

Re-review of `src/lieb-robinson-locality/{FFunction,LinAlg,Ising,Properties,Proofs,Main,
Test}.hs` and `.cabal` after the round-2 fix pass (the `foldl'`/`-Wdodgy-imports` resolution
and the stale `Proofs.hs` header paragraph).

## Verdict section

**Findings**: No remaining issues found.

Verified:

- `LinAlg.hs:37` imports only `Data.List (transpose)`; `foldl'` resolves through the
  project's GHC 9.14.1/base-4.22 Prelude path, with the base version boundary documented at
  the import site.
- `Proofs.hs:25` now describes the round-1 citation mismatch in the past tense, as a resolved
  historical note rather than a live discrepancy.
- The built GHC 9.14.1 artifacts run clean: the test binary exits 0 with QuickCheck 8/8 and
  proofs 12/12; `lr-demo` exits 0 with `v_fit = 2.564`, `v_up = 31.551`, velocity sanity OK,
  and the Theorem 3.1 pointwise bound OK.
- Coverage vs. Theorems I-A/I-B/I-C is stated honestly in `Proofs.hs`'s coverage-matrix
  comment: finite/computational pieces are checked, and condensed/profinite/infinite-volume
  claims are explicitly not overclaimed as executable proof obligations.

(The reviewer's own sandbox was read-only for this round and did not rerun a clean rebuild
itself, relying on artifact mtimes and the recorded GHC 9.14.1/base-4.22 Cabal plan instead;
the independent full clean rebuild and run reported below was performed separately, on the
project's own toolchain, as the final-verification step of this same fix cycle.)

VERDICT: PASS

## Fix-cycle summary (rounds 1–3)

- **Round 1** (`lieb-robinson-locality-haskell-codex-review-round-1.md`): 12 findings (4 High,
  7 Medium, 1 Low) → NEEDS_FIX. All 12 addressed: missing `foldl'` import; the "analytic LR
  upper bound" rerouted through `analyticVelocity`/`tfimFnormAt` with a genuine
  Proposition 3.2 computation (changes the printed `v_up` from 5.437 to 31.551 — confirmed
  with the paper-owning team lead that no paper text quotes either number, so no paper edit
  was needed); `x = 0` excluded from the Theorem-3.1-relevant front-position fit, plus a new
  pointwise Theorem 3.1 check against the simulated data; a genuine `Z^d` lattice enumeration
  replacing a 1D check that had been silently reused for `d = 2, 3`; a separation-parameterized
  convolution test; an honestly-named sup-of-ratios property plus a new real interaction-based
  F-norm property; an I-A/I-B/I-C coverage matrix plus a new uniform-velocity-over-a-parameter-
  box check; corrected paper citations throughout (reweight = Lemma 2.3, F-norm =
  Definition 2.5, velocity = Proposition 3.2, TFIM = Example 3.6/Section 8); an opaque
  `FFunction` type with clamping smart constructors; matrix well-formedness checking plus
  `siteOp`/`tfimH` guards against non-positive chain lengths; an `opNorm` convergence
  certificate; and a separate lightweight `Test.hs` test-suite driver (the suggested `library`
  stanza caused a real `-Wmissing-home-modules` build failure under this project's flat
  source layout and was reverted as a documented, scoped exception).
- **Round 2**: 2 findings → NEEDS_FIX. `-Wdodgy-imports` on `import Prelude hiding (foldl')`
  (legitimate on this project's toolchain, where Prelude already re-exports `foldl'`, but
  dodgy on the reviewer's older one, where it does not) resolved empirically by dropping the
  `hiding` clause and the explicit `Data.List (foldl')` import entirely, documented with a
  comment; the now-stale `Proofs.hs` header paragraph about the citation mismatch rewritten in
  the past tense.
- **Round 3**: PASS, no remaining issues.

VERDICT: PASS
