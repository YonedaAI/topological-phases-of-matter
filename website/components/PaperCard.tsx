import type { Paper } from '../lib/papers';
import theme from '../theme.json';

const ACCENT_CLASS: Record<string, string> = {
  accent: '',
  accent_secondary: 'accent_secondary',
  warning: 'warning',
};

function partKey(part: string): string {
  const m = part.match(/Part\s+([IVX]+)/i);
  return m ? m[1].toUpperCase() : 'I';
}

export function PaperCard({ paper, featured = false }: { paper: Paper; featured?: boolean }) {
  const key = partKey(paper.part);
  const accent = (theme.partAccent as Record<string, string>)[key] ?? 'accent';
  const isCapstone = paper.slug === 'synthesis';

  return (
    <a
      href={`/papers/${paper.slug}/`}
      className={`paper-card${isCapstone ? ' capstone' : ''}${featured ? ' featured' : ''}`}
      style={{ textDecoration: 'none' }}
    >
      <div className="cover">
        {/* eslint-disable-next-line @next/next/no-img-element */}
        <img src={`/images/${paper.slug}.png`} alt={`Cover illustration for ${paper.title}`} loading="lazy" />
      </div>
      <div className="body">
        <span className={`part-badge ${ACCENT_CLASS[accent] ?? ''}`}>
          {isCapstone ? `${paper.part} · Capstone` : paper.part}
        </span>
        <h3>{paper.title}</h3>
        <p className="abstract">{paper.abstract}</p>
        <div className="meta-row">
          <span>
            {paper.pages} pp &middot; {paper.category}
            {paper.hasCode ? ' · code' : ''}
          </span>
        </div>
      </div>
    </a>
  );
}
