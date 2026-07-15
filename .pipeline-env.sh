# Research pipeline environment — sourced by orchestrator Bash blocks.
export PROJECT="topological-phases-of-matter"
export PROJECT_PATH="/Users/mlong/Documents/Development"
export PROOT="$PROJECT_PATH/$PROJECT"
export TOPICS="lieb-robinson-locality positivity-cstar-norms spectral-gap-stability lattice-eft-equivalence bordism-realizability"
export PERSPECTIVE="Topological phase transitions and topological phases of matter within a condensed-mathematics paradigm"
export GITHUB_ORG="${RESEARCH_GITHUB_ORG:-YonedaAI}"
export SLACK_CHANNEL="${RESEARCH_SLACK_CHANNEL:-C0AK269AVSA}"
export RESEARCH_AUTHOR_NAME="${RESEARCH_AUTHOR_NAME:-Matthew Long}"
export RESEARCH_AUTHOR_EMAIL="${RESEARCH_AUTHOR_EMAIL:-matthew@yonedaai.com}"
export RESEARCH_AUTHOR_URL="${RESEARCH_AUTHOR_URL:-https://yonedaai.com}"
export RESEARCH_COLLABORATION="${RESEARCH_COLLABORATION:-The YonedaAI Collaboration}"
export RESEARCH_INSTITUTION="${RESEARCH_INSTITUTION:-YonedaAI Research Collective}"
export RESEARCH_LOCATION="${RESEARCH_LOCATION:-Chicago, IL}"
export RESEARCH_GEMINI_MODEL="${RESEARCH_GEMINI_MODEL:-gemini-3.1-pro}"
export RESEARCH_GEMINI_BIN="${RESEARCH_GEMINI_BIN:-/Users/mlong/.local/bin/agy-review-shim}"
export RESEARCH_CODEX_BIN="${RESEARCH_CODEX_BIN:-/Users/mlong/.local/share/fnm/node-versions/v24.14.0/installation/bin/codex}"
export RESEARCH_GIT_AUTHOR="${RESEARCH_GIT_AUTHOR:-Matthew <mlong@magneton.io>}"

# Resolve gemini + codex to absolute paths (fnm shims aren't active in agent subshells)
GEMINI="$RESEARCH_GEMINI_BIN"
CODEX="$RESEARCH_CODEX_BIN"
[ -x "$GEMINI" ] || GEMINI="$(command -v gemini 2>/dev/null || echo gemini)"
[ -x "$CODEX" ]  || CODEX="$(command -v codex  2>/dev/null || echo codex)"
export GEMINI CODEX
export PATH="$(dirname "$CODEX"):$PATH"

# Strict review gate — per skill Phase 3/4. Usage: review_gate_check <topic>
review_gate_check() {
  local topic="$1"
  local size csize rounds final_verdict
  test -f "reviews/$topic-review-round-1.md" || { echo "FAIL ($topic): round-1 MISSING — Gemini skipped"; return 1; }
  ! grep -q "^SKIPPED:" "reviews/$topic-review-round-1.md" || { echo "FAIL ($topic): round-1 is a SKIPPED stub"; return 1; }
  size=$(wc -c < "reviews/$topic-review-round-1.md")
  [ "$size" -ge 500 ] || { echo "FAIL ($topic): round-1 only ${size}B"; return 1; }
  test -f "reviews/$topic-review.md" || { echo "FAIL ($topic): canonical review MISSING"; return 1; }
  ! grep -q "^SKIPPED:" "reviews/$topic-review.md" || { echo "FAIL ($topic): canonical review is a SKIPPED stub"; return 1; }
  grep -q "VERDICT:" "reviews/$topic-review.md" || { echo "FAIL ($topic): no VERDICT line"; return 1; }
  final_verdict=$(tail -20 "reviews/$topic-review.md" | grep -i "VERDICT" | tail -1)
  rounds=$(ls reviews/$topic-review-round-*.md 2>/dev/null | wc -l | tr -d ' ')
  case "$final_verdict" in
    *ACCEPT*|*MINOR*) ;;
    *) if [ "$rounds" -lt 4 ]; then echo "FAIL ($topic): verdict='$final_verdict' with only $rounds round(s)"; return 1; fi ;;
  esac
  test -f "reviews/$topic-codex-review.md" || { echo "FAIL ($topic): codex review MISSING"; return 1; }
  ! grep -q "^SKIPPED:" "reviews/$topic-codex-review.md" || { echo "FAIL ($topic): codex review is a SKIPPED stub"; return 1; }
  csize=$(wc -c < "reviews/$topic-codex-review.md")
  [ "$csize" -ge 500 ] || { echo "FAIL ($topic): codex review only ${csize}B"; return 1; }
  grep -q "VERDICT:" "reviews/$topic-codex-review.md" || { echo "FAIL ($topic): codex review has no VERDICT line"; return 1; }
  echo "PASS ($topic): Gemini=$rounds round(s) verdict='$final_verdict', Codex=${csize}B"
  return 0
}

# Artifact check — companion to the review gate. Usage: artifact_check <topic>
artifact_check() {
  local topic="$1"; local ok=0
  test -f "papers/latex/$topic.tex" && echo "TEX: $(wc -l < papers/latex/$topic.tex) lines" || { echo "TEX MISSING"; ok=1; }
  if test -f "papers/pdf/$topic.pdf"; then
    echo "PDF OK ($(pdfinfo papers/pdf/$topic.pdf 2>/dev/null | awk '/^Pages/{print $2}') pages)"
    test "papers/pdf/$topic.pdf" -nt "papers/latex/$topic.tex" && echo "PDF CURRENT" || { echo "PDF STALE"; ok=1; }
  else echo "PDF MISSING"; ok=1; fi
  test -f "images/$topic.png" && echo "COVER OK" || { echo "COVER MISSING"; ok=1; }
  echo "HS files: $(ls src/$topic/*.hs 2>/dev/null | wc -l | tr -d ' ')"
  test -f "coordination/abstracts/$topic.md" && echo "ABSTRACT POSTED" || echo "ABSTRACT MISSING"
  return $ok
}

# Slack message linter — call before every slack_send_message tool invocation.
# Usage: slack_lint_msg "$MSG" || { echo "fix the message before sending"; exit 1; }
slack_lint_msg() {
  local msg="$1"
  local fail=0
  local bare
  bare=$(printf '%s\n' "$msg" | grep -nE '(^|[^<])(https?://[^[:space:]<>]+)' || true)
  if [ -n "$bare" ]; then
    echo "slack_lint: FAIL bare URL(s) — wrap in <...>:"
    printf '%s\n' "$bare" | sed 's/^/  /'
    fail=1
  fi
  local bleed
  bleed=$(printf '%s\n' "$msg" | grep -nE 'https?://[^[:space:]<>]+[[:space:]]+\*[A-Za-z]' || true)
  if [ -n "$bleed" ]; then
    echo "slack_lint: FAIL URL followed by '*Word' marker — link will absorb the marker:"
    printf '%s\n' "$bleed" | sed 's/^/  /'
    fail=1
  fi
  local unbalanced
  unbalanced=$(printf '%s\n' "$msg" | awk -F'\\*' '/\*/ { if ((NF-1) % 2 != 0) print NR": "$0 }' || true)
  if [ -n "$unbalanced" ]; then
    echo "slack_lint: FAIL unbalanced '*bold*' markers (odd count of '*' on a line):"
    printf '%s\n' "$unbalanced" | sed 's/^/  /'
    fail=1
  fi
  return $fail
}
