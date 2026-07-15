import fs from 'node:fs';
import path from 'node:path';
import { decode } from 'he';
import DOMPurify from 'isomorphic-dompurify';
import { renderMathInHtml } from './render-math';

// Pandoc source HTML lives in content/papers/<slug>.html — vendored into the
// site at build time (see scripts/copy-assets.mjs) so the Next.js build
// never reaches outside the website/ directory for its data.
const CONTENT_DIR = path.join(process.cwd(), 'content', 'papers');

export interface Heading {
  id: string;
  text: string;
  level: 2 | 3;
}

export interface PaperContent {
  html: string;
  headings: Heading[];
  mathErrorCount: number;
}

// The pandoc page wraps the paper in <main class="main-content" id="content">,
// starting with a .paper-header div (title/author/PDF link — replaced by our
// own React header) and then the real body starting at section 1.
function extractBodyRegion(rawHtml: string): string {
  const startMatch = rawHtml.match(/<h1 data-number="1"[^>]*>/);
  const endIdx = rawHtml.indexOf('</main>');
  if (!startMatch || startMatch.index === undefined || endIdx === -1) {
    throw new Error('Could not locate paper body region (missing <h1 data-number="1"> or </main>)');
  }
  return rawHtml.slice(startMatch.index, endIdx).trim();
}

// The reader page's own <h1> is the paper title (app/papers/[slug]/page.tsx);
// pandoc's body sections/subsections are h1/h2, which would otherwise put
// multiple top-level h1s on one page. Demote body headings by one level
// (h2->h3 first, then h1->h2, so the newly-created h2s aren't re-caught by
// the h2->h3 rule) so the page has exactly one h1.
function demoteHeadings(html: string): string {
  return html
    .replace(/<h2(\s|>)/g, '<h3$1')
    .replace(/<\/h2>/g, '</h3>')
    .replace(/<h1(\s|>)/g, '<h2$1')
    .replace(/<\/h1>/g, '</h2>');
}

// Sections are <h2>, subsections <h3> after demoteHeadings.
function extractHeadings(bodyHtml: string): Heading[] {
  const headings: Heading[] = [];
  const re = /<h([23])[^>]*\sid="([^"]+)"[^>]*>([\s\S]*?)<\/h\1>/g;
  let m: RegExpExecArray | null;
  while ((m = re.exec(bodyHtml))) {
    const level = Number(m[1]) as 2 | 3;
    const id = m[2];
    const text = decode(
      m[3]
        .replace(/<[^>]+>/g, '')
        .replace(/\\\(/g, '')
        .replace(/\\\)/g, '')
        .replace(/\\\[/g, '')
        .replace(/\\\]/g, '')
    )
      .replace(/\s+/g, ' ')
      .trim();
    if (text) headings.push({ id, text, level });
  }
  return headings;
}

const PURIFY_CONFIG = {
  USE_PROFILES: { html: true, mathMl: true, svg: true },
  // DOMPurify's mathMl profile doesn't include `semantics`/`annotation` (used
  // by KaTeX to embed the source TeX for accessibility/copy-paste) or the
  // `encoding` attribute that names its content type — without these, every
  // rendered formula's <math> loses its semantics wrapper and drops straight
  // to raw, unstyled TeX text as the only content.
  ADD_TAGS: ['semantics', 'annotation'],
  ADD_ATTR: ['style', 'encoding'],
};

export function loadPaperContent(slug: string): PaperContent {
  const filePath = path.join(CONTENT_DIR, `${slug}.html`);
  const raw = fs.readFileSync(filePath, 'utf-8');
  const body = demoteHeadings(extractBodyRegion(raw));
  const headings = extractHeadings(body);
  const { html: mathRendered, errorCount, errors } = renderMathInHtml(body, slug);

  if (errorCount > 0) {
    // Surface loudly in the build log without failing the whole static
    // export over a single formula — the fallback rendering keeps the page
    // usable while this gets fixed.
    console.error(
      `[render-math] ${errorCount} formula(s) failed to render in "${slug}":\n${errors.join('\n')}`
    );
  }

  const clean = DOMPurify.sanitize(mathRendered, PURIFY_CONFIG);
  return { html: clean, headings, mathErrorCount: errorCount };
}
