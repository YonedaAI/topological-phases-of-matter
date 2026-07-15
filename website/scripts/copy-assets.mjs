#!/usr/bin/env node
// Vendors the paper sources this site is built from into website/ so that
// `next build` never has to reach outside its own directory: pandoc HTML
// into content/papers/ (read at build time by lib/content.ts), PDFs and
// cover images into public/ (served as static files by the export). Runs
// automatically before `npm run build` / `npm run dev` via the npm
// "predev"/"prebuild" lifecycle hooks — see package.json.
//
// Does NOT touch public/og/ — those designed OG cards come from a separate
// generation step, not from this repo's docs/papers or images directories.
import fs from 'node:fs';
import path from 'node:path';

const REPO_ROOT = path.resolve(process.cwd(), '..');
const WEB_ROOT = process.cwd();

function copyMatching(srcDir, destDir, extension) {
  fs.mkdirSync(destDir, { recursive: true });
  const files = fs.readdirSync(srcDir).filter((f) => f.endsWith(extension));
  for (const file of files) {
    fs.copyFileSync(path.join(srcDir, file), path.join(destDir, file));
  }
  return files.length;
}

const jobs = [
  { src: path.join(REPO_ROOT, 'docs', 'papers'), dest: path.join(WEB_ROOT, 'content', 'papers'), ext: '.html' },
  { src: path.join(REPO_ROOT, 'papers', 'pdf'), dest: path.join(WEB_ROOT, 'public', 'pdf'), ext: '.pdf' },
  { src: path.join(REPO_ROOT, 'images'), dest: path.join(WEB_ROOT, 'public', 'images'), ext: '.png' },
];

for (const { src, dest, ext } of jobs) {
  if (!fs.existsSync(src)) {
    // Cloud builds (e.g. Vercel with website/ as the project root) don't have
    // the repo parent on disk; the vendored copies committed under website/
    // are then the source of truth. Only fail when neither exists.
    const vendored = fs.existsSync(dest)
      ? fs.readdirSync(dest).filter((f) => f.endsWith(ext)).length
      : 0;
    if (vendored > 0) {
      console.warn(`[copy-assets] source missing (${src}); using ${vendored} vendored ${ext} file(s) already in ${dest}`);
      continue;
    }
    console.error(`[copy-assets] FAIL: source directory missing AND no vendored copies: ${src} / ${dest}`);
    process.exit(1);
  }
  const count = copyMatching(src, dest, ext);
  console.log(`[copy-assets] ${src} -> ${dest}: ${count} ${ext} file(s)`);
}
