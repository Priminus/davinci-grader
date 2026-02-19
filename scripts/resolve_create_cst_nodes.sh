#!/usr/bin/env bash
set -euo pipefail

APP="${APP:-DaVinci Resolve}"
WORKDIR="${WORKDIR:-/Users/michaelhart/.openclaw/workspace/video-editor}"
SNAP="${SNAP:-$WORKDIR/screenshots/run}"
mkdir -p "$SNAP"

MODE="${MODE:-both}"

# CST-In values
IN_INPUT_CS="${IN_INPUT_CS:-Rec.2020}"
IN_INPUT_GAMMA="${IN_INPUT_GAMMA:-Apple Log}"
IN_OUTPUT_CS="${IN_OUTPUT_CS:-DaVinci Wide Gamut}"
IN_OUTPUT_GAMMA="${IN_OUTPUT_GAMMA:-DaVinci Intermediate}"

# CST-Out values
OUT_INPUT_CS="${OUT_INPUT_CS:-DaVinci Wide Gamut}"
OUT_INPUT_GAMMA="${OUT_INPUT_GAMMA:-DaVinci Intermediate}"
OUT_OUTPUT_CS="${OUT_OUTPUT_CS:-Rec.709}"
OUT_OUTPUT_GAMMA="${OUT_OUTPUT_GAMMA:-Rec.709-A}"

# We detect expansion by vision analysis in peekaboo see
NEEDLE="Input Color Space"

# Offsets (relative to the "Color Space Transform" header click point)
# You can tune these. Keep as requested.
X_OFFSET="${X_OFFSET:-0}"
Y_OFFSET="${Y_OFFSET:-25}"
ROW_SPACING="${ROW_SPACING:-25}"

SEE_JSON="$SNAP/_see.json"

# IMPORTANT: logs to stderr so stdout stays clean for command substitution
log() { echo "[$(date '+%H:%M:%S')] $*" >&2; }

parse_coords() {
  # expects something containing "(123, 456)"
  echo "$1" | grep -oE '\(([0-9]+), ([0-9]+)\)' | head -1 | sed 's/[()]//g; s/,//; s/  */ /g'
}

# ---------------------------------------------------------------
# Detect if CST panel is expanded (YES/NO) via peekaboo see --analyze
# ---------------------------------------------------------------
is_cst_expanded() {
  peekaboo see \
    --app "$APP" \
    --json-output \
    --timeout-seconds 20 \
    --analyze "Does this image contain the text '${NEEDLE}'? Answer YES or NO only." \
    > "$SEE_JSON"

  jq -r '.data.analysis.text // "NO"' "$SEE_JSON" | tr '[:lower:]' '[:upper:]'
}

# ---------------------------------------------------------------
# Find CST header element id (best-effort AX query)
# ---------------------------------------------------------------
get_cst_header_id() {
  peekaboo see --app "$APP" --json-output --timeout-seconds 20 > "$SEE_JSON"

  jq -r '
    [.data.ui_elements[]
      | select(.label == "Color Space Transform" and .role_description == "text")
    ] | last | .id // "NONE"
  ' "$SEE_JSON"
}

# ---------------------------------------------------------------
# Get CST header click point WITHOUT toggling:
# right-click the CST header to get coordinates, then ESC to dismiss menu.
# Returns: "X Y"
# ---------------------------------------------------------------
get_cst_header_coords() {
  local section_id="$1"

  local out x y
  out="$(peekaboo click --app "$APP" --on "$section_id" --right 2>&1 || true)"

  read -r x y <<<"$(parse_coords "$out" || true)"

  if [[ -z "${x:-}" || -z "${y:-}" ]]; then
    log "❌ Could not parse coords from right-click output:"
    log "    $out"
    exit 1
  fi

  # dismiss context menu if it appeared
  peekaboo press escape --app "$APP" >/dev/null 2>&1 || true
  sleep 0.2

  echo "$x $y"
}

# ---------------------------------------------------------------
# Expand CST panel if needed (only toggles when analysis says NO)
# ---------------------------------------------------------------
ensure_cst_expanded() {
  local section_id="$1"
  local ans
  ans="$(is_cst_expanded)"
  log "CST expanded check = $ans"

  if [[ "$ans" == "YES" ]]; then
    return 0
  fi

  log "CST appears collapsed → clicking header to expand..."
  peekaboo click --app "$APP" --on "$section_id" >/dev/null 2>&1 || true
  sleep 0.9

  ans="$(is_cst_expanded)"
  log "CST expanded re-check = $ans"
  if [[ "$ans" != "YES" ]]; then
    log "❌ CST still not expanded after click"
    exit 1
  fi
}

set_single_dropdown() {
  local x="$1" y="$2" value="$3" label="$4"

  log "Setting $label = $value at ($x,$y)"
  peekaboo click --app "$APP" --coords "$x,$y" >/dev/null 2>&1 || true
  sleep 0.35
  peekaboo type "$value" --app "$APP" >/dev/null 2>&1 || true
  sleep 0.2
  peekaboo press enter --app "$APP" >/dev/null 2>&1 || true
  sleep 0.35
}

# ---------------------------------------------------------------
# Configure CST values for the CURRENT (active) node
# ---------------------------------------------------------------
configure_current_cst_node() {
  local v1="$1" v2="$2" v3="$3" v4="$4"

  # Locate CST header id (should be visible for current node inspector)
  local section_id
  section_id="$(get_cst_header_id)"
  if [[ "$section_id" == "NONE" || "$section_id" == "null" ]]; then
    log "❌ Cannot find CST header element id"
    exit 1
  fi
  log "CST header id = $section_id"

  ensure_cst_expanded "$section_id"

  # Get header coords without toggling
  local hx hy
  read -r hx hy <<<"$(get_cst_header_coords "$section_id")"
  log "CST header coords = ($hx,$hy)"

  # Compute dropdown base coords
  local dx dy
  dx=$((hx + X_OFFSET))
  dy=$((hy + Y_OFFSET))
  log "Computed dropdown base coords = ($dx,$dy) using +${X_OFFSET}x +${Y_OFFSET}y"

  # Fill 4 dropdowns
  set_single_dropdown "$dx" "$dy"                     "$v1" "Input Color Space"
  set_single_dropdown "$dx" "$((dy + ROW_SPACING))"   "$v2" "Input Gamma"
  set_single_dropdown "$dx" "$((dy + ROW_SPACING*2))" "$v3" "Output Color Space"
  set_single_dropdown "$dx" "$((dy + ROW_SPACING*3))" "$v4" "Output Gamma"
}

# ---------------------------------------------------------------
# START FLOW (no modes)
# ---------------------------------------------------------------
log "═══ START FULL CST-IN + CST-OUT FLOW ═══"

# Activate Resolve + Color page
peekaboo app launch "$APP" 2>/dev/null || true
sleep 3
peekaboo hotkey --keys "shift,6" --app "$APP" >/dev/null 2>&1 || true
sleep 2

# Pointer Mode anchor → node graph coords
peekaboo see --app "$APP" --json-output --timeout-seconds 30 > "$SEE_JSON" 2>&1 || true
POINTER_ELEM=$(jq -r '[.data.ui_elements[] | select(.description == "Pointer Mode")] | .[0].id // "NONE"' "$SEE_JSON")
if [[ "$POINTER_ELEM" == "NONE" || "$POINTER_ELEM" == "null" ]]; then
  log "❌ Pointer Mode not found"
  exit 1
fi

CLICK_OUT=$(peekaboo click --app "$APP" --on "$POINTER_ELEM" 2>&1 || true)
read -r PX PY <<<"$(parse_coords "$CLICK_OUT" || true)"
if [[ -z "${PX:-}" || -z "${PY:-}" ]]; then
  log "❌ Could not parse Pointer Mode click coords:"
  log "    $CLICK_OUT"
  exit 1
fi
NGY=$((PY + 100))

# Reset nodes (only for MODE=both or MODE=in)
if [[ "$MODE" != "out" ]]; then
  log "Resetting nodes..."
  peekaboo click --app "$APP" --coords "$PX,$NGY" --right >/dev/null 2>&1 || true
  sleep 0.8
  peekaboo click --app "$APP" "Reset All Grades and Nodes" --wait-for 3000 >/dev/null 2>&1 || true
  sleep 1.6
  peekaboo press delete --app "$APP"
  sleep 0.8
  log "✅ Nodes reset"
else
  log "MODE=out → skipping node reset"
fi

# ──────────────────────────────────────────────────────────────
# CST-IN NODE
# ──────────────────────────────────────────────────────────────
if [[ "$MODE" == "both" || "$MODE" == "in" ]]; then

  log "Creating CST-In node (Alt+S)..."
  peekaboo click --app "$APP" --coords "$PX,$NGY" >/dev/null 2>&1 || true
  sleep 0.2
  peekaboo hotkey --keys "alt,s" --app "$APP" >/dev/null 2>&1 || true
  sleep 1.0
  log "✅ CST-In node created"

  log "Applying CST plugin to CST-In (Shift+Space)..."
  peekaboo hotkey --keys "shift,space" --app "$APP" >/dev/null 2>&1 || true
  sleep 0.9
  peekaboo type "Color Space Transform" --app "$APP" >/dev/null 2>&1 || true
  sleep 0.4
  peekaboo press tab --app "$APP" >/dev/null 2>&1 || true
  sleep 0.2
  peekaboo press enter --app "$APP" >/dev/null 2>&1 || true
  sleep 1.4
  log "✅ CST applied to CST-In"

  log "Setting CST-In values..."
  configure_current_cst_node "$IN_INPUT_CS" "$IN_INPUT_GAMMA" "$IN_OUTPUT_CS" "$IN_OUTPUT_GAMMA"
  log "✅ CST-In configured"

fi

# ──────────────────────────────────────────────────────────────
# CST-OUT NODE
# ──────────────────────────────────────────────────────────────
if [[ "$MODE" == "both" || "$MODE" == "out" ]]; then

  log "Creating CST-Out node (Alt+S)..."
  peekaboo click --app "$APP" --coords "$PX,$NGY" >/dev/null 2>&1 || true
  sleep 0.2
  peekaboo hotkey --keys "alt,s" --app "$APP" >/dev/null 2>&1 || true
  sleep 1.0
  log "✅ CST-Out node created"

  log "Applying CST plugin to CST-Out (Shift+Space)..."
  peekaboo hotkey --keys "shift,space" --app "$APP" >/dev/null 2>&1 || true
  sleep 0.9
  peekaboo type "Color Space Transform" --app "$APP" >/dev/null 2>&1 || true
  sleep 0.4
  peekaboo press tab --app "$APP" >/dev/null 2>&1 || true
  sleep 0.2
  peekaboo press enter --app "$APP" >/dev/null 2>&1 || true
  sleep 1.4
  log "✅ CST applied to CST-Out"

  log "Setting CST-Out values..."
  configure_current_cst_node "$OUT_INPUT_CS" "$OUT_INPUT_GAMMA" "$OUT_OUTPUT_CS" "$OUT_OUTPUT_GAMMA"
  bash "$(dirname "$0")/switch_node.sh"
  log "✅ CST-Out configured"
fi

log "✅ DONE"
