// The incoming HTML is our own pandoc output, pre-rendered with KaTeX and
// sanitized with DOMPurify at build time — not user-supplied content.
//
// This is deliberately a plain Server Component (no 'use client'), rendered
// with dangerouslySetInnerHTML rather than a client-side ref callback. A
// ref-callback mount only sets innerHTML once the browser runs React on the
// client, which means the static-exported HTML file itself ships an empty
// <div> — no math, no text, nothing for crawlers, OG scrapers, or a
// no-JS/slow-JS first paint. Since this component has no 'use client'
// boundary, React Server Components never hydrate or reconcile its subtree
// on the client (there is no client-side re-render of it to diff against),
// so dangerouslySetInnerHTML here cannot suffer the hydration-mangling
// problem that motivates avoiding it in *client* components — the static
// HTML is simply the final content, permanently.
export function PaperContent({ html }: { html: string }) {
  return <div className="paper-content" dangerouslySetInnerHTML={{ __html: html }} />;
}
