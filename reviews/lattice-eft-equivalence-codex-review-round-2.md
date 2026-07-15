---
reviewer: codex (OpenAI)
type: formatting
paper: lattice-eft-equivalence
round: 2
date: 2026-07-14T22:05:00Z
---

Codex formatting review of `papers/latex/lattice-eft-equivalence.tex` (round 2,
fresh thread), after the round-1 fixes (texorpdfstring headings, aliascnt theorem
naming, optional section-title arg, bold-extra, flafter, first by~% fix). Codex
re-inspected the source and confirmed the round-1 items resolved. Two findings
remain, both the same class of defect.

## Findings

1. **Doubled inter-word space before a citation (spectrum $\IFH$).** A source
   line ends with `$\IFH$` and the citation begins the next line as ` ~\cite{...}`
   (leading indent space followed by `~`). The end-of-line newline already emits a
   space, so `$\IFH$` and the citation are separated by two spaces in the output.
   Fix: end the `$\IFH$` line with `$\IFH$~%` (non-breaking space + comment to
   swallow the newline) and drop the leading `~` from the citation line:
   ```
   ... computed by a spectrum $\IFH$~%
   \cite{freed-hopkins,kapustin-cobordism,gaiotto-jf,xiong-minimalist}.
   ```

2. **Doubled inter-word space before a citation ("...used in this setting by").**
   Same pattern: a line ends with `by` and the next line is ` ~\cite{beaudry-etal,
   kubota-omega-spectrum}...`. Fix: `by~%` at the end of the line, drop the leading
   `~` from the citation line:
   ```
   ... used in this setting by~%
   \cite{beaudry-etal,kubota-omega-spectrum}---the infinite-loop space of a
   ```

Both were introduced by an earlier global ` \cite{`\,$\to$\,`~\cite{` replacement
that left a leading space when the citation sat at the start of an indented
continuation line. A file-wide grep for `^\s*~\\cite` confirms these are the only
two occurrences.

VERDICT: NEEDS_FIX
