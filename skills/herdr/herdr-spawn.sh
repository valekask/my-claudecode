#!/usr/bin/env bash
# herdr-spawn.sh — spawn a FRESH Herdr tab (= fresh Claude session) pointed at a
# target working tree and kick off a slash command as the initial prompt.
#
# A general terminal-session primitive: it carries NO project knowledge. See
# ./SKILL.md for the why and the workflow.
#
# CONTAINMENT (default-deny): a spawned session may only start INSIDE the project
# you invoke this from — the git top-level of the invoking dir (or the invoking
# dir itself if it isn't a git repo). Anything outside is REFUSED. This stops a
# session from wandering into a sibling tree by accident. Pass --allow <path> to
# permit an additional base for a deliberate cross-tree spawn.
#
# Verified against herdr 0.7.x. The reliable "fresh tab" recipe is:
#   tab create --cwd <path>  ->  parse result.root_pane.pane_id
#   pane run <root_pane> 'claude "<prompt>"'
# (NOT `agent start`, which *splits* the current/target tab and ignores --cwd.)
#
# Usage:
#   herdr-spawn.sh --cwd <path> --label <label> --prompt '<claude prompt>' \
#       [--workspace <id>] [--focus] [--allow <path> ...]
#
# --allow <path>   (repeatable) add a permitted base beyond the current project.
#                  For the rare deliberate spawn into another tree/worktree.
#
# By default the tab is created in the SPAWNING session's own workspace
# ($HERDR_WORKSPACE_ID) — "where it was requested" — NOT whatever workspace the
# user has manually focused at the moment of the call. Override with --workspace.
#
# By default the tab is spawned in the BACKGROUND (no focus): just create it and
# kick off the work; open it manually when you need it. Pass --focus to bring the
# new tab forward.
#
# Long prompts are handled automatically: a prompt that is long, multi-line, or
# contains a double-quote is written to a temp brief file and launched with a
# short "Read <file> and follow it." pointer (a raw long prompt gets truncated by
# `pane run` and never starts claude). Slash commands are always sent inline.
#
# Example:
#   herdr-spawn.sh --cwd ~/project --label 'ticket FNA-16973' \
#     --prompt '/ticket FNA-16973'
#
# Prints one line on success (with brief=<file> when the prompt was stashed):
#   SPAWNED tab=<tab_id> pane=<pane_id> ws=<id> cwd=<abs-cwd> :: claude "<prompt>"
# so the caller can record the ids wherever it tracks sessions, and later
# focus/read/close them.

set -euo pipefail

CWD="" LABEL="" PROMPT="" WORKSPACE="" FOCUS="--no-focus"
ALLOW=()

while [ $# -gt 0 ]; do
  case "$1" in
    --cwd)       CWD="${2:?--cwd needs a value}"; shift 2 ;;
    --label)     LABEL="${2:?--label needs a value}"; shift 2 ;;
    --prompt)    PROMPT="${2:?--prompt needs a value}"; shift 2 ;;
    --workspace) WORKSPACE="${2:?--workspace needs a value}"; shift 2 ;;
    --allow)     ALLOW+=("${2:?--allow needs a value}"); shift 2 ;;
    --no-focus)  FOCUS="--no-focus"; shift ;;
    --focus)     FOCUS="--focus"; shift ;;
    *) echo "herdr-spawn: unknown arg: $1" >&2; exit 2 ;;
  esac
done

[ -n "$CWD" ]    || { echo "herdr-spawn: --cwd is required" >&2; exit 2; }
[ -n "$LABEL" ]  || { echo "herdr-spawn: --label is required" >&2; exit 2; }
[ -n "$PROMPT" ] || { echo "herdr-spawn: --prompt is required" >&2; exit 2; }

# Expand a leading ~ and resolve to an absolute, real path.
CWD="${CWD/#\~/$HOME}"
[ -d "$CWD" ] || { echo "herdr-spawn: cwd does not exist: $CWD" >&2; exit 2; }
CWD="$(cd "$CWD" && pwd -P)"

# Normalize a base path for prefix-matching: expand ~, resolve to a real path
# when it exists, else strip a trailing slash.
norm_path() {
  local p="${1/#\~/$HOME}"
  if [ -d "$p" ]; then (cd "$p" && pwd -P); else printf '%s' "${p%/}"; fi
}

# True when $1 is $2 or a subtree of $2.
path_under() {
  case "$1" in "$2"|"$2"/*) return 0 ;; *) return 1 ;; esac
}

# --- Containment guard: confine spawns to the current project (+ --allow). -----
# Default base = git top-level of the INVOKING dir ($PWD, where this script was
# called from — the spawning session's cwd), else the invoking dir itself.
DEFAULT_BASE="$(git -C "$PWD" rev-parse --show-toplevel 2>/dev/null || true)"
[ -n "$DEFAULT_BASE" ] || DEFAULT_BASE="$(pwd -P)"

ALLOWED=("$(norm_path "$DEFAULT_BASE")")
if [ "${#ALLOW[@]}" -gt 0 ]; then
  for a in "${ALLOW[@]}"; do ALLOWED+=("$(norm_path "$a")"); done
fi

OK=0
for base in "${ALLOWED[@]}"; do
  if path_under "$CWD" "$base"; then OK=1; break; fi
done
if [ "$OK" -ne 1 ]; then
  echo "herdr-spawn: REFUSED — target cwd is outside the current project." >&2
  echo "             target : $CWD" >&2
  echo "             allowed : ${ALLOWED[*]}" >&2
  echo "             (spawns are confined to the current project; pass" >&2
  echo "              --allow <path> to permit a deliberate cross-tree spawn.)" >&2
  exit 3
fi

command -v herdr >/dev/null || { echo "herdr-spawn: herdr CLI not found in PATH" >&2; exit 4; }
command -v python3 >/dev/null || { echo "herdr-spawn: python3 not found in PATH" >&2; exit 4; }

# --- 1. Fresh tab at the target cwd, in the REQUESTING session's workspace. ---
# Default to this session's own workspace ($HERDR_WORKSPACE_ID) so the tab lands
# where the spawn was requested, not in whatever workspace happens to be focused
# now. An explicit --workspace wins; if neither is resolvable, omit the flag and
# fall back to herdr's default placement.
WORKSPACE="${WORKSPACE:-${HERDR_WORKSPACE_ID:-}}"
WS_ARG=(); [ -n "$WORKSPACE" ] && WS_ARG=(--workspace "$WORKSPACE")
# ${arr[@]+"${arr[@]}"} = safe empty-array expansion under bash 3.2 + `set -u`.
TAB_JSON="$(herdr tab create ${WS_ARG[@]+"${WS_ARG[@]}"} --cwd "$CWD" --label "$LABEL" "$FOCUS")"

read -r TAB_ID PANE_ID < <(
  printf '%s' "$TAB_JSON" | python3 -c '
import sys, json
r = json.load(sys.stdin)["result"]
print(r["tab"]["tab_id"], r["root_pane"]["pane_id"])
'
) || { echo "herdr-spawn: could not parse tab create output:" >&2; echo "$TAB_JSON" >&2; exit 5; }

[ -n "${PANE_ID:-}" ] || { echo "herdr-spawn: no root pane id in tab create output" >&2; echo "$TAB_JSON" >&2; exit 5; }

# --- 2. Launch claude with the prompt as the initial (auto-submitted) prompt. -
# pane run sends the text + Enter atomically. The double-quotes are literal so
# the spawned shell passes the whole prompt to claude as one positional arg.
#
# Long / unsafe prompts: `pane run` truncates very long lines, which silently
# breaks the typed `claude "<prompt>"` command — an unclosed quote means claude
# never starts (this bit us on a ~700-char analysis brief). So for prompts that
# are long, multi-line, or contain a double-quote, stash the prompt in a temp
# brief file and launch claude with a SHORT pointer prompt that reads it. Slash
# commands must be sent literally (and are always short), so they stay inline.
LAUNCH_PROMPT="$PROMPT"
BRIEF_FILE=""
case "$PROMPT" in
  /*) : ;;                                  # slash command — send inline, verbatim
  *)
    if [ "${#PROMPT}" -gt 200 ] \
       || [ "$PROMPT" != "${PROMPT//$'\n'/}" ] \
       || [ "$PROMPT" != "${PROMPT//\"/}" ]; then
      briefdir="${TMPDIR:-/tmp}/herdr-spawn"
      mkdir -p "$briefdir"
      BRIEF_FILE="$(mktemp "$briefdir/brief.XXXXXX")"   # macOS mktemp: X's must trail
      printf '%s\n' "$PROMPT" > "$BRIEF_FILE"
      LAUNCH_PROMPT="Read $BRIEF_FILE and follow it."
    fi
    ;;
esac

herdr pane run "$PANE_ID" "claude \"$LAUNCH_PROMPT\"" >/dev/null

if [ -n "$BRIEF_FILE" ]; then
  echo "SPAWNED tab=$TAB_ID pane=$PANE_ID ws=${WORKSPACE:-default} cwd=$CWD brief=$BRIEF_FILE :: claude \"$LAUNCH_PROMPT\""
else
  echo "SPAWNED tab=$TAB_ID pane=$PANE_ID ws=${WORKSPACE:-default} cwd=$CWD :: claude \"$PROMPT\""
fi
