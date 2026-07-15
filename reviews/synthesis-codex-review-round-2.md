---
reviewer: codex (OpenAI, gpt-5.5 via codex exec read-only, xhigh)
type: formatting
paper: synthesis
round: 2
date: 2026-07-14T18:20:00Z
---

# Codex LaTeX formatting review — round 2

Round-1 fixes verified in place: `progconj` labels resolve as `Conjecture VI-1` through
`VI-4`; `\Cref{rec:III,rec:IIIc}` is present; the longtable statement column is ragged-right
`p{7.1cm}`; the `\addlinespace` separators are gone. No compile errors, undefined refs/cites,
duplicate destinations, overfull/underfull boxes, BibTeX warnings, or hyperref PDF-string
warnings.

## Remaining finding

1. **synthesis.tex:1202–1245 — Table 1 longtable page split still logs infinite-glue
   shrinkage.** The synced build log has `ignored: Infinite glue shrinkage found in box being
   split` (synthesis.log:797), at the Table 1 split across pages 19–20. Fix the table
   construction, not refs/cites: remove the continuation-foot block (lines 1216–1218), or
   split Table 1 into two explicit nonbreakable `tabular`s; if keeping `longtable`, avoid
   booktabs rules / continuation-footer material at the page break and use only fixed
   non-stretch spacing (or no separator) there.

VERDICT: NEEDS_FIX
