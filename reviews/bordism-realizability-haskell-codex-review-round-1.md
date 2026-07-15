---
reviewer: codex (gpt-5.5, xhigh)
type: haskell
topic: bordism-realizability
round: 1
date: 2026-07-15T00:29:44Z
---

**Findings**

- High: [Kitaev.hs:64](/Users/mlong/Documents/Development/topological-phases-of-matter/src/bordism-realizability/Kitaev.hs:64), [Kitaev.hs:80](/Users/mlong/Documents/Development/topological-phases-of-matter/src/bordism-realizability/Kitaev.hs:80), [Kitaev.hs:83](/Users/mlong/Documents/Development/topological-phases-of-matter/src/bordism-realizability/Kitaev.hs:83) compute invariants on points where the paper's proposition does not apply. `windingNumber` and `majoranaNumber` return plain `Int` even when `Delta == 0` or the bulk is gapless, while Prop. kitaev is only for `Delta_p /= 0` and off `|mu|=2|t|` ([paper:634](/Users/mlong/Documents/Development/topological-phases-of-matter/papers/latex/bordism-realizability.tex:634)). Fix with a `GappedKitaevParams` smart constructor or `Either Gapless Int`, and reject `Delta ~= 0`, discriminant points, and `Delta=0, |mu|<2|t|`.

- High: [Stabilizer.hs:49](/Users/mlong/Documents/Development/topological-phases-of-matter/src/bordism-realizability/Stabilizer.hs:49), [Stabilizer.hs:53](/Users/mlong/Documents/Development/topological-phases-of-matter/src/bordism-realizability/Stabilizer.hs:53), [Stabilizer.hs:64](/Users/mlong/Documents/Development/topological-phases-of-matter/src/bordism-realizability/Stabilizer.hs:64), [Stabilizer.hs:94](/Users/mlong/Documents/Development/topological-phases-of-matter/src/bordism-realizability/Stabilizer.hs:94) are not type-safe: out-of-range `single` indices silently produce identity-like operators, and mismatched Pauli lengths are truncated by `zipWith`. Fix by validating `0 <= s < n`, replacing partial/error APIs with `Maybe`/`Either`, and using a length-checked vector representation or explicit length checks in `multPauli`/`anticommutes`.

- High: [Stabilizer.hs:182](/Users/mlong/Documents/Development/topological-phases-of-matter/src/bordism-realizability/Stabilizer.hs:182) does not enforce the paper preconditions `a < b`, `b-a` even, and valid endpoints ([paper:493](/Users/mlong/Documents/Development/topological-phases-of-matter/papers/latex/bordism-realizability.tex:493)). Invalid windows can still return an operator and make properties pass for meaningless inputs. Add a `StringWindow` smart constructor and have `stringOp`, `stringOrder`, and `stringOrderRotated` consume only validated windows.

- Medium: [Proofs.hs:48](/Users/mlong/Documents/Development/topological-phases-of-matter/src/bordism-realizability/Proofs.hs:48) relies on exact `Double` equality for `cos pi`, and [Kitaev.hs:81](/Users/mlong/Documents/Development/topological-phases-of-matter/src/bordism-realizability/Kitaev.hs:81) derives the Majorana endpoint signs through `dVector p pi`. The paper's endpoint identities are algebraic ([paper:660](/Users/mlong/Documents/Development/topological-phases-of-matter/papers/latex/bordism-realizability.tex:660)); don't make them depend on libm behavior. Compute `d_z(0) = -2*t-mu` and `d_z(pi) = 2*t-mu` directly for `majoranaNumber` and proof checks.

- Medium: [Proofs.hs:160](/Users/mlong/Documents/Development/topological-phases-of-matter/src/bordism-realizability/Proofs.hs:160) calls finite examples "proof checks." They do not establish the universal cluster claims in Prop. cluster, especially all `a,b`, all sites `j`, and all `theta` ([paper:500](/Users/mlong/Documents/Development/topological-phases-of-matter/papers/latex/bordism-realizability.tex:500), [paper:526](/Users/mlong/Documents/Development/topological-phases-of-matter/papers/latex/bordism-realizability.tex:526), [paper:529](/Users/mlong/Documents/Development/topological-phases-of-matter/papers/latex/bordism-realizability.tex:529)). Either rename them to deterministic examples or add universally quantified QuickCheck/exhaustive finite-window checks. Also add explicit Haddock citations to `papers/latex/bordism-realizability.tex:493-537` and `:634-663`.

- Medium: [Properties.hs:85](/Users/mlong/Documents/Development/topological-phases-of-matter/src/bordism-realizability/Properties.hs:85) checks no local order only at site `a`; the paper says every `Z_j` and `X_j` expectation vanishes. Fix with `all (\j -> expectation gens (single n 'Z' j) == 0 && expectation gens (single n 'X' j) == 0) [0..n-1]`.

- Medium: [Properties.hs:27](/Users/mlong/Documents/Development/topological-phases-of-matter/src/bordism-realizability/Properties.hs:27) samples only positive `t` and positive `Delta`; [Properties.hs:48](/Users/mlong/Documents/Development/topological-phases-of-matter/src/bordism-realizability/Properties.hs:48) samples only small, fixed-shape windows. Add negative `t`, negative `Delta`, larger/slack `n`, boundary-adjacent windows, and invalid-window rejection tests.

- Medium: [Kitaev.hs:117](/Users/mlong/Documents/Development/topological-phases-of-matter/src/bordism-realizability/Kitaev.hs:117) scans only `mu in [0,4]` and ignores invalid `Delta`, while [Properties.hs:38](/Users/mlong/Documents/Development/topological-phases-of-matter/src/bordism-realizability/Properties.hs:38) restricts `t <= 2`, exactly hiding the scan limit. Fix by bracketing around `2*abs t`, exposing the search range, or returning the analytic boundary separately from numerical detection.

- Low: [Kitaev.hs:48](/Users/mlong/Documents/Development/topological-phases-of-matter/src/bordism-realizability/Kitaev.hs:48) labels a 400-point grid estimate as `bulkGap`. Either call it `bulkGapEstimate` or compute the exact minimum of the quadratic in `cos k`.

- Low: [bordism-realizability.cabal:16](/Users/mlong/Documents/Development/topological-phases-of-matter/src/bordism-realizability/bordism-realizability.cabal:16) duplicates all modules between executable and test suite and leaves `QuickCheck` unbounded. More idiomatic: define a library stanza, keep `Properties` in the test suite unless the executable intentionally runs tests, and add practical bounds such as `QuickCheck >= 2.14 && < 2.17`.

Verification: I ran the existing built executable; it reports `7/7` QuickCheck properties and `19/19` deterministic checks passing. The issues above are coverage/domain/soundness problems that the current tests do not catch.

VERDICT: NEEDS_FIX
