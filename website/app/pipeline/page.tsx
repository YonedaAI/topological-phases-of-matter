import type { Metadata } from 'next';
import theme from '../../theme.json';
import { papers } from '../../lib/papers';
import { pipelineStats } from '../../lib/pipeline-stats';
import type { ReviewTrack, TopicStats, PhaseEntry } from '../../lib/pipeline-stats';

const PAGE_DESCRIPTION =
  "How this six-part research program was produced — agents, models, review loops, and the build timeline, regenerated from the repository's own review artifacts at build time.";

export const metadata: Metadata = {
  title: 'Pipeline',
  description: PAGE_DESCRIPTION,
  openGraph: {
    title: 'Pipeline Statistics',
    description: PAGE_DESCRIPTION,
    type: 'article',
    url: '/pipeline/',
    images: [{ url: '/og/og-default.png', width: 1200, height: 630 }],
  },
  twitter: {
    card: 'summary_large_image',
    title: 'Pipeline Statistics',
    description: PAGE_DESCRIPTION,
    images: ['/og/og-default.png'],
  },
  alternates: { canonical: '/pipeline/' },
};

function partAccentClass(part: string): string {
  const m = part.match(/Part\s+([IVX]+)/i);
  const key = m ? m[1].toUpperCase() : 'I';
  const accent = (theme.partAccent as Record<string, string>)[key] ?? 'accent';
  return accent === 'accent' ? '' : accent;
}

type Tone = 'accent' | 'warning' | 'muted';

function verdictTone(verdict: string | null): Tone {
  if (!verdict) return 'muted';
  const v = verdict.toUpperCase();
  if (v === 'ACCEPT' || v === 'PASS') return 'accent';
  if (v === 'MAJOR' || v === 'NEEDS_FIX') return 'warning';
  return 'muted';
}

function Chip({ label, tone, title }: { label: string; tone: Tone; title?: string | null }) {
  return (
    <span className={`chip ${tone}`} title={title ?? undefined}>
      {label}
    </span>
  );
}

function Trajectory({ track, fallback }: { track: ReviewTrack | null; fallback?: string }) {
  if (!track) return <span className="loop-meta">{fallback ?? 'n/a'}</span>;

  const items = track.rounds.map((r) => ({ label: r.verdict ?? '—', title: r.raw }));
  const lastLabel = items.length ? items[items.length - 1].label : null;
  if (track.canonical?.verdict && track.canonical.verdict !== lastLabel) {
    items.push({ label: track.canonical.verdict, title: track.canonical.raw });
  }
  if (items.length === 0) return <span className="loop-meta">no rounds recorded</span>;

  return (
    <div className="loop-chips">
      {items.map((it, i) => (
        <span key={i} style={{ display: 'contents' }}>
          {i > 0 && (
            <span className="loop-arrow" aria-hidden="true">
              &rarr;
            </span>
          )}
          <Chip label={it.label} tone={verdictTone(it.label)} title={it.title} />
        </span>
      ))}
    </div>
  );
}

function TopicLoop({ topic }: { topic: TopicStats }) {
  const paper = papers.find((p) => p.slug === topic.slug);
  const title = paper?.title ?? topic.slug;
  const part = paper?.part ?? '';
  const recommendation = topic.panel.metaReviewer?.recommendation?.replace(/_/g, ' ') ?? null;

  return (
    <div className="loop-strip">
      <div className="loop-strip-head">
        {part && <span className={`part-badge ${partAccentClass(part)}`}>{part}</span>}
        <h3>{title}</h3>
      </div>

      <div className="loop-row">
        <span className="row-label">Gemini</span>
        <Trajectory track={topic.gemini} />
      </div>

      <div className="loop-row">
        <span className="row-label">Codex &middot; LaTeX</span>
        <Trajectory track={topic.codexLatex} />
      </div>

      <div className="loop-row">
        <span className="row-label">Panel</span>
        <div className="loop-chips">
          <Chip
            label={`${topic.panel.blockingCount} blocking`}
            tone={topic.panel.blockingCount > 0 ? 'warning' : 'accent'}
          />
          <span className="loop-arrow" aria-hidden="true">
            &rarr;
          </span>
          <Chip label="re-verified" tone="accent" />
          {recommendation && <span className="loop-meta">({recommendation})</span>}
        </div>
      </div>

      {topic.codexHaskell && (
        <div className="loop-row">
          <span className="row-label">Codex &middot; Haskell</span>
          <Trajectory track={topic.codexHaskell} />
        </div>
      )}
    </div>
  );
}

function WebsiteLoop() {
  const { found, fixed } = pipelineStats.constants.fixes.website;
  const resolved = found === fixed;
  return (
    <div className="loop-strip">
      <div className="loop-strip-head">
        <span className="part-badge warning">Site</span>
        <h3>Website build review</h3>
      </div>
      <div className="loop-row">
        <span className="row-label">Codex &middot; Website</span>
        <div className="loop-chips">
          <Chip label={`${found} found`} tone="warning" />
          <span className="loop-arrow" aria-hidden="true">
            &rarr;
          </span>
          <Chip label={`${fixed} fixed`} tone="accent" />
          <span className="loop-arrow" aria-hidden="true">
            &rarr;
          </span>
          <Chip label={resolved ? 'PASS' : 'NEEDS_FIX'} tone={resolved ? 'accent' : 'warning'} />
        </div>
      </div>
    </div>
  );
}

function toMinutes(hhmm: string): number {
  const [h, m] = hhmm.split(':').map(Number);
  return h * 60 + m;
}

function formatHour(min: number): string {
  const h = Math.floor(min / 60) % 24;
  return `${String(h).padStart(2, '0')}:00`;
}

function Gantt({ timeline }: { timeline: PhaseEntry[] }) {
  const rulerStart = toMinutes('14:00');
  const rulerEnd = toMinutes('22:00');
  const totalMin = rulerEnd - rulerStart;

  const leftPad = 195;
  const rightPad = 20;
  const topPad = 30;
  const bottomPad = 12;
  const rowH = 27;
  const rowGap = 5;
  const barH = rowH - rowGap;
  const plotW = 750;
  const plotH = timeline.length * rowH;
  const width = leftPad + plotW + rightPad;
  const height = topPad + plotH + bottomPad;

  const minutesToX = (min: number) => leftPad + ((min - rulerStart) / totalMin) * plotW;
  const hourTicks: number[] = [];
  for (let t = rulerStart; t <= rulerEnd; t += 60) hourTicks.push(t);

  return (
    <div className="gantt-wrap">
      <svg viewBox={`0 0 ${width} ${height}`} role="img" aria-label="Pipeline phase timeline from 14:00 to 22:00">
        {hourTicks.map((t) => (
          <g key={t}>
            <line
              x1={minutesToX(t)}
              y1={topPad - 8}
              x2={minutesToX(t)}
              y2={topPad + plotH}
              stroke="var(--border)"
              strokeWidth={1}
            />
            <text
              x={minutesToX(t)}
              y={topPad - 13}
              fontSize={10.5}
              fill="var(--text-dim)"
              textAnchor="middle"
              fontFamily="var(--font-mono)"
            >
              {formatHour(t)}
            </text>
          </g>
        ))}

        {timeline.map((p, i) => {
          const y = topPad + i * rowH + rowGap / 2;
          const x = minutesToX(toMinutes(p.start));
          const w = Math.max(6, minutesToX(toMinutes(p.end)) - x);
          return (
            <g key={p.phase}>
              <text
                x={leftPad - 10}
                y={y + barH / 2 + 4}
                fontSize={11}
                fill="var(--text-muted)"
                textAnchor="end"
                fontFamily="var(--font-body)"
              >
                {p.phase}
              </text>
              <rect x={x} y={y} width={w} height={barH} rx={5} fill="var(--accent)" fillOpacity={0.85}>
                <title>{`${p.phase}: ${p.start}–${p.end}`}</title>
              </rect>
            </g>
          );
        })}
      </svg>
    </div>
  );
}

export default function PipelinePage() {
  const { constants, totals, topics } = pipelineStats;
  const codexModel = constants.models.find((m) => m.name.startsWith('GPT-5.5'));
  const tokensM = (constants.tokens.codexMeasured / 1e6).toFixed(2);
  const modelFamilies = Array.from(new Set(constants.models.map((m) => m.name.split(' ')[0]))).join(' · ');
  const tokensStatusLabel = constants.tokens.estimateFlag ? 'Estimate only' : 'Measured';
  const exemptions = constants.postCapResolved;
  const postCapCount = exemptions.filter((e) => e.kind === 'post-cap').length;
  const environmentalCount = exemptions.filter((e) => e.kind === 'environmental').length;
  const gateLabel = !totals.allGatesPass
    ? 'Gates pending'
    : exemptions.length === 0
      ? 'All gates PASS'
      : 'All gates closed';
  const gateNote =
    totals.allGatesPass && exemptions.length > 0
      ? [
          postCapCount > 0 ? `${postCapCount} post-cap fix${postCapCount === 1 ? '' : 'es'}` : null,
          environmentalCount > 0 ? `${environmentalCount} environmental` : null,
        ]
          .filter(Boolean)
          .join(', ') + ' — see below'
      : null;
  const exemptionTitle =
    exemptions.length > 0 ? exemptions.map((e) => `${e.topic} (${e.track}): ${e.reason}`).join('\n') : undefined;

  return (
    <main>
      <div className="pipeline-header">
        <span className="kicker">Build provenance</span>
        <h1>Pipeline Statistics</h1>
        <p className="lede">
          Every paper in this program passed through the same loop: draft, Gemini peer review, a Codex LaTeX
          formatting pass, a five-role review panel, and — where the paper ships code — a Codex Haskell
          verification pass. The numbers below are regenerated from the repository&rsquo;s own review artifacts
          each time the site is built.
        </p>
      </div>

      <div className="container">
        <div className="stat-grid">
          <div className="stat-tile">
            <div className="value">{constants.agents.named}</div>
            <div className="label">Named agents</div>
            <div className="note">
              +{constants.agents.orchestrator} orchestrator &middot; +{constants.agents.workerSpawnedCodexCompanions}{' '}
              codex companions
            </div>
          </div>
          <div className="stat-tile">
            <div className="value">{constants.models.length}</div>
            <div className="label">Model families</div>
            <div className="note">{modelFamilies}</div>
          </div>
          <div className="stat-tile">
            <div className="value">{constants.time.wallClock}</div>
            <div className="label">Wall-clock</div>
            <div className="note">{constants.time.note}</div>
          </div>
          <div className="stat-tile">
            <div className="value">{`${tokensM}M`}</div>
            <div className="label">Measured GPT-5.5 tokens</div>
            <div className="note">{constants.tokens.codexMeasuredRuns} logged codex runs</div>
          </div>
          <div className="stat-tile caveat">
            <div className="value">{tokensStatusLabel}</div>
            <div className="label">Claude-side tokens</div>
            <div className="note">{constants.tokens.caveat}</div>
          </div>
        </div>

        <h2 className="section-heading">Models</h2>
        <div className="pipeline-table-wrap">
          <table className="pipeline-table">
            <thead>
              <tr>
                <th scope="col">Model</th>
                <th scope="col">Role</th>
                <th scope="col">Count</th>
              </tr>
            </thead>
            <tbody>
              {constants.models.map((m) => (
                <tr key={m.name}>
                  <td>
                    {m.name}
                    {m.id && <div className="model-id">{m.id}</div>}
                  </td>
                  <td>{m.role}</td>
                  <td className="num">{m.count}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <p className="table-footnote">{constants.modelsFootnote}</p>

        <h2 className="section-heading">The code &rarr; review &rarr; fix loop</h2>
        {topics.map((t) => (
          <TopicLoop key={t.slug} topic={t} />
        ))}
        <WebsiteLoop />

        <h2 className="section-heading">Phase timeline</h2>
        <Gantt timeline={constants.timeline} />

        <h2 className="section-heading">Review artifacts</h2>
        <div className="stat-grid">
          <div className="stat-tile">
            <div className="value">{totals.reviewFileCount}</div>
            <div className="label">Review files</div>
          </div>
          <div className="stat-tile">
            <div className="value">{totals.panelJsonCount}</div>
            <div className="label">Panel JSONs</div>
          </div>
          <div className="stat-tile">
            <div className="value">{totals.geminiRoundsTotal}</div>
            <div className="label">Gemini rounds</div>
            <div className="note">{constants.fixes.gemini}</div>
          </div>
          <div className="stat-tile">
            <div className="value">{codexModel ? codexModel.count : '—'}</div>
            <div className="label">Codex runs</div>
          </div>
          <div className="stat-tile">
            <div className="value">{constants.fixes.humanizerEdits}</div>
            <div className="label">Humanizer edits</div>
          </div>
          <div className="stat-tile">
            <div
              className="value"
              style={{ color: totals.allGatesPass ? 'var(--success)' : 'var(--warning)' }}
              title={exemptionTitle}
            >
              {gateLabel}
            </div>
            <div className="label">Review status</div>
            {gateNote && <div className="note">{gateNote}</div>}
          </div>
        </div>

        {exemptions.length > 0 && (
          <div className="exemptions-box">
            <div className="exemptions-title">Documented exceptions ({exemptions.length})</div>
            <ul>
              {exemptions.map((e) => (
                <li key={`${e.topic}-${e.track}`}>
                  <strong>{e.topic}</strong> ({e.track === 'codexLatex' ? 'Codex · LaTeX' : 'Codex · Haskell'},{' '}
                  {e.kind}): {e.reason}
                </li>
              ))}
            </ul>
          </div>
        )}
      </div>

      <p className="pipeline-footnote">
        All statistics regenerated from the repository&rsquo;s own review artifacts at build time; token figures for
        Claude agents are estimates (not metered in-session).
      </p>
    </main>
  );
}
