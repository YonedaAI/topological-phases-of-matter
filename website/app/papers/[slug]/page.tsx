import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { getAllSlugs, getPaper, getAdjacentPapers } from '../../../lib/papers';
import { loadPaperContent } from '../../../lib/content';
import { PaperContent } from '../../../components/PaperContent';
import { TableOfContents } from '../../../components/TableOfContents';

export function generateStaticParams() {
  return getAllSlugs().map((slug) => ({ slug }));
}

export async function generateMetadata({ params }: { params: { slug: string } }): Promise<Metadata> {
  const paper = getPaper(params.slug);
  if (!paper) return {};
  const ogImage = `/og/og-${paper.slug}.png`;
  const url = `/papers/${paper.slug}/`;
  return {
    title: paper.title,
    description: paper.abstract,
    openGraph: {
      title: paper.title,
      description: paper.abstract,
      type: 'article',
      url,
      images: [{ url: ogImage, width: 1200, height: 630, alt: paper.title }],
    },
    twitter: {
      card: 'summary_large_image',
      title: paper.title,
      description: paper.abstract,
      images: [ogImage],
    },
    alternates: { canonical: url },
  };
}

export default function PaperPage({ params }: { params: { slug: string } }) {
  const paper = getPaper(params.slug);
  if (!paper) notFound();

  const { html, headings } = loadPaperContent(paper.slug);
  const { prev, next } = getAdjacentPapers(paper.slug);

  return (
    <div className="paper-layout">
      <TableOfContents headings={headings} />

      <main className="paper-main">
        <div className="reader-header">
          <span className="part-badge">{paper.part}</span>
          <h1>{paper.title}</h1>
          <div className="reader-meta">
            <span>Matthew Long &middot; YonedaAI Research Collective &middot; Chicago, IL</span>
            <span>&middot;</span>
            <span>{paper.pages} pp</span>
            <span>&middot;</span>
            <span>{paper.category}</span>
          </div>
          <div className="reader-actions">
            <a className="btn primary" href={`/pdf/${paper.slug}.pdf`}>
              Download PDF
            </a>
            {paper.hasCode && (
              <a
                className="btn"
                href={`https://github.com/YonedaAI/topological-phases-of-matter/tree/main/src/${paper.slug}`}
                target="_blank"
                rel="noreferrer"
              >
                View code
              </a>
            )}
            <a className="btn" href="/">
              All papers
            </a>
          </div>
        </div>

        <PaperContent html={html} />

        <nav className="paper-nav" aria-label="Paper navigation">
          {prev ? (
            <a href={`/papers/${prev.slug}/`}>
              <span className="dir">&larr; Previous &middot; {prev.part}</span>
              <span>{prev.title}</span>
            </a>
          ) : (
            <span />
          )}
          {next ? (
            <a href={`/papers/${next.slug}/`} className="next-col">
              <span className="dir">Next &middot; {next.part} &rarr;</span>
              <span>{next.title}</span>
            </a>
          ) : (
            <span />
          )}
        </nav>
      </main>
    </div>
  );
}
