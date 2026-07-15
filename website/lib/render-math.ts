import katex from 'katex';
import { decode } from 'he';
import { getMacrosForSlug } from './macros';

// Pandoc wraps every math source span in \(...\) (inline) or \[...\] (display)
// and HTML-escapes the raw TeX as plain text (so literal Unicode characters
// used in the .tex sources, e.g. "×" typed directly, come through the
// pandoc output as HTML entities like "&times;"). We match the whole
// <span class="math ...">...</span> element (pandoc never nests another
// element inside a math span) so the delimiters are always well-formed.
const MATH_SPAN_RE = /<span class="math (inline|display)">([\s\S]*?)<\/span>/g;

function stripDelimiters(src: string, displayMode: boolean): string {
  const trimmed = src.trim();
  if (displayMode) {
    return trimmed.replace(/^\\\[/, '').replace(/\\\]$/, '').trim();
  }
  return trimmed.replace(/^\\\(/, '').replace(/\\\)$/, '').trim();
}

// A handful of display equations are wrapped in \begin{equation}...\end{equation}
// (or the starred form) purely for the LaTeX build's numbering; KaTeX has no
// equation-numbering concept and the pandoc HTML here never resolves those
// numbers into visible text anyway, so unwrap to the inner content and let
// displayMode supply the display styling.
function unwrapEquationEnvironment(src: string): string {
  const m = src.match(/^\\begin\{equation\*?\}([\s\S]*)\\end\{equation\*?\}$/);
  return m ? m[1].trim() : src;
}

// KaTeX has no `multline`/`multline*` (an amsmath environment for a long
// expression broken over several unaligned lines, first line left and last
// line right). `gather`/`gather*` — natively supported — take the same bare
// `\\`-separated line syntax and center each line, which is the closest
// faithful substitution without hand-aligning each source equation.
function rewriteMultline(src: string): string {
  return src
    .replace(/\\begin\{multline\*\}/g, '\\begin{gather*}')
    .replace(/\\end\{multline\*\}/g, '\\end{gather*}')
    .replace(/\\begin\{multline\}/g, '\\begin{gather}')
    .replace(/\\end\{multline\}/g, '\\end{gather}');
}

const TIKZCD_RE = /\\begin\{tikzcd\}([\s\S]*)\\end\{tikzcd\}/;

// tikz-cd commutative diagrams have no KaTeX (or any browser-math-renderer)
// equivalent — they're TikZ/PGF drawing commands, not math markup. Rather
// than let these hit KaTeX and fall through to the generic error fallback,
// render a designed placeholder that names what's missing and keeps the
// diagram's own source available on demand; the diagram itself is always
// visible in the PDF.
function renderTikzCdPlaceholder(src: string): string {
  const esc = src.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  return (
    '<div class="diagram-fallback">' +
    '<p class="diagram-note">Commutative diagram &mdash; rendered in the PDF.</p>' +
    '<details><summary>View diagram source (TikZ-CD)</summary>' +
    `<pre><code>${esc}</code></pre>` +
    '</details></div>'
  );
}

export interface RenderMathResult {
  html: string;
  errorCount: number;
  errors: string[];
}

export function renderMathInHtml(html: string, slug: string): RenderMathResult {
  const macros = getMacrosForSlug(slug);
  const errors: string[] = [];

  const rendered = html.replace(MATH_SPAN_RE, (_full, kind: string, inner: string) => {
    const displayMode = kind === 'display';
    let src = stripDelimiters(inner, displayMode);
    // Decode HTML entities back to real characters — KaTeX understands
    // Unicode math characters (×, ·, ∀, ...) directly.
    src = decode(src);
    if (displayMode) src = unwrapEquationEnvironment(src);

    if (displayMode && TIKZCD_RE.test(src)) {
      return renderTikzCdPlaceholder(src);
    }
    src = rewriteMultline(src);

    try {
      return katex.renderToString(src, {
        displayMode,
        throwOnError: true,
        strict: 'ignore',
        trust: true,
        macros: { ...macros },
      });
    } catch (err) {
      const message = err instanceof Error ? err.message : String(err);
      errors.push(`[${slug}] ${displayMode ? 'display' : 'inline'} math failed: ${message}\n    source: ${src.slice(0, 200)}`);
      // Never surface KaTeX's own red error span; fall back to plain escaped
      // text so a rendering gap is visible-but-quiet rather than alarming.
      const esc = src.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
      return `<code class="math-fallback">${esc}</code>`;
    }
  });

  return { html: rendered, errorCount: errors.length, errors };
}
