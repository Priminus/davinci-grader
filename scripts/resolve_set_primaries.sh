#!/usr/bin/env bash
set -euo pipefail

# resolve_set_primaries.sh
# Sets Primary Color Wheel values via hardcoded screen coordinates.
# Pass values as env vars. Unset vars are skipped (no change).
#
# Usage:
#   LIFT_R=-0.03 LIFT_B=0.04 GAIN_R=0.97 GAIN_B=1.03 bash scripts/resolve_set_primaries.sh
#
# All env vars (all optional — only set ones are applied):
#   TEMP, TINT, CONTRAST, PIVOT, MID_DETAIL
#   LIFT_Y, LIFT_R, LIFT_G, LIFT_B
#   GAMMA_Y, GAMMA_R, GAMMA_G, GAMMA_B
#   GAIN_Y, GAIN_R, GAIN_G, GAIN_B
#   OFFSET_Y, OFFSET_R, OFFSET_G, OFFSET_B
#   COLOR_BOOST, SHADOWS, HIGHLIGHTS, SATURATION, HUE, LUM_MIX

APP="${APP:-DaVinci Resolve}"

log() { echo "[$(date '+%H:%M:%S')] $*" >&2; }

set_value() {
  local x="$1" y="$2" val="$3" label="$4"
  log "Setting $label = $val at ($x,$y)"
  peekaboo click --app "$APP" --coords "$x,$y" --double >/dev/null 2>&1 || true
  sleep 0.3
  peekaboo type "$val" --app "$APP" >/dev/null 2>&1 || true
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

# ── Navigate to Primary Color Wheels ──
log "Clicking Primary Color Wheels tab..."
peekaboo click --app "$APP" --coords 149,680 >/dev/null 2>&1 || true
sleep 0.5

# ═══════════════════════════════════════════════════════════════
# HARDCODED SCREEN COORDINATES (from AGENTS.md + extrapolation)
# Screen: 3456x2234 Retina, logical ~1728x1117
# ═══════════════════════════════════════════════════════════════

# ── Top row (y=739) ──
# Known: Temp=205, Tint=357, Contrast=511 (spacing ~154px)
maybe_set 205 739 TEMP        "Temp"
maybe_set 357 739 TINT        "Tint"
maybe_set 511 739 CONTRAST    "Contrast"
maybe_set 665 739 PIVOT       "Pivot"          # estimated +154
maybe_set 819 739 MID_DETAIL  "Mid/Detail"     # estimated +154

# ── RGBY input boxes (y=912) ──
# Known anchors: Y(Luma)=66,912  Blue Gain=591,912
# Layout: 4 groups (Lift/Gamma/Gain/Offset) × 4 channels (Y,R,G,B)
# Evenly spaced: (591-66)/11 ≈ 47.7px per slot → rounded to nearest int
#
#   Pos  Group    Chan   X
#   0    Lift     Y      66
#   1    Lift     R      114
#   2    Lift     G      162
#   3    Lift     B      209
#   4    Gamma    Y      257
#   5    Gamma    R      305
#   6    Gamma    G      352
#   7    Gamma    B      400
#   8    Gain     Y      448
#   9    Gain     R      495
#   10   Gain     G      543
#   11   Gain     B      591
#   12   Offset   Y      638
#   13   Offset   R      686
#   14   Offset   G      734
#   15   Offset   B      781

# Lift
maybe_set  66 912 LIFT_Y   "Lift Y"
maybe_set 104 912 LIFT_R   "Lift R"
maybe_set 142 912 LIFT_G   "Lift G"
maybe_set 180 912 LIFT_B   "Lift B"

# Gamma
maybe_set 271 912 GAMMA_Y  "Gamma Y"
maybe_set 309 912 GAMMA_R  "Gamma R"
maybe_set 347 912 GAMMA_G  "Gamma G"
maybe_set 386 912 GAMMA_B  "Gamma B"

# Gain
maybe_set 474 912 GAIN_Y   "Gain Y"
maybe_set 512 912 GAIN_R   "Gain R"
maybe_set 551 912 GAIN_G   "Gain G"
maybe_set 589 912 GAIN_B   "Gain B"

# Offset (THERE IS NO Y VALUE)
maybe_set 684 912 OFFSET_R "Offset R"
maybe_set 736 912 OFFSET_G "Offset G"
maybe_set 786 912 OFFSET_B "Offset B"

# ── Bottom row (y=960, estimated) ──
# TODO: verify these y coords
maybe_set 114 960 COLOR_BOOST "Color Boost"
maybe_set 253 960 SHADOWS     "Shadows"
maybe_set 395 960 HIGHLIGHTS  "Highlights"
maybe_set 537 960 SATURATION  "Saturation"
maybe_set 675 960 HUE         "Hue"
maybe_set 815 960 LUM_MIX     "Lum Mix"

log "✅ Primaries done"
