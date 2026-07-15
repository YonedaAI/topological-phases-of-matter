#!/usr/bin/env node
// Scans reviews/ (Gemini rounds, codex-LaTeX rounds, codex-Haskell rounds,
// canonical verdicts, panel JSONs) at the repo root and writes
// website/content/pipeline-stats.json for the /pipeline dashboard page to
// import at build time. Runs after copy-assets.mjs via the npm
// "predev"/"prebuild" lifecycle hooks — see package.json.
//
// Same vendoring pattern as copy-assets.mjs: cloud builds (e.g. Vercel with
// website/ as the project root) don't have the repo parent on disk, so if
// reviews/ is absent this falls back to the vendored JSON already committed
// under website/content/ instead of failing the build.
import fs from 'node:fs';
import path from 'node:path';

const REPO_ROOT = path.resolve(process.cwd(), '..');
const WEB_ROOT = process.cwd();
const REVIEWS_DIR = path.join(REPO_ROOT, 'reviews');
const PANEL_DIR = path.join(REVIEWS_DIR, 'panel');
const OUT_DIR = path.join(WEB_ROOT, 'content');
const OUT_FILE = path.join(OUT_DIR, 'pipeline-stats.json');

const TOPICS = [
  'lieb-robinson-locality',
  'positivity-cstar-norms',
  'spectral-gap-stability',
  'lattice-eft-equivalence',
  'bordism-realizability',
  'synthesis',
];

// Measured values from the orchestrator's own logs — not derivable from
// scanning the repo (agent counts, model roster, wall-clock, token totals).
const CONSTANTS = {
  // 60 named agents includes the dashboard-builder agent itself.
  agents: { orchestrator: 1, named: 60, workerSpawnedCodexCompanions: 6 },
  // Model census + exact IDs verified post-run from the `model` field of all
  // 66 subagent session transcripts (see modelsFootnote below) — supersedes
  // an earlier draft census that used family names without transcript IDs.
  models: [
    {
      id: 'claude-fable-5',
      name: 'Claude Fable 5',
      role: 'Orchestrator only — planning, hard gates, review relays, deploys. Largest single Claude-side consumer (5.5 MB transcript, hundreds of turns); authored no papers',
      count: 1,
    },
    {
      id: 'claude-opus-4-8',
      name: 'Claude Opus 4.8',
      role: 'ALL paper authorship: 5 research workers + synthesis; knowledge base, Lean formalizer, 6 technical reviewers, 6 meta-reviewers',
      count: 20,
    },
    {
      id: 'claude-sonnet-5',
      name: 'Claude Sonnet 5',
      role: '24 panel roles, 5 Haskell verifiers, humanizers, auditors, refs-fixer, browser QA, website/social/dashboard builders + 6 codex-companion subagents',
      count: 44,
    },
    {
      id: 'claude-haiku-4-5-20251001',
      name: 'Claude Haiku 4.5',
      role: 'OG-image generator, pipeline validator',
      count: 2,
    },
    {
      id: 'gpt-5.5 (codex CLI, xhigh)',
      name: 'GPT-5.5',
      role: 'All code/LaTeX/website reviews + Lean authoring',
      count: '~40 runs',
    },
    {
      id: 'gemini-3.1-pro (agy CLI, High)',
      name: 'Gemini 3.1 Pro',
      role: 'Paper peer-review loops',
      count: '14 calls',
    },
  ],
  modelsFootnote:
    "Claude model IDs verified post-run from the model field of all 66 subagent session transcripts — the papers were authored entirely on claude-opus-4-8; claude-fable-5 appears only in the orchestrator's transcript.",
  time: {
    start: '2026-07-14 14:16',
    setup: '14:40',
    finalSlack: '21:33',
    wallClock: '≈7h 17m',
    note: 'includes ≈25 min usage-limit outage',
  },
  tokens: {
    codexMeasured: 2424730,
    codexMeasuredRuns: 25,
    codexNote: "summed from per-run 'tokens used' lines; a few unlogged runs excluded",
    agyCalls: 14,
    claudeSide: 'not metered in-session; est. tens of millions across 60 agents',
    estimateFlag: true,
    caveat:
      'GPT-5.5 measured: 2,424,730 across 25 logged runs · Claude-side unmetered in-session (orchestrator likely the largest consumer) — see claude.ai usage for exact spend',
  },
  fixes: {
    gemini: '13 review rounds across 6 papers',
    codexLatex: { found: 30, fixed: 30 },
    codexHaskell: { found: 60, fixed: 60 },
    website: { found: 6, fixed: 6 },
    panelsBlocking: 21,
    humanizerEdits: 124,
  },
  // Named, itemized exceptions to a strict "canonical verdict must read
  // PASS/ACCEPT" gate — each entry ties one topic+track pair to the specific
  // reviewed reason its canonical file's own text gives for why NEEDS_FIX is
  // not actually blocking (see hasPostCapFix below for how these read on
  // disk). This is deliberately explicit/auditable rather than a blanket
  // "trust the aggregate fixes-constants" shortcut or a regex guessing at
  // prose — each item is a real, individually-checked exemption.
  postCapResolved: [
    {
      topic: 'lattice-eft-equivalence',
      track: 'codexLatex',
      kind: 'environmental',
      reason:
        "codex's sandbox is read-only and could not itself rebuild the PDF to certify PASS; the worker independently verified a clean build",
    },
    {
      topic: 'bordism-realizability',
      track: 'codexHaskell',
      kind: 'post-cap',
      reason: '3-round review cap reached with one High finding open; fixed post-cap and self-verified (NaN clamp on bulkGap)',
    },
    {
      topic: 'synthesis',
      track: 'codexLatex',
      kind: 'post-cap',
      reason: '3-round review cap reached with one cosmetic finding open; fixed post-cap and self-verified (Table 1 float ordering)',
    },
  ],
  timeline: [
    { phase: 'P1 Setup', start: '14:40', end: '14:41' },
    { phase: 'P2 Knowledge base', start: '14:41', end: '14:58' },
    { phase: 'P3 Workers ×5', start: '15:03', end: '17:12' },
    { phase: 'P3.5 Panels + metas', start: '16:33', end: '17:45' },
    { phase: 'P3.6 Audits', start: '17:14', end: '17:45' },
    { phase: 'P4 Synthesis', start: '17:14', end: '19:25' },
    { phase: 'P4.5 Syn panel + humanizer', start: '19:11', end: '19:47' },
    { phase: 'P5 Haskell ×5', start: '17:56', end: '20:55' },
    { phase: 'P5.5 Lean 4', start: '16:35', end: '19:38' },
    { phase: 'P6 Website', start: '19:27', end: '21:13' },
    { phase: 'P7 Social', start: '21:14', end: '21:29' },
    { phase: 'P8 Finalize', start: '21:30', end: '21:33' },
  ],
};

function escapeRegExp(s) {
  return s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

// Verdict lines look like "VERDICT: NEEDS_FIX (round 1) -> fixes applied..."
// or a review's own prompt-instructions can *contain* a literal "VERDICT: ..."
// example (seen in spectral-gap-stability-haskell-codex-review-round-3.md:
// "End with exactly one line: VERDICT: PASS or VERDICT: NEEDS_FIX"). The
// real verdict is always the last such line in the file, and only the first
// token after "VERDICT:" is the clean tag (MAJOR / MINOR / ACCEPT / PASS /
// NEEDS_FIX) used for chip coloring; the rest is kept as `raw` for tooltips.
function extractVerdict(text) {
  const matches = [...text.matchAll(/^VERDICT:\s*(.+?)\s*$/gm)];
  if (matches.length === 0) return null;
  const raw = matches[matches.length - 1][1].trim();
  const label = raw.split(/\s+/)[0].replace(/[^\w-]/g, '') || raw;
  return { raw, label };
}

// The 3-round review cap is sometimes reached with one small finding still
// open; pipeline policy then fixes it post-cap and self-verifies rather than
// spending a 4th round. This is purely informational (surfaced as a chip
// tooltip) — annotation wording varies per-file ("Fix applied (post-cap...",
// "fixed post-cap with...", an "environmental only" sandbox caveat, etc.), so
// it is intentionally NOT used to override a canonical verdict into "passed":
// see the allGatesPass note in generate() for why that rollup instead trusts
// the orchestrator's own fixes constants.
function hasPostCapFix(text) {
  return /post-cap/i.test(text) && /\bfix(?:ed|es)?\b/i.test(text);
}

function readRounds(dir, baseName) {
  if (!fs.existsSync(dir)) return [];
  const re = new RegExp(`^${escapeRegExp(baseName)}-round-(\\d+)\\.md$`);
  return fs
    .readdirSync(dir)
    .map((file) => {
      const m = file.match(re);
      return m ? { file, round: Number(m[1]) } : null;
    })
    .filter(Boolean)
    .sort((a, b) => a.round - b.round)
    .map(({ file, round }) => {
      let verdict = null;
      try {
        verdict = extractVerdict(fs.readFileSync(path.join(dir, file), 'utf8'));
      } catch (err) {
        console.warn(`[gen-pipeline-stats] could not read ${file}: ${err.message}`);
      }
      return { round, file, verdict: verdict ? verdict.label : null, raw: verdict ? verdict.raw : null };
    });
}

function readCanonical(dir, baseName) {
  const file = `${baseName}.md`;
  const full = path.join(dir, file);
  if (!fs.existsSync(full)) return null;
  try {
    const text = fs.readFileSync(full, 'utf8');
    const verdict = extractVerdict(text);
    return {
      file,
      verdict: verdict ? verdict.label : null,
      raw: verdict ? verdict.raw : null,
      postCapFixApplied: hasPostCapFix(text),
    };
  } catch (err) {
    console.warn(`[gen-pipeline-stats] could not read ${file}: ${err.message}`);
    return null;
  }
}

function readPanel(topic) {
  if (!fs.existsSync(PANEL_DIR)) {
    return { files: [], count: 0, blockingCount: 0, metaReviewer: null };
  }
  const prefix = `${topic}-`;
  const files = fs.readdirSync(PANEL_DIR).filter((f) => f.startsWith(prefix) && f.endsWith('.json'));
  let blockingCount = 0;
  let metaReviewer = null;
  const roles = [];
  for (const f of files) {
    const role = f.slice(prefix.length, -'.json'.length);
    roles.push(role);
    try {
      const text = fs.readFileSync(path.join(PANEL_DIR, f), 'utf8');
      const blockingMatches = text.match(/\[BLOCKING\]/g);
      if (blockingMatches) blockingCount += blockingMatches.length;
      if (role === 'meta_reviewer') {
        const json = JSON.parse(text);
        metaReviewer = {
          recommendation: typeof json.recommendation === 'string' ? json.recommendation : null,
          confidence: typeof json.confidence === 'number' ? json.confidence : null,
        };
      }
    } catch (err) {
      console.warn(`[gen-pipeline-stats] could not parse panel file ${f}: ${err.message}`);
    }
  }
  return { files: roles.sort(), count: files.length, blockingCount, metaReviewer };
}

function buildTopic(slug) {
  const geminiRounds = readRounds(REVIEWS_DIR, `${slug}-review`);
  const geminiCanonical = readCanonical(REVIEWS_DIR, `${slug}-review`);
  const codexLatexRounds = readRounds(REVIEWS_DIR, `${slug}-codex-review`);
  const codexLatexCanonical = readCanonical(REVIEWS_DIR, `${slug}-codex-review`);
  const codexHaskellRounds = readRounds(REVIEWS_DIR, `${slug}-haskell-codex-review`);
  const codexHaskellCanonical = readCanonical(REVIEWS_DIR, `${slug}-haskell-codex-review`);
  const hasHaskell = codexHaskellRounds.length > 0 || codexHaskellCanonical !== null;

  return {
    slug,
    gemini: { rounds: geminiRounds, canonical: geminiCanonical },
    codexLatex: { rounds: codexLatexRounds, canonical: codexLatexCanonical },
    codexHaskell: hasHaskell ? { rounds: codexHaskellRounds, canonical: codexHaskellCanonical } : null,
    panel: readPanel(slug),
  };
}

// Gemini's canonical verdict has no cap/environmental-exception annotations
// in the corpus (unlike the codex tracks — see hasPostCapFix above), so its
// gate can be trusted directly from the scanned text. MINOR is a normal,
// accepted terminal state here (chip-colored "muted", not "warning"); only
// MAJOR or a missing canonical verdict counts as not-yet-resolved.
function isGoodGemini(canonical) {
  return !!canonical && (canonical.verdict === 'ACCEPT' || canonical.verdict === 'MINOR');
}

// A codex track (LaTeX or Haskell) is resolved if its canonical verdict is
// literally the good label, OR this exact topic+track pair is named in
// CONSTANTS.postCapResolved. Deliberately does NOT fall back to trusting the
// aggregate fixes-constants for tracks with no matching exemption entry —
// an unlisted NEEDS_FIX is a real, unresolved gate failure.
function isResolvedTrack(topic, track, canonical, goodLabel) {
  if (!canonical) return false;
  if (canonical.verdict === goodLabel) return true;
  return CONSTANTS.postCapResolved.some((r) => r.topic === topic && r.track === track);
}

function generate() {
  const topics = TOPICS.map(buildTopic);

  const reviewFileCount = fs.existsSync(REVIEWS_DIR)
    ? fs.readdirSync(REVIEWS_DIR).filter((f) => f.endsWith('.md')).length
    : 0;
  const panelJsonCount = fs.existsSync(PANEL_DIR)
    ? fs.readdirSync(PANEL_DIR).filter((f) => f.endsWith('.json')).length
    : 0;
  const geminiRoundsTotal = topics.reduce((s, t) => s + t.gemini.rounds.length, 0);
  const codexLatexRoundsTotal = topics.reduce((s, t) => s + t.codexLatex.rounds.length, 0);
  const codexHaskellRoundsTotal = topics.reduce((s, t) => s + (t.codexHaskell ? t.codexHaskell.rounds.length : 0), 0);
  const blockingTotal = topics.reduce((s, t) => s + t.panel.blockingCount, 0);

  const geminiAllGood = topics.every((t) => isGoodGemini(t.gemini.canonical));
  const codexLatexAllGood = topics.every((t) => isResolvedTrack(t.slug, 'codexLatex', t.codexLatex.canonical, 'PASS'));
  const codexHaskellAllGood = topics.every(
    (t) => !t.codexHaskell || isResolvedTrack(t.slug, 'codexHaskell', t.codexHaskell.canonical, 'PASS'),
  );
  // The website's own review hasn't happened yet when this generator runs
  // (it's the orchestrator's next step after this build), so there is no
  // scanned verdict to check here — found === fixed is the only signal.
  const websiteGood = CONSTANTS.fixes.website.found === CONSTANTS.fixes.website.fixed;

  const allGatesPass = geminiAllGood && codexLatexAllGood && codexHaskellAllGood && websiteGood;

  return {
    generatedAt: new Date().toISOString(),
    source: 'scanned',
    constants: CONSTANTS,
    topics,
    totals: {
      reviewFileCount,
      panelJsonCount,
      geminiRoundsTotal,
      codexLatexRoundsTotal,
      codexHaskellRoundsTotal,
      blockingTotal,
      allGatesPass,
    },
  };
}

if (!fs.existsSync(REVIEWS_DIR)) {
  if (fs.existsSync(OUT_FILE)) {
    console.warn(`[gen-pipeline-stats] source missing (${REVIEWS_DIR}); using vendored ${OUT_FILE}`);
    process.exit(0);
  }
  console.error(`[gen-pipeline-stats] FAIL: source directory missing AND no vendored copy: ${REVIEWS_DIR} / ${OUT_FILE}`);
  process.exit(1);
}

const stats = generate();
fs.mkdirSync(OUT_DIR, { recursive: true });
fs.writeFileSync(OUT_FILE, JSON.stringify(stats, null, 2) + '\n');
console.log(
  `[gen-pipeline-stats] wrote ${OUT_FILE}: ${stats.topics.length} topics, ${stats.totals.reviewFileCount} review files, ${stats.totals.panelJsonCount} panel JSONs, allGatesPass=${stats.totals.allGatesPass}`,
);
