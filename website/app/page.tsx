import type { Metadata } from 'next';
import katex from 'katex';
import { papers } from '../lib/papers';
import { getMacrosForSlug } from '../lib/macros';
import { PaperCard } from '../components/PaperCard';

export const metadata: Metadata = {
  openGraph: {
    url: '/',
    images: [{ url: '/og/og-default.png', width: 1200, height: 630 }],
  },
  twitter: {
    card: 'summary_large_image',
    images: ['/og/og-default.png'],
  },
};

const macros = getMacrosForSlug('synthesis');

function symbol(tex: string): string {
  try {
    return katex.renderToString(tex, {
      displayMode: false,
      throwOnError: true,
      strict: 'ignore',
      trust: true,
      macros: { ...macros },
    });
  } catch {
    return tex;
  }
}

const SPINE = [
  { label: 'Local quantum interactions', tex: '\\Int_{d,G}' },
  { label: 'Condensed moduli stack of Hamiltonians', tex: '\\Ham_{d,G}' },
  { label: 'Uniformly gapped substack', tex: '\\Gap_{d,G}' },
  { label: 'Stabilized phase ∞-groupoid', tex: '\\Phase_{d,G}^{\\st}' },
  { label: 'Invertible condensed phase spectrum', tex: '\\IPcond_{d,G}' },
].map((s) => ({ ...s, rendered: symbol(s.tex) }));

const synthesis = papers.find((p) => p.slug === 'synthesis')!;
const modules = papers.filter((p) => p.slug !== 'synthesis');

export default function Home() {
  return (
    <main>
      <section className="hero">
        <span className="kicker">Six-part modular research program</span>
        <h1>Topological Phases of Matter in a Condensed-Mathematics Paradigm</h1>
        <p className="lede">
          Topological phase transitions and topological phases of matter, developed as components of a
          condensed moduli stack of gapped local Hamiltonians — from Clausen&ndash;Scholze condensed
          mathematics to an invertible phase spectrum, built module by module.
        </p>

        <div className="spine">
          {SPINE.map((s, i) => (
            <span key={s.label} style={{ display: 'contents' }}>
              <span className="spine-box">
                <span className="symbol" dangerouslySetInnerHTML={{ __html: s.rendered }} />
                <span className="label">{s.label}</span>
              </span>
              {i < SPINE.length - 1 && <span className="spine-arrow" aria-hidden="true">⇝</span>}
            </span>
          ))}
        </div>
      </section>

      <div className="container">
        <div className="featured-heading">
          <h2 className="section-heading" style={{ margin: 0, border: 'none', padding: 0 }}>
            Capstone
          </h2>
        </div>
        <PaperCard paper={synthesis} featured />

        <h2 className="section-heading">The five modules</h2>
        <div className="papers-grid">
          {modules.map((p) => (
            <PaperCard key={p.slug} paper={p} />
          ))}
        </div>
      </div>
    </main>
  );
}
