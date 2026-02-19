#!/usr/bin/env bash
set -euo pipefail

# resolve_set_hdr.sh
# Sets HDR Color Wheels values via hardcoded screen coordinates.
# Pass values as env vars. Only set vars are applied.
#
# Visible zones: Dark, Shadow, Light, Global
# Each zone has: Exp (exposure), Sat (saturation), X (color offset x), Y (color offset y)
#
# Usage:
#   LIGHT_EXP=-0.2 LIGHT_SAT=1.1 SPECULAR_EXP=0.3 \
#   bash scripts/resolve_set_hdr.sh

APP="${APP:-DaVinci Resolve}"

log() { echo "[$(date '+%H:%M:%S')] $*" >&2; }

set_value() {
  local x="$1" y="$2" val="$3" label="$4"
  log "Setting $label = $val at ($x,$y)"
  peekaboo click --app "$APP" --coords "$x,$y" --double >/dev/null 2>&1 || true
  sleep 0.3
  peekaboo type -- "$val" --app "$APP" >/dev/null 2>&1 || true
  sleep 0.2
  peekaboo press enter --app "$APP" >/dev/null 2>&1 || true
  sleep 0.3
}

maybe_set() {
  local x="$1" y="$2" var_name="$3" label="$4"
  local val="${!var_name:-}"
  if [[ -n "$val" ]]; then
    set_value "$x" "$y" "$val" "$label"
  fi
}

# ── Navigate to HDR Color Wheels ──
log "Clicking HDR Color Wheels tab..."
peekaboo click --app "$APP" --coords 206,680 >/dev/null 2>&1 || true
sleep 0.5

# ═══════════════════════════════════════════════════════════════
# SCREEN COORDINATES (from accessibility element positions)
# Calibrated via peekaboo click --on elem_XX for each value field
# ═══════════════════════════════════════════════════════════════

# ── Light zone ──
maybe_set 100 911 DARK_EXP      "Dark Exp"
maybe_set 200 911 DARK_SAT      "Dark Sat"
maybe_set  79 947 DARK_X        "Dark X"
maybe_set 128 947 DARK_Y        "Dark Y"
maybe_set 181 947 DARK_FALLOFF  "Dark Falloff"

# ── Highlight zone ──
maybe_set 305 911 SHADOW_EXP      "Shadow Exp"
maybe_set 403 911 SHADOW_SAT      "Shadow Sat"
maybe_set 285 947 SHADOW_X        "Shadow X"
maybe_set 335 947 SHADOW_Y        "Shadow Y"
maybe_set 385 947 SHADOW_FALLOFF  "Shadow Falloff"

# ── Specular zone ──
maybe_set 513 911 LIGHT_EXP      "Light Exp"
maybe_set 606 911 LIGHT_SAT      "Light Sat"
maybe_set 489 947 LIGHT_X        "Light X"
maybe_set 539 947 LIGHT_Y        "Light Y"
maybe_set 589 947 LIGHT_FALLOFF  "Light Falloff"

# ── Global zone ──
maybe_set 714 911 GLOBAL_EXP  "Global Exp"
maybe_set 811 911 GLOBAL_SAT  "Global Sat"
maybe_set 716 947 GLOBAL_X    "Global X"
maybe_set 771 947 GLOBAL_Y    "Global Y"

log "✅ HDR done"
