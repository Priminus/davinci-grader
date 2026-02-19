# Node Count After Reset — IMPORTANT

**Date:** 2026-02-19

## Key Fact

After `resolve_create_cst_nodes.sh` runs "Reset All Grades and Nodes" + Delete, the node graph has **0 nodes**.

Each subsequent `Alt+S` creates a new node starting from 01.

So after the full CST script (`MODE=both`):
- **Node 01** = CST-In
- **Node 02** = CST-Out
- **Total: 2 nodes** = both CST nodes successfully created

## Lesson

Do NOT expect 3 nodes (original + 2 CST). The reset+delete removes the default node. **2 nodes = success.** Do not re-run the script thinking a node is missing.
