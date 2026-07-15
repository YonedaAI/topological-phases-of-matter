import type { Metadata } from 'next';
import { Space_Grotesk, Inter, JetBrains_Mono } from 'next/font/google';
import 'katex/dist/katex.min.css';
import './globals.css';

const spaceGrotesk = Space_Grotesk({
  subsets: ['latin'],
  variable: '--font-space-grotesk',
  display: 'swap',
});
const inter = Inter({
  subsets: ['latin'],
  variable: '--font-inter',
  display: 'swap',
});
const jetbrainsMono = JetBrains_Mono({
  subsets: ['latin'],
  variable: '--font-jetbrains-mono',
  display: 'swap',
});

// The Vercel project for this site is created under exactly this name in the
// deploy step, so this is a safe hardcoded fallback — NEXT_PUBLIC_SITE_URL
// still overrides it if set, and Vercel's own auto-detected production URL
// (when present at build time) takes precedence over the hardcoded value.
// Static export must never ship a localhost URL in its OG/canonical tags.
const PRODUCTION_URL = 'https://topological-phases-of-matter.vercel.app';
const siteUrl =
  process.env.NEXT_PUBLIC_SITE_URL ||
  (process.env.VERCEL_PROJECT_PRODUCTION_URL
    ? `https://${process.env.VERCEL_PROJECT_PRODUCTION_URL}`
    : PRODUCTION_URL);

const SITE_NAME = 'Topological Phases of Matter';
const SITE_DESCRIPTION =
  'Topological phase transitions and topological phases of matter within a condensed-mathematics paradigm — a six-part modular research program from local quantum interactions to the invertible condensed phase spectrum.';

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: { default: SITE_NAME, template: `%s · ${SITE_NAME}` },
  description: SITE_DESCRIPTION,
  openGraph: {
    type: 'website',
    siteName: SITE_NAME,
    title: SITE_NAME,
    description: SITE_DESCRIPTION,
    url: '/',
    images: [{ url: '/og/og-default.png', width: 1200, height: 630, alt: SITE_NAME }],
  },
  twitter: {
    card: 'summary_large_image',
    title: SITE_NAME,
    description: SITE_DESCRIPTION,
    images: ['/og/og-default.png'],
  },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en" className={`${spaceGrotesk.variable} ${inter.variable} ${jetbrainsMono.variable}`}>
      <body>
        <header className="site-header">
          <a href="/" className="brand" style={{ textDecoration: 'none' }}>
            <strong>Topological Phases of Matter</strong>
            <span>Condensed-mathematics research program</span>
          </a>
          <nav aria-label="Primary">
            <a href="/">Papers</a>
            <a href="https://github.com/YonedaAI/topological-phases-of-matter" target="_blank" rel="noreferrer">
              GitHub
            </a>
          </nav>
        </header>

        {children}

        <footer className="site-footer">
          <p>Matthew Long &middot; YonedaAI Research Collective &middot; Chicago, IL</p>
          <p style={{ marginTop: '0.4rem' }}>
            <a href="https://github.com/YonedaAI/topological-phases-of-matter" target="_blank" rel="noreferrer">
              github.com/YonedaAI/topological-phases-of-matter
            </a>
          </p>
        </footer>
      </body>
    </html>
  );
}
