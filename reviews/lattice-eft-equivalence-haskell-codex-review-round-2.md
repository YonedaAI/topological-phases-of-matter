---
reviewer: codex (OpenAI, gpt-5.5, reasoning effort xhigh)
type: haskell
paper: lattice-eft-equivalence
round: 2
date: 2026-07-14T21:58:00Z
---

Codex re-review of `src/lattice-eft-equivalence/` after the round-1 fix pass, run
read-only via:

```
codex exec -m gpt-5.5 -c 'model_reasoning_effort="xhigh"' --sandbox read-only
```

Prompt summarized the round-1 fixes applied (CMonoid constructor hidden + eqG
documented as bounded witness-search; scale retyped Integer->Natural;
freeCMonoid stores+validates generators via respectsAlphabet; mkHom certified
constructor with rejection tests; stale Haddocks fixed; 8 new toy-monoid
QuickCheck properties; full 10x8 Table 1 regression; suite 31/31 properties,
18/18 proof checks, -Wall -Wextra -Werror clean) and asked Codex to verify the
fixes and check fresh for remaining defects.

Codex confirmed all round-1 fixes are correctly implemented and found no fresh
defect in the bounded `eqG` algorithm for the two certified monoids. It could
not independently execute the suite in its own sandbox (`cabal test` failed
with a permission error there, and the sandbox's visible `ghc` is 8.4.2, not
the `ghc-9.10.1` pinned by `cabal.project`) — this is an environmental
limitation of the read-only review sandbox, not a defect; the suite has been
independently rebuilt and run clean by this agent (see round-1 file and
`coordination/board.md`).

## Findings

1. **Medium — `Monoid.hs:91` — Haddock overclaims `scale`'s type safety.**
   `Natural` prevents negative exponents from being *constructed*, but
   `scale (-1) x` is not a compile-time type error: it typechecks (numeric
   literals are polymorphic) and fails at *runtime* via `Natural`'s `Num`
   instance (an arithmetic underflow exception), not at compile time. The
   implementation is safer than plain `Integer`, but the comment's "type
   error" wording is inaccurate. Fix: reword to describe a runtime rejection
   via `Natural` underflow, not a type error.

2. **Low — `Properties.hs:66` (`prop_respectsOwnAlphabet`) — only tests the
   positive path.** `gen` still allows building elements with out-of-alphabet
   generator names, and `respectsAlphabet`/validation is opt-in, so the
   property only confirming honestly-built elements pass leaves the negative
   case unexercised. Fix: add a negative regression, e.g.
   `not (respectsAlphabet (freeCMonoid ["a"]) (gen "b"))`.

VERDICT: NEEDS_FIX
