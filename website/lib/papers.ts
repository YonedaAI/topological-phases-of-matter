import papersData from '../papers.json';

export interface Paper {
  slug: string;
  title: string;
  part: string;
  abstract: string;
  pages: number;
  hasCode: boolean;
  category: string;
}

export const papers: Paper[] = papersData as Paper[];

export function getPaper(slug: string): Paper | undefined {
  return papers.find((p) => p.slug === slug);
}

export function getAllSlugs(): string[] {
  return papers.map((p) => p.slug);
}

export interface AdjacentPapers {
  prev: Paper | null;
  next: Paper | null;
}

export function getAdjacentPapers(slug: string): AdjacentPapers {
  const index = papers.findIndex((p) => p.slug === slug);
  if (index === -1) return { prev: null, next: null };
  return {
    prev: index > 0 ? papers[index - 1] : null,
    next: index < papers.length - 1 ? papers[index + 1] : null,
  };
}
