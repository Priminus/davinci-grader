#!/bin/bash
# Check if the Node Graph is visible in DaVinci Resolve Color page
# Returns YES or NO
export PEEKABOO_AI_PROVIDERS=openai/gpt-5.1
WORKSPACE_DIR="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$WORKSPACE_DIR/screenshots"
peekaboo see --app "DaVinci Resolve" --path "$WORKSPACE_DIR/screenshots/check_nodes.png" --analyze "Look at the right-center area of the screenshot.
If any of the below 3 points are present, then answer YES. Otherwise answer NO.
- Is there a word 'Clip' with a chevron beside it
- Is the top right 'Nodes' text in white text
- Is there in the node graph section 2 rectangles with green circles (input and output sources)
Answer YES or NO ONLY. Do not explain."
