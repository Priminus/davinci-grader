#!/usr/bin/env bash
# resolve_set_curves.sh — Create and drag curve points in DaVinci Resolve
#
# Usage:
#   POINTS="x1,y1,dy1 x2,y2,dy2 ..." bash scripts/resolve_set_curves.sh
#
# Each point is: x,y,dy where:
#   x,y = position on the curve line to click (create point)
#   dy  = pixels to drag vertically (positive=down/darker, negative=up/brighter)
#
# Optional env vars:
#   RESET=1           — reset curves before starting (clicks reset button)
#   CLICK_CURVES=1    — click the Curves tab (389,680) first
#   DRAG_DURATION=500 — drag duration in ms (default 500)
#   VERIFY=1          — take a screenshot after each action (slower but safer)
#
# Example (5-point S-curve):
#   POINTS="140,934,12 254,889,6 311,866,0 425,820,-8 539,775,-14" \
#   CLICK_CURVES=1 RESET=1 bash scripts/resolve_set_curves.sh

set -euo pipefail

APP="DaVinci Resolve"
DRAG_DURATION="${DRAG_DURATION:-500}"
VERIFY="${VERIFY:-0}"
SCREENSHOTS_DIR="$(cd "$(dirname "$0")/.." && pwd)/screenshots"
mkdir -p "$SCREENSHOTS_DIR"

if [ -z "${POINTS:-}" ]; then
  echo "ERROR: POINTS env var required. Example: POINTS=\"140,934,12 254,889,6\""
  exit 1
fi

# Click Curves tab if requested
if [ "${CLICK_CURVES:-0}" = "1" ]; then
  echo "[curves] Clicking Curves tab at 389,680..."
  peekaboo click --app "$APP" --coords 389,680 2>&1
  sleep 0.5
  if [ "$VERIFY" = "1" ]; then
    echo "[curves] Verifying Curves tab opened..."
    peekaboo see --app "$APP" --analyze "Is the Curves panel open?" 2>&1 | grep -i "analysis" || true
  fi
fi

# Reset is NOT possible do not try.

# Parse points into arrays
read -ra POINT_ARRAY <<< "$POINTS"

echo "[curves] Phase 1: Creating ${#POINT_ARRAY[@]} points on the curve..."

# Phase 1: Create all points by clicking on the curve line (left to right)
for point in "${POINT_ARRAY[@]}"; do
  IFS=',' read -r px py dy <<< "$point"
  echo "  Creating point at ($px, $py)..."
  peekaboo click --app "$APP" --coords "$px,$py" 2>&1
  sleep 0.4
done

# Click away from curve briefly to deselect, then back
sleep 0.3

echo "[curves] Phase 2: Dragging ${#POINT_ARRAY[@]} points to target positions..."

# Phase 2: Click each point to select it, then drag to target
for point in "${POINT_ARRAY[@]}"; do
  IFS=',' read -r px py dy <<< "$point"

  if [ "$dy" = "0" ]; then
    echo "  Point ($px, $py): no drag needed, skipping."
    continue
  fi

  target_y=$((py + dy))
  echo "  Clicking point at ($px, $py) then dragging to ($px, $target_y) [dy=$dy]..."
  peekaboo drag --from-coords "$px,$py" --to-coords "$px,$target_y" --app "$APP" --duration "$DRAG_DURATION" 2>&1
  sleep 0.4

  if [ "$VERIFY" = "1" ]; then
    echo "  Verifying..."
    SNAP=$(peekaboo see --app "$APP" 2>&1 | head -1)
    cp "$(echo "$SNAP" | sed 's/.*saved to: //')" "$SCREENSHOTS_DIR/curve_${px}_${dy}.png" 2>/dev/null || true
  fi
done

peekaboo click --app "$APP" --coords 965,380

echo "[curves] Done. Taking final screenshot..."
FINAL=$(peekaboo see --app "$APP" 2>&1 | grep "saved to:" | sed 's/.*saved to: //')
if [ -n "$FINAL" ]; then
  cp "$FINAL" "$SCREENSHOTS_DIR/curves_final.png" 2>/dev/null || true
  echo "[curves] Final screenshot: $SCREENSHOTS_DIR/curves_final.png"
fi

echo "[curves] ✅ Complete"
