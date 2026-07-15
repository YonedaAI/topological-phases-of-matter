# Cross-Cutting Citation Audit — topological-phases-of-matter

**Auditor:** citation-verifier (cross-cutting, global) | **Date:** 2026-07-14
**Scope:** all 5 worker papers + shared `references.bib` (both copies) + companion citations.
Per-paper GrokRxiv citation panels (`reviews/panel/*-citation.json`) were read first; their
verifications are cited here, not repeated. This audit's job was (a) bib integrity, (b) full
source-level coverage for all 5 papers, (c) ≥10 *additional* external spot-verifications beyond
what the panels already did, and (d) cross-paper consistency.

## TL;DR

**No blocking defects found.** All 5 papers PASS. Every `\cite` key in every paper resolves in
`references.bib`; both bib copies are byte-identical; no duplicate keys; only 1 harmless orphan
entry. 35 of 58 bib entries (60%) are now independently externally verified (22 by the three
existing GrokRxiv citation panels, 13 new in this audit), including every source on the
coordinator's named priority list. Two papers — **spectral-gap-stability** and
**bordism-realizability** — had *no* citation panel at all yet (only novelty/reproducibility/
summary panels exist for bordism-realizability; nothing for spectral-gap-stability), so this
audit is their only citation-level check to date; both come back clean.

---

## 1. Per-paper verdict

| Paper | Cite keys | Missing from bib | Panel citation review? | Verdict |
|---|---|---|---|---|
| lieb-robinson-locality | 19 | 0 | Yes (`lieb-robinson-locality-citation.json`, conf. 0.91) | **PASS** |
| positivity-cstar-norms | 27 | 0 | Yes (`positivity-cstar-norms-citation.json`, conf. 0.92) | **PASS** |
| spectral-gap-stability | 27 | 0 | **None exists** — first citation-level check is this audit | **PASS** |
| lattice-eft-equivalence | 35 | 0 | Yes (`lattice-eft-equivalence-citation.json`, conf. 0.85, plus a re-verification round) | **PASS** |
| bordism-realizability | 39 | 0 | **No citation.json** (only novelty/repro/summary panels exist) — first citation-level check is this audit | **PASS** |

Total unique keys cited across all 5 papers: **57** (of 58 bib entries; 1 orphan, see §2).
Sum of per-paper cite counts above is 147; the discrepancy from 57 unique keys reflects the
heavy, and fully consistent, cross-citation of the 6 companion-paper keys and shared external
sources (Aoki, Clausen–Scholze, Kitaev, etc.) — see §4.

No paper's compiled PDF contains an unresolved `[?]` citation marker (checked via `pdftotext`
on all 5 `papers/pdf/*.pdf`, grep count = 0 in every case), confirming the source-level
resolution above also holds at the BibTeX/compile level.

---

## 2. Bib integrity

1. **Sync**: `references.bib` (repo root) and `papers/latex/references.bib` — `diff` reports
   **zero differences**. Byte-identical.
2. **`% verified:` provenance comments**: all **52 external entries** have an individual
   `% verified:` comment immediately above the `@entry` (confirmed programmatically). The
   **6 companion `@misc` entries** (`paperLocality` … `paperSynthesis`) are instead covered by
   a single shared section header, `% I. CANONICAL COMPANION PAPERS (this series) — cite
   verbatim, do NOT alter.` — appropriate, since these are internal self-citations to the
   project's own in-progress manuscripts, not external literature subject to web verification.
   This is a legitimate documentation convention, not a gap.
3. **Duplicate keys**: none (`sort | uniq -d` on all 58 keys is empty).
4. **Orphan entries** (in `references.bib`, cited by **no** paper): **1**.
   - `clausen-scholze-complex` — Clausen & Scholze, "Condensed Mathematics and Complex
     Geometry," arXiv:2605.11731. Has a full `% verified:` provenance comment and is a
     legitimate, real source, but no paper currently invokes it. Harmless (not a broken
     reference — nothing points *at* it), but flagged per the audit brief. Likely intended for
     the still-pending synthesis paper (Part VI); worth cross-checking when that paper is
     drafted, or removing if it stays unused.
5. **Companion `@misc` entries intact**: all 6 present — `paperLocality`, `paperPositivity`,
   `paperGap`, `paperEFT`, `paperRealizability`, `paperSynthesis` — titles/notes/"Part N of
   this series" framing consistent across every citing paper (see §4).

**Total bib entries: 58.**

---

## 3. Coverage (source-level `\cite` → `references.bib` resolution)

Extracted every `\cite{...}`/`\citep`-style key from all 5 `.tex` files via direct regex
extraction (not relying on compiled output) and diffed against the full bib key set.

**Result: 0 blocking missing references in any of the 5 papers.** Every key cited resolves.
This matches the expectation that the compiled PDFs show no `[?]`, and is now confirmed at
both the source level (this audit) and the compile level (`pdftotext` scan, §1).

No paper cites a key that doesn't exist in `references.bib`; no key exists in one paper's
"logical" citation set but is spelled differently in another (checked by exact string match
across all 5 extraction passes — see also §4 for the specific Clausen–Scholze alias check).

---

## 4. Cross-paper consistency

- **Companion self-citations.** Each of the 5 papers cites the other 4 already-written
  companion papers plus the still-pending `paperSynthesis` (Part VI), and never cites itself:
  lieb-robinson-locality → {EFT, Gap, Positivity, Realizability, Synthesis}; positivity-cstar-norms
  → {EFT, Gap, Locality, Realizability, Synthesis}; spectral-gap-stability → {EFT, Locality,
  Positivity, Realizability, Synthesis}; lattice-eft-equivalence → {Gap, Locality, Positivity,
  Realizability, Synthesis}; bordism-realizability → {EFT, Gap, Locality, Positivity, Synthesis}.
  Fully consistent, no paper mis-cites itself or omits a sibling.
- **Clausen–Scholze arXiv IDs.** Three distinct 2605.xxxxx postings exist in the bib and are
  used consistently by key (never aliased under two different keys, never conflated):
  `clausen-scholze-condensed` = 2605.03658, `clausen-scholze-analytic` = 2605.03655,
  `clausen-scholze-complex` = 2605.11731 (the orphan, §2). No paper mixes these up.
- **Ogata citations.** `ogata-classification-review` (ICM survey, 2110.04675), `ogata-h3-index`
  (2101.00426), and `ogata-spt-chains` (2110.04671, added post-panel-fix to
  `lattice-eft-equivalence` per its re-verification round) are each used for their correct,
  distinct scope (survey vs. 2D H³ index vs. 1D primary source) across positivity-cstar-norms,
  spectral-gap-stability, lattice-eft-equivalence, and bordism-realizability — no cross-paper
  confusion between the survey and the primary-source papers.
- **No duplicate/aliased entries for the same underlying work** were found anywhere in the
  58-key set (i.e., no two keys point at the same title under different names).

---

## 5. External spot-verification (this audit)

The three existing panels (loc/pos/eft-citation) had already independently verified 22 unique
entries via WebSearch/WebFetch (full list in §6). This audit verified **13 additional entries**
via WebSearch — exceeding the ≥10 target — chosen to (a) cover every name on the coordinator's
explicit priority list not yet independently checked, and (b) prioritize load-bearing sources
in **spectral-gap-stability** and **bordism-realizability**, the two papers with no prior
citation-panel coverage at all. For each, title/authors/venue/arXiv ID were confirmed against
live search results, and the *specific claim* the paper attributes to the source was checked
against the citing paper's actual text (not just "does the source exist").

| Key | Confirmed source | Used correctly in-paper? |
|---|---|---|
| `michalakis-zwolak` | Michalakis & Zwolak, "Stability of Frustration-Free Hamiltonians," CMP 322:277 (2013), arXiv:1109.1588 | Yes — spectral-gap-stability Thm. `thm:mz`: LTQO + uniform local gap ⟹ stability + area law, matches abstract verbatim |
| `nsy-bulkgap` | Nachtergaele–Sims–Young, "Stability of the bulk gap...," Lett. Math. Phys. 114:24 (2024), arXiv:2102.07209 | Yes — spectral-gap-stability Thm. `thm:nsy`; text even correctly notes the "GNS representation" adaptation of the BHM strategy, matching the verified abstract's own description |
| `bhm-stability` | Bravyi–Hastings–Michalakis, "Topological quantum order: stability under local perturbations," JMP 51:093512 (2010), arXiv:1001.0344 | Yes — spectral-gap-stability Thm. `thm:bhm`, jointly with short proof below |
| `bravyi-hastings-shortproof` | Bravyi–Hastings, "A short proof of stability...," CMP 307:609 (2011), arXiv:1001.4363 | Yes — correctly framed as the "short proof" companion to `bhm-stability` |
| `cglw-cohomology` | Chen–Gu–Liu–Wen, "SPT orders and the group cohomology of their symmetry group," PRB 87:155114 (2013), arXiv:1106.4772 | Yes — used in both spectral-gap-stability (frustration-free example class) and bordism-realizability (Thm. V-A, group-cohomology fixed-point realizability) |
| `walker-wang` | Walker–Wang, "(3+1)-TQFTs and Topological Insulators," Front. Phys. 7:150 (2012), arXiv:1104.2632 | Yes — bordism-realizability `prop:ww`, construction/boundary-theory claim matches abstract exactly |
| `else-nayak` | Else–Nayak, "Classifying SPT phases through the anomalous action of the symmetry on the edge," PRB 90:235137 (2014), arXiv:1409.5436 | Yes — bordism-realizability Thm. V-A edge characterization, matches the $H^{d+1}(G,U(1))$ edge-obstruction result precisely |
| `thouless-pump` | Thouless, "Quantization of particle transport," PRB 27:6083 (1983) — classic, pre-arXiv | Yes — DOI-only citation is correct/expected for this era |
| `kitaev-honeycomb` | Kitaev, "Anyons in an exactly solved model and beyond," Ann. Phys. 321:2 (2006), arXiv:cond-mat/0506438 | Yes — used in both spectral-gap-stability (frustration-free example) and bordism-realizability (chiral topological order) |
| `kitaev-majorana-wire` | Kitaev, "Unpaired Majorana fermions in quantum wires," Physics-Uspekhi 44:131 (2001), arXiv:cond-mat/0010440 | Yes — bordism-realizability's class-D/BDI Kitaev chain description matches exactly |
| `aasen-wang-hastings` | Aasen–Wang–Hastings, "Adiabatic paths of Hamiltonians...," PRB 106:085122 (2022), arXiv:2203.11137 | Yes — bordism-realizability correctly labels the $\pi_1,\pi_2,\pi_3$ claim as *conjectural*, matching the source's own "conjectured description" language — good citation hygiene |
| `ogata-h3-index` | Ogata, "A $H^3(G,\mathbb{T})$-valued index...," Forum Math. Pi 9:e13 (2021), arXiv:2101.00426 | Yes — 2D SPT completeness claim in lattice-eft-equivalence/bordism-realizability matches; this closes a gap left open by *two* prior panels, both of which had marked it "not independently re-verified" |
| `kapustin-sopenko-noether` | Kapustin–Sopenko, "Local Noether theorem...," JMP 63:091903 (2022), arXiv:2201.01327 | Yes — spectral-gap-stability's "chiral phases (nonzero Hall conductance)" citation matches; verified abstract explicitly states the invariant "unify\[ies\] and generalize\[s\] the Hall conductance and the Thouless pump" |

**No misattributions found in any of the 13.** Every coordinator-named priority source
(CPW 1502.04573, Michalakis–Zwolak, NSY stability/`nsy-bulkgap`, Freed–Hopkins 1604.06527,
Kitaev periodic table 0901.2686, CGLW, Walker–Wang, Else–Nayak, Thouless, Bellissard) is now
independently verified — the first five by prior panels, the remainder in this pass.

---

## 6. Full external-verification ledger (union of panels + this audit)

**35 of 58 entries (60%)** independently confirmed via WebSearch/WebFetch to date:

- **Verified by prior GrokRxiv citation panels (22):** `lieb-robinson-1972`,
  `nsy-quasilocality-1` (partial — F-function formalism confirmed, internal theorem-number
  pinpoint not confirmed due to a non-machine-readable PDF), `clausen-scholze-condensed`,
  `barwick-haine-pyknotic`, `hastings-wen-qac`, `bmns-automorphic`, `hastings-koma`,
  `nachtergaele-sims-clustering`, `cpw-undecidable`, `aoki-solidification`,
  `ogata-classification-review`, `kitaev-periodic-table`, `clausen-scholze-analytic`,
  `bellissard-ncg-qhe`, `denittis-rendel-weyl`, `beaudry-etal`, `freed-hopkins`,
  `kapustin-fidkowski`, `kapustin-sopenko-hall`, `kubota-omega-spectrum`, `ogata-spt-chains`,
  `altland-zirnbauer`.
- **Newly verified in this audit (13):** `michalakis-zwolak`, `nsy-bulkgap`, `bhm-stability`,
  `bravyi-hastings-shortproof`, `cglw-cohomology`, `walker-wang`, `else-nayak`, `thouless-pump`,
  `kitaev-honeycomb`, `kitaev-majorana-wire`, `aasen-wang-hastings`, `ogata-h3-index`,
  `kapustin-sopenko-noether`.
- **Companion self-citations (6), verified by project file-existence rather than web search**
  (not external literature): `paperLocality`, `paperPositivity`, `paperGap`, `paperEFT`,
  `paperRealizability` all correspond to real, compiled `.tex`/`.pdf` files in this project.
  `paperSynthesis` (Part VI) has no corresponding file yet — expected, since the synthesis
  paper is still in progress per the project task tracker (not a defect).

**Remaining 17 entries** not yet independently web-verified by any reviewer (all are either
classic/pre-arXiv results with very high domain confidence, or lower-relevance/background
citations; none appear on the coordinator's priority list and none are missing-from-bib
issues — this is a residual-verification note, not a defect):
`bourne-kellendonk-rennie`, `clausen-scholze-analytic-stacks`, `clausen-scholze-complex`
(the orphan), `denittis-states`, `freed-sre`, `gaiotto-jf`, `hastings-locality`,
`hsin-wang-moduli`, `kapustin-cobordism`, `kellendonk-tilings`, `kubota-controlled`,
`nsy-quasilocality-2`, `prodan-sb`, `ssh-1979`, `thiang-ktheory`, `tknn-1982`,
`xiong-minimalist`.

---

## 7. Non-blocking issues carried over from existing panels (not re-litigated, for completeness)

These were already recorded by the per-paper panels and are cross-referenced here only so the
global picture is in one place; none are blocking and none are this audit's finding:

- lattice-eft-equivalence: two precision gaps flagged by its panel (missing direct
  Altland–Zirnbauer / Ogata-primary-source cites) were **already fixed** by worker-eft and
  re-verified by the same panel (`re_verification.result: "PASS"`, dated 2026-07-14) — confirmed
  still consistent in this audit's independent key-extraction (both `altland-zirnbauer` and
  `ogata-spt-chains` are present and correctly used).
- lieb-robinson-locality: panel noted the classical Bratteli–Robinson-style operator-algebra
  reference for the C*-quasi-local-algebra construction is not directly cited (defers to
  `nsy-quasilocality-1` "and the references there") — minor precision point, not an error.
- positivity-cstar-norms: panel noted absent Glimm/Bratteli citations for UHF/AF algebra
  terminology, and a one-step indirection on semitopological K-theory (Aoki cited, not Weibel
  directly) — both minor, non-blocking.
- lattice-eft-equivalence: `ogata-classification-review` downgraded by its panel to reflect
  that the ICM-survey abstract doesn't itself state the precise completeness theorem (resolved
  by the `ogata-spt-chains` fix above); a lower-priority Schnyder–Ryu–Furusaki–Ludwig companion
  citation for the periodic table remains absent.

---

## 8. Totals

- **Papers audited:** 5/5, all **PASS**.
- **Total unique `\cite` keys checked at source level:** 57 (across 147 per-paper citations).
- **Blocking defects (missing-from-bib citations):** **0**.
- **Bib entries:** 58 total; 1 harmless orphan (`clausen-scholze-complex`); 0 duplicates; both
  bib copies byte-identical; all 52 external entries individually provenance-tagged; all 6
  companion entries intact.
- **External verifications:** 35/58 entries (60%) independently confirmed to date — 22 by
  prior panels, 13 new in this audit (exceeding the ≥10 target), all with zero misattributions.
- **Papers newly given their first citation-level check by this audit:** spectral-gap-stability,
  bordism-realizability (both PASS).
