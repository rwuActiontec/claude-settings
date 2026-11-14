#!/bin/bash
# Claude Code status line — receives session JSON on stdin.
# Shows: model id + display name, cwd, total in/out tokens, context %,
# effort level, thinking enabled, the Fable weekly limit (e.g. "Fable 56%")
# and the all-models weekly limit (e.g. "7d 40%").
# Fields per https://code.claude.com/docs/en/statusline
# The model-scoped weekly bucket is NOT in the statusline JSON; it comes from
# GET /api/oauth/usage (limits[].kind == "weekly_scoped"), cached for 60s and
# refreshed in the background so the status line never blocks on the network.
# Parsed with python3 (jq is not installed on this host).

input=$(cat)

IFS=$'\t' read -r MODEL_ID MODEL_NAME CWD IN_TOK OUT_TOK CTX_PCT EFFORT THINKING RL7 <<EOF
$(printf '%s' "$input" | python3 -c '
import json, sys

def dig(obj, *path):
    for k in path:
        if isinstance(obj, dict) and k in obj:
            obj = obj[k]
        else:
            return None
    return obj

try:
    d = json.load(sys.stdin)
except Exception:
    d = {}

model_id = dig(d, "model", "id") or "?"
model_name = dig(d, "model", "display_name") or "?"
cwd = dig(d, "workspace", "current_dir") or d.get("cwd") or "?"
in_tok = dig(d, "context_window", "total_input_tokens") or 0
out_tok = dig(d, "context_window", "total_output_tokens") or 0
ctx_pct = int(dig(d, "context_window", "used_percentage") or 0)
effort = dig(d, "effort", "level") or "-"
thinking = "on" if dig(d, "thinking", "enabled") else "off"

rl7 = dig(d, "rate_limits", "seven_day", "used_percentage")
rl7 = "-" if rl7 is None else str(int(rl7))

print("\t".join([str(model_id), str(model_name), str(cwd), str(int(in_tok)), str(int(out_tok)),
                  str(ctx_pct), str(effort), thinking, rl7]))
')
EOF

BRANCH=$(git -C "$CWD" branch --show-current 2>/dev/null)

# --- Model-scoped weekly limit (Fable) via /api/oauth/usage, cached 60s ---
USAGE_CACHE="${XDG_CACHE_HOME:-$HOME/.cache}/claude-statusline-usage.json"
CRED_FILE="$HOME/.claude/.credentials.json"
CACHE_TTL=60
cache_mtime=$(stat -c %Y "$USAGE_CACHE" 2>/dev/null || echo 0)
if (( $(date +%s) - cache_mtime > CACHE_TTL )); then
    mkdir -p "$(dirname "$USAGE_CACHE")"
    touch "$USAGE_CACHE"   # reset age now so concurrent status-line runs don't stampede
    USAGE_CACHE="$USAGE_CACHE" CRED_FILE="$CRED_FILE" setsid bash -c '
        token=$(python3 -c "import json,sys;print(json.load(open(sys.argv[1]))[\"claudeAiOauth\"][\"accessToken\"])" "$CRED_FILE" 2>/dev/null)
        [ -n "$token" ] || exit 0
        curl -fs --max-time 5 \
            -H "Authorization: Bearer $token" \
            -H "anthropic-beta: oauth-2025-04-20" \
            "https://api.anthropic.com/api/oauth/usage" -o "$USAGE_CACHE.tmp" \
          && mv -f "$USAGE_CACHE.tmp" "$USAGE_CACHE"
    ' >/dev/null 2>&1 </dev/null &
fi

# Emits: Fable weekly-scoped label and used %. Prefers the bucket whose model
# display_name contains "Fable"; falls back to any weekly_scoped bucket.
IFS=$'\t' read -r FABLE_LABEL FABLE_PCT <<EOF
$(python3 - "$USAGE_CACHE" <<'PY'
import json, sys
label, pct = "Fable", "-"
try:
    d = json.load(open(sys.argv[1]))
    scoped = []
    for l in d.get("limits") or []:
        m = (l.get("scope") or {}).get("model") or {}
        if l.get("kind") == "weekly_scoped" and m.get("display_name"):
            scoped.append((m["display_name"], str(int(l.get("percent") or 0))))
    fable = [s for s in scoped if "fable" in s[0].lower()]
    if fable or scoped:
        label, pct = (fable or scoped)[0]
except Exception:
    pass
print(f"{label}\t{pct}")
PY
)
EOF

# Shorten home dir to ~
CWD="${CWD/#$HOME/~}"

# Humanize token counts (12345 -> 12.3k, 1234567 -> 1.2M)
fmt_tokens() {
    local n=$1
    if (( n >= 1000000 )); then
        printf '%.1fM' "$(echo "$n / 1000000" | bc -l)"
    elif (( n >= 1000 )); then
        printf '%.1fk' "$(echo "$n / 1000" | bc -l)"
    else
        printf '%d' "$n"
    fi
}

IN_FMT=$(fmt_tokens "$IN_TOK")
OUT_FMT=$(fmt_tokens "$OUT_TOK")

# Color context % by pressure: green < 50, yellow < 80, red >= 80
if (( CTX_PCT >= 80 )); then
    CTX_COLOR='\033[31m'
elif (( CTX_PCT >= 50 )); then
    CTX_COLOR='\033[33m'
else
    CTX_COLOR='\033[32m'
fi

DIM='\033[2m'
CYAN='\033[36m'
BLUE='\033[34m'
MAGENTA='\033[35m'
RESET='\033[0m'
SEP="${DIM} | ${RESET}"

FABLE_FMT="$FABLE_PCT"; [ "$FABLE_PCT" != "-" ] && FABLE_FMT="${FABLE_PCT}%"
WEEK_FMT="$RL7"; [ "$RL7" != "-" ] && WEEK_FMT="${RL7}%"

GREEN='\033[32m'
BRANCH_SEG=""
[ -n "$BRANCH" ] && BRANCH_SEG="${SEP}${GREEN} ${BRANCH}${RESET}"

printf "${CYAN}%s${RESET} ${DIM}(%s)${RESET}${SEP}${BLUE}%s${RESET}${BRANCH_SEG}${SEP}↑%s ↓%s${SEP}ctx ${CTX_COLOR}%s%%${RESET}${SEP}effort ${MAGENTA}%s${RESET}${SEP}think %s${SEP}%s %s${SEP}7d %s" \
    "$MODEL_NAME" "$MODEL_ID" "$CWD" "$IN_FMT" "$OUT_FMT" "$CTX_PCT" "$EFFORT" "$THINKING" "$FABLE_LABEL" "$FABLE_FMT" "$WEEK_FMT"
