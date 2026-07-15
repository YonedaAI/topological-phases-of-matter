# Topological Phases of Matter in the Condensed-Mathematics Paradigm

A six-paper research program treating quantum phases as components of a **condensed
moduli stack of uniformly gapped local Hamiltonians** (in the sense of Clausen–Scholze
condensed mathematics), with phase transitions as crossings of a gapless discriminant
locus carrying a relative-cohomological charge.

**Website:** https://topological-phases-of-matter-pi.vercel.app

The program in one sequence:

```
        local quantum interactions
                   |
                   v
   condensed moduli stack of Hamiltonians        Ham_{d,G}
                   |
                   v
        uniformly gapped substack                Gap_{d,G}
                   |
                   v
      stabilized phase infinity-groupoid         Phase_{d,G} = (Gap[W^-1])^st
                   |
                   v
     invertible condensed phase spectrum         IP^cond_{d,G}
```

with the dictionary: pi_0 = phases · pi_1 = adiabatic pumps and phase automorphisms ·
pi_n = higher families and defects · Sigma = gapless transition locus ·
E^{q+1}(B, B\Sigma) = relative charge of a transition.

Each paper is a module; composition of the modules is the program (Part VI). The five
analytic problems the prospectus demands — locality, positivity, the thermodynamic gap,
the lattice↔EFT passage, and realizability — each own a paper. The stance throughout is
a **rigorous program**: theorems only where present-day mathematics proves them,
numbered Conjectures everywhere else, with two hard walls never crossed (Cubitt–
Pérez-García–Wolf undecidability of the spectral gap; the Kapustin–Fidkowski electric
and Kapustin–Spodyneiko thermal no-gos).

## Papers

| # | Paper | Pages | Category | Read | PDF |
|---|-------|-------|----------|------|-----|
| I | Condensed Locality: Lieb–Robinson Estimates and Quasi-Local Dynamics on the Moduli Stack of Hamiltonians | 21 | math-ph | [HTML](https://topological-phases-of-matter-pi.vercel.app/papers/lieb-robinson-locality/) | [PDF](papers/pdf/lieb-robinson-locality.pdf) |
| II | Positivity, C*-Norms, and Condensed State Spaces of Quasi-Local Algebras | 21 | math.OA | [HTML](https://topological-phases-of-matter-pi.vercel.app/papers/positivity-cstar-norms/) | [PDF](papers/pdf/positivity-cstar-norms.pdf) |
| III | The Uniformly Gapped Substack: Existence and Stability of the Thermodynamic Spectral Gap | 26 | math-ph | [HTML](https://topological-phases-of-matter-pi.vercel.app/papers/spectral-gap-stability/) | [PDF](papers/pdf/spectral-gap-stability.pdf) |
| IV | From Lattice Models to Effective Field Theories: Stabilization and the Invertible Condensed Phase Spectrum | 24 | math.AT | [HTML](https://topological-phases-of-matter-pi.vercel.app/papers/lattice-eft-equivalence/) | [PDF](papers/pdf/lattice-eft-equivalence.pdf) |
| V | Physical Realizability of Bordism and Homotopy Classes by Gapped Lattice Systems | 25 | cond-mat.str-el | [HTML](https://topological-phases-of-matter-pi.vercel.app/papers/bordism-realizability/) | [PDF](papers/pdf/bordism-realizability.pdf) |
| VI | Topological Phases of Matter in the Condensed-Mathematics Paradigm: A Modular Research Program | 26 | math-ph | [HTML](https://topological-phases-of-matter-pi.vercel.app/papers/synthesis/) | [PDF](papers/pdf/synthesis.pdf) |

## Machine-checked scaffolding

- **Haskell** (`src/<slug>/`, one suite per Part I–V): 27 modules, 72 QuickCheck
  properties and 198 deterministic/equational checks, all compiled with
  `-Wall -Wextra -Werror` and run to exit 0. Numerics include the TFIM
  Lieb–Robinson light cone, exact-diagonalization gap sweeps exhibiting the
  discriminant at the critical point, the Grothendieck completion of the stacking
  monoid with the tenfold-way Bott table, and the Kitaev-chain invariant flip at
  |mu| = 2|t|.
- **Lean 4** (`lean/`): a mathlib-based library (`CondensedPhases`, 6 modules,
  614 lines) formalizing the framework vocabulary — interactions, uniform gap,
  stacking, phase monoid, Grothendieck group with its universal property — and the
  program's **five central problems as Prop-valued statements**, each doc-comment
  citing its paper. `lake build` clean; zero `sorry`, zero `axiom`; `#print axioms`
  confirms the proof-term graph is sorry-free (27 proven items).

## Review trail

Every paper passed: an iterative external peer-review loop (Gemini 3.1 Pro via the
`agy` CLI) to ACCEPT/MINOR; a codex (GPT-5.5, xhigh) formatting loop to PASS; a
six-role review panel (summary, technical correctness, novelty, reproducibility,
citation, meta) with all blocking findings fixed and re-verified; and cross-cutting
citation and notation audits (57 citation keys source-verified, ~35 externally
re-verified against arXiv/DOI records; canonical symbol table enforced across the
series). The 98 review artifacts live in `reviews/` (62 files) and `reviews/panel/`
(36 JSON verdicts). Coordination logs: `coordination/`.

## Repository layout

```
papers/latex/     LaTeX sources + shared references.bib (verified entries only)
papers/pdf/       compiled PDFs (build of record)
docs/papers/      HTML conversions (resolved citations + cross-references)
src/<slug>/       Haskell verification suites (cabal projects)
lean/             Lean 4 library (lake + mathlib)
website/          Next.js 14 static-export site (deployed to Vercel)
reviews/          full review trail (Gemini, codex, panel JSONs)
coordination/     notation canon, abstracts board, run log, audits
posts/            social post drafts (twitter/linkedin/facebook/bluesky)
images/           300-DPI paper covers
context/          the seed prospectus
```

## Building locally

```bash
# Papers (TeX Live)
cd papers/latex && pdflatex <slug>.tex && bibtex <slug> && pdflatex <slug>.tex && pdflatex <slug>.tex

# Haskell suites (GHC >= 9.10, cabal)
cd src/<slug> && cabal run && cabal test

# Lean library (elan; first build fetches the mathlib cache)
cd lean && lake exe cache get && lake build

# Website (Node >= 20)
cd website && npm install && npm run build   # static export in out/
```

## Author

Matthew Long — The YonedaAI Collaboration, YonedaAI Research Collective, Chicago, IL
matthew@yonedaai.com · https://yonedaai.com

The seed prospectus is `context/source.txt`; the program's honest claim is stated
there and kept throughout: condensed mathematics does not produce a different Chern
number — it offers a single categorical and homological environment in which
continuous families, profinite disorder, analytic completions, operator K-theory,
symmetry, stacking, defects, and phase-transition loci can be treated simultaneously.
