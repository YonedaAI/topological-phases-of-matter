#!/usr/bin/env python3
"""
Convert LaTeX papers to styled HTML for GitHub Pages using pandoc + post-processing.

Usage:
    python3 latex2html.py --config papers.yaml
    python3 latex2html.py --latex-dir papers/latex --html-dir docs/papers --template scripts/paper-template.html

Config YAML format:
    project_title: "The AI Operating System"
    papers:
      - name: "agent-scheduler"
        title: "Agent Scheduler"
        part: "Part I"
      - name: "tool-interface"
        title: "Tool Interface Layer"
        part: "Part II"

Requires: pandoc (brew install pandoc), pdflatex, bibtex, pdftotext (for
citation and cross-reference resolution).

Citations (\\cite): resolved via pandoc --citeproc against the shared
references.bib, using the numeric style in numeric.csl. A paper may instead
embed a \\begin{thebibliography}...\\end{thebibliography} block (as a
self-contained fallback bibliography); pandoc does NOT resolve \\cite against
that natively (it leaves citation spans empty and renders the bibitems as an
unnumbered, disconnected paragraph dump), so that block is stripped from the
copy fed to pandoc and citeproc is used against the shared references.bib
instead, provided every \\cite key used also has a references.bib entry.

Cross-references (\\Cref, \\cref, \\ref, \\eqref): pandoc's LaTeX reader has no
concept of LaTeX's compiled numbering, so it emits raw hyperlinks whose visible
text is the literal, unresolved label ("[eq:disp]"). To resolve these
correctly -- including cleveref behaviors like range compression
("Theorems 3.1 to 3.4") and mixed-kind lists ("Proposition 7.1 and Theorem
II-C") that are impractical to reimplement by hand -- this script compiles a
throwaway copy of each paper in a scratch directory with a small appendix that
re-invokes every unique \\Cref/\\cref/\\ref/\\eqref call found in the paper,
then reads the *actual* cleveref-rendered text back out of the resulting PDF
via pdftotext. That harvested text is substituted for each macro call in a
COPY of the .tex before pandoc ever sees it. The scratch compile never touches
papers/latex/ originals or their PDFs. A lighter-weight fallback (parsing the
.aux file's \\newlabel entries directly, with the reference kind guessed from
the label prefix) is used only if the harvest is missing an entry.
"""

import argparse
import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent


# ---------------------------------------------------------------------------
# LaTeX artifact cleanup (post-pandoc HTML)
# ---------------------------------------------------------------------------

def clean_latex_artifacts(html: str) -> str:
    """Remove remaining LaTeX commands from pandoc HTML output."""
    # Inline commands
    html = re.sub(r'\\texttt\{([^}]*)\}', r'<code>\1</code>', html)
    html = re.sub(r'\\textbf\{([^}]*)\}', r'<strong>\1</strong>', html)
    html = re.sub(r'\\emph\{([^}]*)\}', r'<em>\1</em>', html)
    html = re.sub(r'\\textit\{([^}]*)\}', r'<em>\1</em>', html)
    html = re.sub(r'\\textsc\{([^}]*)\}', r'\1', html)
    html = re.sub(r'\\textsf\{([^}]*)\}', r'\1', html)

    # Sizing and spacing
    html = re.sub(r'\\(Large|LARGE|large|huge|Huge|small|footnotesize|tiny|normalsize)\b', '', html)
    html = re.sub(r'\\vspace\*?\{[^}]*\}', '', html)
    html = re.sub(r'\\hspace\*?\{[^}]*\}', '', html)
    html = re.sub(r'\\noindent\b', '', html)
    html = re.sub(r'\\centering\b', '', html)
    html = re.sub(r'\\raggedright\b', '', html)

    # References and labels
    html = re.sub(r'\\label\{[^}]*\}', '', html)

    # lstlisting remnants
    html = re.sub(r'\\begin\{lstlisting\}\[[^\]]*\]', '', html)
    html = re.sub(r'\\begin\{lstlisting\}', '', html)
    html = re.sub(r'\\end\{lstlisting\}', '', html)

    # Math symbols that might not render outside KaTeX
    html = html.replace('\\cdot', '&middot;')
    html = html.replace('\\times', '&times;')
    html = html.replace('\\leq', '&le;')
    html = html.replace('\\geq', '&ge;')
    html = html.replace('\\rightarrow', '&rarr;')
    html = html.replace('\\Rightarrow', '&rArr;')
    html = html.replace('\\mapsto', '&#8614;')
    html = html.replace('\\infty', '&infin;')
    html = html.replace('\\ldots', '&hellip;')

    # Clean leftover backslash commands
    html = re.sub(r'\\(par|medskip|bigskip|smallskip|newline|linebreak)\b', '', html)
    html = re.sub(r'\\(clearpage|newpage|pagebreak)\b', '', html)

    # Second pass for nested patterns
    html = re.sub(r'\\texttt\{([^}]*)\}', r'<code>\1</code>', html)
    html = re.sub(r'\\textbf\{([^}]*)\}', r'<strong>\1</strong>', html)
    html = re.sub(r'\\emph\{([^}]*)\}', r'<em>\1</em>', html)

    return html


def insert_references_heading(body: str) -> str:
    """Pandoc/citeproc emits <div id="refs">...</div> with no heading (the
    LaTeX \\bibliography command that produced it is likewise headingless in
    the *source*, but \\bibliographystyle auto-titles it "References" in the
    compiled PDF). Match that PDF heading and pandoc's own styling for
    unnumbered sections (see how \\section*{Code availability} renders)."""
    if '<div id="refs"' not in body:
        return body
    if re.search(r'<h[1-6][^>]*>\s*References\s*<', body):
        return body
    return body.replace(
        '<div id="refs"',
        '<h1 class="unnumbered" id="references">References</h1>\n<div id="refs"',
        1,
    )


# ---------------------------------------------------------------------------
# Bibliography handling
# ---------------------------------------------------------------------------

THEBIB_RE = re.compile(r'\\begin\{thebibliography\}.*?\\end\{thebibliography\}', re.DOTALL)


def strip_thebibliography(text: str):
    """Strip an embedded thebibliography block, if present.

    Verified empirically: pandoc does NOT resolve \\cite against it (citation
    spans stay empty) and separately renders the \\bibitem paragraphs as an
    unordered, unnumbered dump (even echoing the {99} capacity argument as
    stray text). Every \\cite key in this corpus already has a matching entry
    in the shared references.bib, so citeproc against that file is a strict
    improvement, not just a workaround.
    """
    if '\\begin{thebibliography}' not in text:
        return text, False
    return THEBIB_RE.sub('', text), True


# ---------------------------------------------------------------------------
# Brace-aware parsing helpers (LaTeX .aux entries nest braces, e.g. a title
# field containing \cite{...}; naive [^}]* regexes break on these)
# ---------------------------------------------------------------------------

def extract_braced_groups(s: str, start: int):
    """From s[start] == '{', extract consecutive top-level {...} groups.
    Returns (list_of_group_contents, index_after_last_group)."""
    groups = []
    i = start
    n = len(s)
    while i < n and s[i] == '{':
        depth = 0
        j = i
        while j < n:
            if s[j] == '{':
                depth += 1
            elif s[j] == '}':
                depth -= 1
                if depth == 0:
                    break
            j += 1
        groups.append(s[i + 1:j])
        i = j + 1
    return groups, i


def parse_aux_number_map(aux_path: Path):
    """Fallback source of truth: label -> printed number/counter text, read
    straight from \\newlabel{label}{{number}{page}{title}{anchor}{}}."""
    numbers = {}
    if not aux_path.exists():
        return numbers
    text = aux_path.read_text(errors='replace')
    for m in re.finditer(r'\\newlabel\{([^}]+)\}\{', text):
        label = m.group(1)
        if label.endswith('@cref'):
            continue
        brace_start = m.end() - 1
        groups, _ = extract_braced_groups(text, brace_start)
        if not groups:
            continue
        subgroups, _ = extract_braced_groups(groups[0], 0)
        if subgroups:
            numbers[label] = subgroups[0]
    return numbers


# Fallback only (task-specified mapping): used when the LaTeX-harvest below
# is missing a specific entry. cleveref's *actual* rendering (range
# compression, per-group capitalization in mixed lists, custom \Crefname
# overrides for progthm/progconj/recollection, ...) is what the harvest
# below captures; this table is intentionally simpler.
PREFIX_KIND = {
    'thm': 'Theorem', 'prop': 'Proposition', 'lem': 'Lemma', 'cor': 'Corollary',
    'def': 'Definition', 'rem': 'Remark', 'conj': 'Conjecture', 'rec': 'Recollection',
    'ex': 'Example', 'sec': 'Section', 'subsec': 'Section', 'fig': 'Figure',
    'tab': 'Table', 'app': 'Section',
}


def fallback_resolve(cmd: str, arg: str, number_map: dict) -> str:
    labels = [l.strip() for l in arg.split(',')]
    if cmd == 'eqref':
        return ', '.join(f"({number_map.get(l, '?' + l)})" for l in labels)
    if cmd == 'ref':
        return ', '.join(number_map.get(l, '?' + l) for l in labels)
    parts = []
    for l in labels:
        prefix = l.split(':')[0] if ':' in l else ''
        kind = PREFIX_KIND.get(prefix, prefix.capitalize() or 'Ref')
        if cmd == 'cref':
            kind = kind.lower()
        parts.append(f"{kind} {number_map.get(l, '?' + l)}")
    if len(parts) == 1:
        return parts[0]
    if len(parts) == 2:
        return parts[0] + ' and ' + parts[1]
    return ', '.join(parts[:-1]) + ', and ' + parts[-1]


# ---------------------------------------------------------------------------
# Cross-reference resolution via LaTeX "dump" harvesting
# ---------------------------------------------------------------------------

REF_CALL_RE = re.compile(r'\\(Cref|cref|eqref|ref)\{([^}]*)\}')


def extract_unique_ref_calls(text: str):
    seen_set = set()
    ordered = []
    for m in REF_CALL_RE.finditer(text):
        key = (m.group(1), m.group(2))
        if key not in seen_set:
            seen_set.add(key)
            ordered.append(key)
    return ordered


def build_dump_source(original_text: str, calls) -> str:
    lines = []
    for i, (cmd, arg) in enumerate(calls):
        idx = f"{i:06d}"
        lines.append(f"\\noindent XDUMPB{idx} \\{cmd}{{{arg}}} XDUMPE{idx}\\par")
    dump_block = "\n\\clearpage\n" + "\n".join(lines) + "\n"
    last_end = original_text.rfind('\\end{document}')
    if last_end == -1:
        raise ValueError('no \\end{document} found in source')
    return original_text[:last_end] + dump_block + '\n' + original_text[last_end:]


def run_logged(cmd, cwd: Path, log_path: Path):
    try:
        result = subprocess.run(cmd, cwd=cwd, capture_output=True, text=True, timeout=180)
    except subprocess.TimeoutExpired as e:
        log_path.write_text(f"TIMEOUT running {cmd}\n{e}")
        return None
    log_path.write_text((result.stdout or '') + '\n' + (result.stderr or ''))
    return result


def compile_until_stable(tex_stem: str, work_dir: Path, has_bib: bool, max_passes: int = 6) -> bool:
    tex_name = f"{tex_stem}.tex"
    run_logged(['pdflatex', '-interaction=nonstopmode', tex_name], work_dir, work_dir / 'pass1.log')
    if has_bib:
        run_logged(['bibtex', tex_stem], work_dir, work_dir / 'bibtex.log')
    stable = False
    for i in range(max_passes):
        log_path = work_dir / f'pass{i + 2}.log'
        run_logged(['pdflatex', '-interaction=nonstopmode', tex_name], work_dir, log_path)
        log_text = log_path.read_text(errors='replace') if log_path.exists() else ''
        if 'Rerun to get' not in log_text:
            stable = True
            break
    return stable and (work_dir / f'{tex_stem}.pdf').exists()


def harvest_crossrefs(name: str, original_text: str, bib_path: Path, scratch_root: Path, log: list):
    """Compile a scratch copy with a cross-reference dump appendix, and read
    back the actual rendered text for every unique \\Cref/\\cref/\\ref/\\eqref
    call. Falls back to .aux-based reconstruction for any call the harvest
    didn't resolve (missing marker, compile hiccup, etc.)."""
    calls = extract_unique_ref_calls(original_text)
    if not calls:
        return {}, []

    if shutil.which('pdflatex') is None or shutil.which('pdftotext') is None:
        log.append(f"  ERROR: pdflatex/pdftotext not found on PATH; cannot resolve cross-refs for {name}")
        return {}, [f"\\{c}{{{a}}}" for c, a in calls]

    work_dir = scratch_root / f"{name}-xref"
    work_dir.mkdir(parents=True, exist_ok=True)
    dump_text = build_dump_source(original_text, calls)
    tex_path = work_dir / f"{name}.tex"
    tex_path.write_text(dump_text)

    has_bib = '\\bibliography{' in original_text
    if has_bib and bib_path.exists():
        shutil.copy(bib_path, work_dir / bib_path.name)

    ok = compile_until_stable(name, work_dir, has_bib)
    pdf_path = work_dir / f"{name}.pdf"
    if not ok:
        log.append(f"  WARNING: cross-ref dump compile for {name} did not fully stabilize "
                    f"(check {work_dir} logs); resolved entries are still used, gaps fall back to .aux")

    mapping = {}
    if pdf_path.exists():
        txt_result = subprocess.run(['pdftotext', '-layout', str(pdf_path), '-'],
                                     capture_output=True, text=True)
        dump_txt = txt_result.stdout
        for i, (cmd, arg) in enumerate(calls):
            idx = f"{i:06d}"
            pat = re.compile(r'XDUMPB' + idx + r'(.*?)XDUMPE' + idx, re.DOTALL)
            m = pat.search(dump_txt)
            if m:
                resolved = re.sub(r'\s+', ' ', m.group(1)).strip()
                if resolved:
                    mapping[(cmd, arg)] = resolved

    missing = [c for c in calls if c not in mapping]
    if missing:
        number_map = parse_aux_number_map(work_dir / f"{name}.aux")
        for cmd, arg in missing:
            mapping[(cmd, arg)] = fallback_resolve(cmd, arg, number_map)
        log.append(f"  NOTE: {len(missing)} cross-ref(s) in {name} used the .aux-prefix fallback "
                    f"instead of the harvested cleveref text: {missing[:8]}")

    return mapping, missing


def apply_crossref_map(text: str, mapping: dict):
    unresolved = []

    def _sub(m):
        key = (m.group(1), m.group(2))
        if key in mapping:
            return mapping[key]
        unresolved.append(m.group(0))
        return m.group(0)

    new_text = REF_CALL_RE.sub(_sub, text)
    return new_text, unresolved


# ---------------------------------------------------------------------------
# Per-paper conversion
# ---------------------------------------------------------------------------

def convert_paper(
    name: str,
    title: str,
    part: str,
    project_title: str,
    latex_dir: Path,
    html_dir: Path,
    template: str,
    bib_path: Path,
    csl_path: Path,
    scratch_root: Path,
) -> int:
    """Convert a single paper from LaTeX to styled HTML. Returns artifact count."""
    tex_file = latex_dir / f"{name}.tex"
    html_file = html_dir / f"{name}.html"
    full_title = f"{title} — {project_title}, {part}"

    print(f"Converting {name}...")

    if not tex_file.exists():
        print(f"  ERROR: {tex_file} not found")
        return -1

    original_text = tex_file.read_text()
    log = []

    # 1. Cross-references: resolve \Cref/\cref/\ref/\eqref against a scratch
    #    LaTeX compile, on a copy. Original .tex/.pdf are never touched.
    mapping, unresolved_harvest = harvest_crossrefs(name, original_text, bib_path, scratch_root, log)
    resolved_text, unresolved_subs = apply_crossref_map(original_text, mapping)

    # 2. Citations: strip an embedded thebibliography (pandoc doesn't resolve
    #    \cite against it); citeproc below handles both styles uniformly.
    resolved_text, had_thebib = strip_thebibliography(resolved_text)

    for line in log:
        print(line)
    if unresolved_subs:
        print(f"  WARNING: {len(unresolved_subs)} cross-ref(s) still unresolved after fallback: "
              f"{unresolved_subs[:5]}")

    xform_dir = scratch_root / 'pandoc-src'
    xform_dir.mkdir(parents=True, exist_ok=True)
    xform_path = xform_dir / f"{name}.tex"
    xform_path.write_text(resolved_text)

    # Run pandoc to get HTML body, with citeproc resolving \cite against the
    # shared bibliography using a numeric style.
    result = subprocess.run(
        [
            "pandoc", str(xform_path),
            "--to", "html5",
            "--mathjax",
            "--toc", "--toc-depth=3",
            "--number-sections",
            "--syntax-highlighting=none",
            "--wrap=none",
            "--citeproc",
            f"--bibliography={bib_path}",
            f"--csl={csl_path}",
        ],
        capture_output=True, text=True,
    )

    if result.returncode != 0:
        print(f"  pandoc warning: {result.stderr[:400]}")

    body = result.stdout
    if not body.strip():
        print(f"  ERROR: pandoc produced empty output for {name}")
        return -1

    n_citation_spans = len(re.findall(r'<span class="citation"', body))
    n_empty_citations = len(re.findall(r'<span class="citation"[^>]*>\s*</span>', body))

    # Clean LaTeX artifacts
    body = clean_latex_artifacts(body)
    body = insert_references_heading(body)

    # Substitute into template
    html = template.replace("{{TITLE}}", full_title)
    html = html.replace("{{PDF_LINK}}", f"../latex/{name}.pdf")
    html = html.replace("{{PART}}", part)
    html = html.replace("{{BODY}}", body)

    # Write output
    html_dir.mkdir(parents=True, exist_ok=True)
    html_file.write_text(html)

    # Count remaining artifacts
    remaining = len(re.findall(r'\\(texttt|textbf|vspace|Large|emph|textsc)\b', html))
    leftover_labels = len(re.findall(
        r'\[(?:eq|thm|prop|sec|lem|cor|def|rem|conj|rec|fig|tab):[^\]]*\]', html))
    lines = html.count('\n') + 1
    print(f"  Done: {lines} lines, {remaining} LaTeX artifacts, "
          f"{n_citation_spans} citations ({n_empty_citations} empty), "
          f"{len(mapping)} cross-refs resolved ({len(unresolved_subs)} unresolved), "
          f"thebibliography stripped={had_thebib}, leftover-labels={leftover_labels}")
    return remaining + n_empty_citations + leftover_labels


def load_config(config_path: Path) -> dict:
    """Load YAML or JSON config file."""
    text = config_path.read_text()
    # Try JSON first (no dependency), then YAML
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        pass
    try:
        import yaml
        return yaml.safe_load(text)
    except ImportError:
        print("ERROR: PyYAML not installed. Use JSON config or: pip install pyyaml")
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description="Convert LaTeX papers to styled HTML")
    parser.add_argument("--config", type=Path, help="YAML/JSON config file")
    parser.add_argument("--latex-dir", type=Path, help="Directory containing .tex files")
    parser.add_argument("--html-dir", type=Path, help="Output directory for .html files")
    parser.add_argument("--template", type=Path, help="HTML template file")
    parser.add_argument("--project-title", default="Research Series", help="Project title for page headers")
    parser.add_argument("--papers", nargs="*", help="Papers as name:title:part (e.g. 'my-paper:My Paper:Part I')")
    parser.add_argument("--bibliography", type=Path, default=None,
                         help="Shared .bib file (default: <latex-dir>/references.bib)")
    parser.add_argument("--csl", type=Path, default=SCRIPT_DIR / "numeric.csl",
                         help="CSL citation style (default: scripts/numeric.csl)")
    parser.add_argument("--scratch-dir", type=Path, default=None,
                         help="Scratch directory for LaTeX cross-reference resolution "
                              "(default: a fresh temp dir)")
    args = parser.parse_args()

    if args.config:
        config = load_config(args.config)
        project_title = config.get("project_title", "Research Series")
        latex_dir = Path(config.get("latex_dir", "papers/latex"))
        html_dir = Path(config.get("html_dir", "docs/papers"))
        template_path = Path(config.get("template", "scripts/paper-template.html"))
        papers = [(p["name"], p["title"], p["part"]) for p in config["papers"]]
    elif args.latex_dir and args.html_dir and args.template and args.papers:
        project_title = args.project_title
        latex_dir = args.latex_dir
        html_dir = args.html_dir
        template_path = args.template
        papers = []
        for p in args.papers:
            parts = p.split(":")
            if len(parts) != 3:
                print(f"ERROR: Paper spec '{p}' must be 'name:title:part'")
                sys.exit(1)
            papers.append(tuple(parts))
    else:
        parser.print_help()
        print("\nExamples:")
        print("  python3 latex2html.py --config papers.yaml")
        print("  python3 latex2html.py --latex-dir papers/latex --html-dir docs/papers \\")
        print("    --template scripts/paper-template.html --project-title 'My Research' \\")
        print("    --papers 'paper-a:Paper A:Part I' 'paper-b:Paper B:Part II'")
        sys.exit(1)

    if not template_path.exists():
        print(f"ERROR: Template not found at {template_path}")
        sys.exit(1)

    template = template_path.read_text()

    bib_path = args.bibliography or (latex_dir / "references.bib")
    if not bib_path.exists():
        print(f"ERROR: Bibliography not found at {bib_path}")
        sys.exit(1)
    if not args.csl.exists():
        print(f"ERROR: CSL style not found at {args.csl}")
        sys.exit(1)

    for tool in ("pandoc", "pdflatex", "bibtex", "pdftotext"):
        if shutil.which(tool) is None:
            print(f"ERROR: required tool '{tool}' not found on PATH")
            sys.exit(1)

    if args.scratch_dir:
        scratch_root = args.scratch_dir
        scratch_root.mkdir(parents=True, exist_ok=True)
        cleanup_scratch = False
    else:
        scratch_root = Path(tempfile.mkdtemp(prefix="latex2html-xref-"))
        cleanup_scratch = True

    total_artifacts = 0
    try:
        for name, title, part in papers:
            count = convert_paper(
                name, title, part, project_title, latex_dir, html_dir, template,
                bib_path, args.csl, scratch_root,
            )
            if count > 0:
                total_artifacts += count
    finally:
        if cleanup_scratch:
            shutil.rmtree(scratch_root, ignore_errors=True)

    print(f"\nAll {len(papers)} papers converted.")
    if total_artifacts == 0:
        print("  All clean — no LaTeX artifacts, empty citations, or unresolved labels detected.")
    else:
        print(f"  WARNING: {total_artifacts} total remaining issues across all papers.")


if __name__ == "__main__":
    main()
