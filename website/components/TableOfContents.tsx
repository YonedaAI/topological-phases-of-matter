'use client';

import { useEffect, useState } from 'react';

export interface TocHeading {
  id: string;
  text: string;
  level: 2 | 3;
}

// IntersectionObserver-based active-section tracking goes stale once a
// heading has scrolled past the viewport (nothing intersects any more).
// Instead, on every scroll we walk the headings top-to-bottom and keep the
// last one whose offsetTop is still above the scroll position.
export function TableOfContents({ headings }: { headings: TocHeading[] }) {
  const [activeId, setActiveId] = useState('');
  const [mobileOpen, setMobileOpen] = useState(false);

  useEffect(() => {
    const onScroll = () => {
      const scrollY = window.scrollY + 120;
      let current = '';
      for (const { id } of headings) {
        const el = document.getElementById(id);
        if (el && el.offsetTop <= scrollY) current = id;
      }
      setActiveId(current);
    };
    window.addEventListener('scroll', onScroll, { passive: true });
    onScroll();
    return () => window.removeEventListener('scroll', onScroll);
  }, [headings]);

  if (headings.length === 0) return null;

  const renderList = () => (
    <ul className="toc-list" style={{ listStyle: 'none', margin: 0, padding: 0 }}>
      {headings.map(({ id, text, level }) => (
        <li key={id}>
          <a
            href={`#${id}`}
            className={[level === 3 ? 'toc-sub' : '', activeId === id ? 'toc-active' : ''].join(' ').trim()}
            onClick={() => setMobileOpen(false)}
          >
            {text}
          </a>
        </li>
      ))}
    </ul>
  );

  return (
    <>
      <aside className="paper-toc" aria-labelledby="toc-heading">
        <div className="paper-toc-title" id="toc-heading">
          Contents
        </div>
        {renderList()}
      </aside>

      <div className="paper-toc-toggle">
        <button
          type="button"
          className="btn"
          onClick={() => setMobileOpen((v) => !v)}
          aria-expanded={mobileOpen}
          aria-controls="toc-mobile-panel"
        >
          {mobileOpen ? 'Hide contents ▲' : 'Contents ▾'}
        </button>
        <div className="toc-mobile-panel" id="toc-mobile-panel" hidden={!mobileOpen}>
          {renderList()}
        </div>
      </div>
    </>
  );
}
