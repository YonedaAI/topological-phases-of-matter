# Canonical Notation — topological-phases-of-matter

**Status:** authoritative. Every paper (Parts I–VI) MUST use these symbols and MUST
copy the LaTeX macro block verbatim into its preamble. Do not silently introduce a
variant glyph for a concept that already has one here; if a paper genuinely needs a new
symbol, add it to this file first (append-only) and note it on `board.md`.

Extracted from `context/source.txt`. Section references below point at that prospectus.

---

## 1. Symbol table

| Symbol | LaTeX macro | Meaning | Source §|
|---|---|---|---|
| $d$ | `d` | spatial dimension | §1 |
| $L$ | `L` | lattice / coarse (proper) metric space of sites | §1 |
| $G$ | `G` | internal or spatial symmetry group | §1 |
| $\underline{G}$ | `\cg{G}` | the associated **condensed** symmetry group | §3 |
| $\mathcal{I}_{d,G}$ | `\Int_{d,G}` | topological space of admissible $G$-symmetric local / quasi-local interactions | §1 |
| $\underline{X}$, $\underline{X}(S)=\mathrm{Cont}(S,X)$ | `\cond{X}` | condensation of a space $X$; value on a profinite set $S$ | §1 |
| $S$ | `S` | a profinite test set (probe object) | §1 |
| $\mathfrak{Ham}_{d,G}$ | `\Ham_{d,G}` | condensed moduli **stack** of $G$-symmetric local/quasi-local Hamiltonians | §2 |
| $\mathrm{gap}(H)$ | `\gapof{H}` | spectral gap above the ground state of $H$ | §2 |
| $\Delta$ | `\gapbound` | uniform lower gap bound ($\Delta>0$) | §2 |
| $\mathfrak{Gap}_{d,G}$ | `\Gap_{d,G}` | **uniformly** gapped substack, $\bigcup_{\Delta>0}\{\,\inf_{s\in S}\mathrm{gap}(H_s)\ge\Delta\,\}$ | §2 |
| $\mathcal{W}$ | `\Weq` | class of gapped adiabatic / quasi-local (finite-depth) equivalences to be inverted | §2 |
| $(-)^{\mathrm{st}}$ | `(-)^{\st}` | stabilization by trivial product-state ancillas | §2 |
| $\mathfrak{Phase}_{d,G}$ | `\Phase_{d,G}` | stabilized phase $\infty$-groupoid $=\bigl(\mathfrak{Gap}_{d,G}[\mathcal{W}^{-1}]\bigr)^{\mathrm{st}}$ | §2 |
| $\mathrm{Shape}(-)$ | `\Shape` | shape / underlying homotopy type of a condensed anima | §2 |
| $\mathrm{Phases}_{d,G}=\pi_0\,\mathrm{Shape}(\mathfrak{Phase}_{d,G})$ | `\Phases_{d,G}` | the ordinary set of phases | §2 |
| $\boxtimes$ | `\boxtimes` | stacking of systems (symmetric-monoidal / $E_\infty$ product on $\mathfrak{Phase}$) | §3 |
| $\mathbf{IP}^{\mathrm{cond}}_{d,G}$ | `\IPcond_{d,G}` | invertible condensed phase **spectrum** (group completion of invertible sector) | §3 |
| $\mathfrak{Phase}_d^{\,h\underline{G}}$ | `\Phase_d^{\hfix{\cg{G}}}` | homotopy fixed points under $\underline{G}$ (symmetric systems) | §3 |
| $[Y/\underline{G}]$ | `\quotstack{Y}{\cg{G}}` | action stack for spatial symmetry ($Y$ = space / lattice / disorder hull) | §3 |
| $B$, $\underline{B}$ | `B`, `\cond{B}` | parameter space of a family (couplings, fields, disorder, b.c.) and its condensation | §4 |
| $f:\underline{B}\to\mathfrak{Ham}_{d,G}$ | `f` | a family of systems | §4 |
| $U_f=\underline{B}\times_{\mathfrak{Ham}_{d,G}}\mathfrak{Gap}_{d,G}$ | `U_f` | gapped locus of the family | §4 |
| $\Sigma_f=\underline{B}\setminus U_f$ | `\Sig_f` | gapless / critical **discriminant** locus | §4 |
| $\nu_f:U_f\to\pi_0(\mathfrak{Phase}_{d,G})$ | `\nu_f` | (locally constant) phase label on the gapped locus | §4 |
| $E$, $\nu\in E^q(U_f)$ | `E` | generalized cohomology theory carrying the invariant; a bulk invariant | §4 |
| $\partial\nu\in E^{q+1}(B,U_f)$ | `\rc` | relative transition charge (obstruction to extending $\nu$ across $\Sigma_f$) | §4 |
| $q(k)=t_1+t_2e^{ik}$ | `q(k)` | SSH off-diagonal function; winding number $\nu$ | §5 |
| $A$, $\underline{A}$, $\underline{A}(S)=C(S,A)$ | `A`, `\cond{A}` | (topological/Banach/$C^*$) observable algebra and its condensation | §6 |
| $K_{\mathrm{op}}$, $K_{\mathrm{alg}}$ | `\Kop`, `\Kalg` | operator (topological) and algebraic $K$-theory | §6 |
| $\mathrm{Solid}(-)$ | `\Solid` | solidification functor; $K_{\mathrm{op}}(A)\simeq\mathrm{Solid}\bigl(K_{\mathrm{alg}}(\underline{A})\bigr)$ | §6 |
| $\Omega=Q^{\mathbb{Z}^d}$ | `\dis` | profinite disorder hull ($Q$ = finite local-configuration set; letter $Q$ blessed series-wide 2026-07-14 to avoid the $F$-function clash — see note below) | §7 |
| $\omega\mapsto H_\omega$ | `\omega` | disordered family = an $\Omega$-point $H\in\mathfrak{Ham}_{d,G}(\Omega)$ | §7 |
| $B_F$ | `\BF` | interaction Banach space for an $F$-function $F$ (locality norm; see Paper I) | Paper I |
| $F$ | `\Ffun` | $F$-function encoding interaction decay (Nachtergaele–Sims–Young) | Paper I |

Notes:
- **"Uniformly" gapped is essential** (§2): a family where each $H_s$ is gapped but
  $\inf_s\mathrm{gap}(H_s)=0$ is NOT a member of $\mathfrak{Gap}$. Papers must never drop the word.
- $\mathcal{W}$ is **part of the definition of the phase problem** (§2). Isomorphism, gapped
  homotopy, stable equivalence, and $K$-theoretic equivalence need not coincide; always
  state which $\mathcal{W}$ is meant.
- $B_F$ / $F$-function notation is the standard locality-norm apparatus (Nachtergaele–Sims–Young,
  arXiv:1810.02428); Paper I fixes the precise convention and the others inherit it.
- Use $\mathfrak{}$ (fraktur) for the moduli stacks, $\mathcal{}$ (calligraphic) for spaces of
  interactions and for $\mathcal{W}$, $\mathbf{}$ (bold) for spectra, $\underline{(-)}$ for
  condensation. Do not mix these up.

---

## 2. LaTeX macro block — COPY VERBATIM into every paper preamble

```latex
% ==== topological-phases-of-matter : canonical macros (v1, 2026-07-14) ====
% Requires amsmath, amssymb, amsfonts (mathfrak, mathbf, mathcal all standard).
\usepackage{amsmath,amssymb,amsfonts}

% --- condensation / probes ---
\newcommand{\cond}[1]{\underline{#1}}          % condensation X |-> \cond{X}
\newcommand{\cg}[1]{\underline{#1}}            % condensed group (alias, for readability)
\newcommand{\Cont}{\operatorname{Cont}}        % Cont(S,X)
\newcommand{\Shape}{\operatorname{Shape}}      % shape / homotopy type

% --- interaction space & locality ---
\newcommand{\Int}{\mathcal{I}}                 % \Int_{d,G} interaction space
\newcommand{\Ffun}{F}                          % F-function (interaction decay)
\newcommand{\BF}{\mathcal{B}_{F}}              % interaction Banach space for F

% --- moduli stacks ---
\newcommand{\Ham}{\mathfrak{Ham}}              % \Ham_{d,G}
\newcommand{\Gap}{\mathfrak{Gap}}              % \Gap_{d,G}
\newcommand{\Phase}{\mathfrak{Phase}}          % \Phase_{d,G}
\newcommand{\Phases}{\operatorname{Phases}}    % \Phases_{d,G} = pi_0 Shape Phase
\newcommand{\Weq}{\mathcal{W}}                 % class of equivalences to invert
\newcommand{\st}{\mathrm{st}}                  % stabilization superscript
\newcommand{\hfix}[1]{h#1}                     % homotopy-fixed-point superscript, e.g. \Phase_d^{\hfix{\cg{G}}}
\newcommand{\quotstack}[2]{[#1/#2]}            % action stack [Y/\cg{G}]

% --- gap ---
\newcommand{\gapof}[1]{\operatorname{gap}(#1)} % gap(H)
\newcommand{\gapbound}{\Delta}                  % uniform gap bound

% --- stacking / spectrum ---
% \boxtimes is built in (stacking product)
\newcommand{\IPcond}{\mathbf{IP}^{\mathrm{cond}}}  % invertible condensed phase spectrum

% --- transitions / discriminant / charge ---
\newcommand{\Sig}{\Sigma}                       % \Sig_f gapless discriminant
\newcommand{\rc}{\partial\nu}                   % relative transition charge in E^{q+1}(B,U_f)

% --- observables & solid K-theory ---
\newcommand{\Kop}{K_{\mathrm{op}}}             % operator / topological K-theory
\newcommand{\Kalg}{K_{\mathrm{alg}}}           % algebraic K-theory
\newcommand{\Solid}{\operatorname{Solid}}      % solidification functor

% --- disorder ---
\newcommand{\dis}{\Omega}                       % disorder hull \Omega = Q^{Z^d} (Q = local-configuration alphabet; NOT the F-function)
% ==== end canonical macros ====
```

## 3. Standing conventions

- **Author block (all six papers):** Matthew Long; The YonedaAI Collaboration; 2026.
- **Series note:** each paper carries `note = {Part N of this series}` (see `references.bib`
  keys `paperLocality … paperSynthesis`) and cross-cites the others by those keys.
- **Slogans (boxed, quote verbatim where used):**
  - topological phase $=$ a component of the stabilized condensed stack of gapped systems (§2);
  - topological transition $=$ crossing the gapless discriminant in the Hamiltonian moduli stack (§4).
- **The $\pi$-dictionary (§9), quote verbatim:** $\pi_0=$ phases; $\pi_1=$ adiabatic pumps and
  phase automorphisms; $\pi_n=$ higher families and higher defects; $\Sigma=$ gapless transition
  locus; $E^{q+1}(B,B\setminus\Sigma)=$ relative charge of a transition.
- **Stance:** a rigorous research **program**, not a completed theory (§0, §8). Theorems are
  labelled as such only when provable with cited today's-technology; everything else is a
  numbered **Conjecture** or **Program/Definition**. See `.knowledge-base.md`.

---

## Amendment 2026-07-14 — disorder-alphabet letter (resolves notation-audit B3)

Part II documented a rename of the disorder local-configuration alphabet from $F$ to $Q$
("to avoid clash with Part I's $F$-function") on board.md but the change was never recorded
here, leaving the canonical table prescribing the colliding $F$. Per the notation audit
(coordination/notation-audit.md, findings B1/B2/B3/A1), the letter **$Q$ is now blessed
series-wide**: the profinite disorder hull is written $\Omega = Q^{\mathbb{Z}^d}$ in all
papers. Papers I and III (blocking) and IV and V (advisory) are being patched to match;
Part II already complies. The macro \dis is unchanged; only the alphabet letter in prose
and displayed formulas moves from $F$ to $Q$.
