import statsData from '../content/pipeline-stats.json';

export interface VerdictRound {
  round: number;
  file: string;
  verdict: string | null;
  raw: string | null;
}

export interface CanonicalVerdict {
  file: string;
  verdict: string | null;
  raw: string | null;
  postCapFixApplied: boolean;
}

export interface ReviewTrack {
  rounds: VerdictRound[];
  canonical: CanonicalVerdict | null;
}

export interface PanelInfo {
  files: string[];
  count: number;
  blockingCount: number;
  metaReviewer: { recommendation: string | null; confidence: number | null } | null;
}

export interface TopicStats {
  slug: string;
  gemini: ReviewTrack;
  codexLatex: ReviewTrack;
  codexHaskell: ReviewTrack | null;
  panel: PanelInfo;
}

export interface ModelEntry {
  id?: string;
  name: string;
  role: string;
  count: number | string;
}

export interface PhaseEntry {
  phase: string;
  start: string;
  end: string;
}

export interface PipelineConstants {
  agents: { orchestrator: number; named: number; workerSpawnedCodexCompanions: number };
  models: ModelEntry[];
  modelsFootnote: string;
  time: { start: string; setup: string; finalSlack: string; wallClock: string; note: string };
  tokens: {
    codexMeasured: number;
    codexMeasuredRuns: number;
    codexNote: string;
    agyCalls: number;
    claudeMeasured: {
      totalAllTypes: number;
      output: number;
      cacheRead: number;
      cacheWrite: number;
      freshInput: number;
      assistantMessages: number;
      perModel: { model: string; msgs: number; output: number; allTypes: number }[];
      note: string;
    };
    claudeSide: string;
    estimateFlag: boolean;
    caveat: string;
  };
  fixes: {
    gemini: string;
    codexLatex: { found: number; fixed: number };
    codexHaskell: { found: number; fixed: number };
    website: { found: number; fixed: number };
    panelsBlocking: number;
    humanizerEdits: number;
  };
  postCapResolved: { topic: string; track: string; kind: 'environmental' | 'post-cap'; reason: string }[];
  timeline: PhaseEntry[];
}

export interface PipelineTotals {
  reviewFileCount: number;
  panelJsonCount: number;
  geminiRoundsTotal: number;
  codexLatexRoundsTotal: number;
  codexHaskellRoundsTotal: number;
  blockingTotal: number;
  allGatesPass: boolean;
}

export interface PipelineStats {
  generatedAt: string;
  source: 'scanned' | 'vendored-fallback';
  constants: PipelineConstants;
  topics: TopicStats[];
  totals: PipelineTotals;
}

export const pipelineStats = statsData as unknown as PipelineStats;

export function getTopicStats(slug: string): TopicStats | undefined {
  return pipelineStats.topics.find((t) => t.slug === slug);
}
