# davinci-grader

An AI agent that automates colour grading in DaVinci Resolve using [Peekaboo](https://github.com/steipete/peekaboo) and [OpenClaw](https://github.com/anthropics/openclaw).

Adapted from rules taught in [this video](https://www.youtube.com/watch?v=QyMZb7aIO24).

## What it does

- Creates CST (Color Space Transform) In and Out nodes
- Updates the highlight curve
- Adjusts dark/shadow/light on the HDR wheel
- Sets lift/gamma/gain/offset on primary colour wheels
- Polygon window creation (experimental)

## Display compatibility

Tested on **Liquid Retina XDR 16-inch (3456x2234)** only. Many coordinates are hardcoded and there is no reliable way to resolve click targets dynamically yet. Other resolutions will likely require adjustment.

## Prerequisites

### Homebrew

Since Peekaboo is unable to type apostrophe, which is required to switch nodes, we use cliclick to get around this limitation.
```bash
brew install cliclick
```

### macOS Privacy & Security

Add the following to **System Settings > Privacy & Security**:

**Accessibility:**
- peekaboo
- node
- openclaw

**Screen & System Audio Recording:**
- peekaboo
- openclaw

### Environment

Set `PEEKABOO_API_PROVIDERS` in your shell profile:

```bash
# Add to ~/.bash_profile
export PEEKABOO_API_PROVIDERS="..."
```

## Usage

### With OpenClaw (multi-agent)

Place this agent in your OpenClaw workspace and ask your main agent to utilise it for video edits in DaVinci Resolve.

### With OpenClaw (standalone)

Configure OpenClaw to use this agent directly.

## Project structure

```
davinci-grader/
├── AGENTS.md                  # Agent instructions
├── IDENTITY.md                # Agent identity
├── SOUL.md                    # Agent personality/behaviour
├── TOOLS.md                   # Available tools
├── USER.md                    # User context
├── HEARTBEAT.md               # Heartbeat config
├── scripts/
│   ├── resolve_create_cst_nodes.sh   # Create CST In/Out nodes
│   ├── resolve_set_curves.sh         # Set highlight curve
│   ├── resolve_set_hdr.sh            # Set HDR wheel values
│   ├── resolve_set_primaries.sh      # Set primary colour wheels
│   ├── check_nodes_visible.sh        # Verify node visibility
│   └── switch_node.sh                # Switch between nodes
├── skills/
│   └── peekaboo.json          # Peekaboo skill definition
├── reference/
│   └── resolve-color-grade-workflow.md
└── memory/                    # Agent memory (runtime)
```
