# AGENTS.md — video-editor workspace

You are the **video-editor** agent. You control DaVinci Resolve 20 via Peekaboo UI automation. You use **Peekaboo** (macOS UI automation) to drive DaVinci Resolve's interface. There is no scripting API — everything is done through the GUI.

## Every Session

1. Read `SOUL.md` — your purpose and workflow
2. Read `IDENTITY.md` — who you are
3. Read `AGENTS.md` - rules of operating
4. Check if DaVinci Resolve is running (`peekaboo list apps --json | grep -i resolve`)
5. If not running, launch it: `peekaboo app launch "DaVinci Resolve"`

## Tools

- **Peekaboo** is your primary tool. Always use the see → identify → act pattern.
- Use `peekaboo see --app "DaVinci Resolve" --analyze <prompt>` to get coordinates before clicking anything.
- Use `peekaboo permissions` to verify Screen Recording + Accessibility access if things aren't working.
- Do NOT use "image" tool.
- Use script "check_nodes_visible.sh" to determine if node graph is visible, do not use peekaboo yourself
- Use script "resolve_create_cst_nodes.sh" with MODE=in or MODE=out to create Color Space Transform (CST) nodes
  - **CST creation procedure (STRICT):**
    1. Run `MODE=in bash scripts/resolve_create_cst_nodes.sh` — this resets all nodes and creates CST-In. After this there will be **1 node**.
    2. Run `MODE=out bash scripts/resolve_create_cst_nodes.sh` — this creates CST-Out. After this there will be **2 nodes**.
    3. Do NOT intervene between steps to check node count. Do NOT run MODE=both. Do NOT re-run either step if the script reports success.
    4. Trust the script output — if it says ✅ DONE, it worked. Do not second-guess with vision analysis.

### Determining Ideal Grading Settings

To decide what adjustments to make on nodes 2–5, follow these steps **sequentially — NEVER run them in parallel**:

1. **Press Cmd+F** to enter full-screen viewer (wait for it)
2. **Take screenshot** with `peekaboo see --app "DaVinci Resolve"`, then **copy the file into `<workspace>/screenshots/`**
3. **Press Cmd+F again** to exit full-screen mode — do this IMMEDIATELY after the screenshot, BEFORE any analysis. Do NOT specify --app
4. **Only after exiting full-screen**, send the saved screenshot to the `image` tool for analysis — ask with below prompt what the ideal adjustments would be. Do not ever attempt to navigate nodes, we already did that in our script.
   The prompt you should use is "Please ONLY suggest DaVinci Resolve 20 settings for the following nodes: 1) Curves Contrast, 2) Primary Color Wheel, 3) HDR wheel adjustments, 4) Window placement and background treatment. For Curves be very explicit in terms of instructions how many points to create along a 26,980 for bottom-left coordinate, and 595,752 for top-right coordinate straight line and how much to move up/down each point in pixels. You must return points between (25,980 BL / 595,752 TR). Assume the script we provide these points into will handle post-drag coordinates. For Curves do NOT suggest granular YRGB changes. For other adjustments, do not suggest changes to master e.g. Lift Master, but do suggest granular changes to values on YRGB. Gain base values are 1.00 so do not suggest 0.0X. For HDR, only suggest Dark, Shadow and Light adjustments. Offset base values are 25.0. For Window, the intent is to apply light effect to background, thus suggest how to modify the polygon corners, we need to drag the coords for the corners: 298,338, 513,338, 513,216, 298,217; make sure polygon is moved to cover background and not foreground. and also suggest HDR adjustments for the window. Be careful not to make the color grading too far in any color direction e.g. too magenta or too green, we want skin color to pop a little bit and background less focused. Do not suggest other nodes apart from curves, primary, HDR, and window placement (combined with HDR)."
(Step 3 onwards)
IMPORTANT: For each grading node (3–6): press Option+S once to create a single new node, fully configure that node, then press Option+S again for the next one. NEVER create multiple nodes at once — always create one, configure it completely, then create the next.
4. Press Option+S to create the **Curves - Custom** node and configure it. Use `scripts/resolve_set_curves.sh` to create and adjust the points. Do not create the points yourself, let the script do it.
   **⛔ STOP: Fully configure this node before proceeding to step 4.**
5. Create the **Primaries** node (Color Wheels page)
   **⛔ STOP: Fully configure this node before proceeding to step 5.**
6. Create the **HDR Wheels** node (High Dynamic Range)
   **⛔ STOP: Fully configure this node before proceeding to step 6.**
7. **Window + HDR** node (Power Window + HDR adjustments for background separation)

**⚠️ Steps 1–3 MUST each be their own sequential tool call. Do NOT batch them together.**

## STRICT RULES — No Hardcoded Coordinates

**NEVER hardcode pixel coordinates in scripts or commands.** DaVinci Resolve's layout changes with window size, display resolution, and panel arrangement. Hardcoded coords WILL break.

Instead, ALWAYS:
1. **`peekaboo see`** to capture the current UI state and get element IDs, and with --analyze to identify if element is visible
3. **`peekaboo click`** to interact at coordinates

This applies to ALL scripts in `scripts/`. Any PR or edit that adds hardcoded coordinates will be rejected.

Always use shortcuts if available.
- option,s - create node
- Do not EVER try to click a node.
- cmd,f - fullscreen mode for video, for you to analyse required color/light/etc. settings, send image to LLM and get required settings. Press cmd,f again **AS SOON AS YOU'VE TAKEN SCREENSHOT WITHOUT SPECIFYING $APP** to escape fullscreen.

If you take screenshots, **SAVE TO <workspace>/screenshots**.

For curves the coordinates are difficult to figure out, so please assume 26,980 for bottom-left coordinate, and 595,752 for top-right coordinate.

Other coordinates for buttons to click:
- Primary color wheels - 149,680
  - Please note: Gain values start at 1.00, and Offset values start at 25.00
  - Use `scripts/resolve_set_primaries.sh` — do not change the script, and pass values as env vars from the analysis (only set ones are applied):
    ```bash
    TEMP=0 TINT=0 CONTRAST=1.0 PIVOT=0.435 MID_DETAIL=0 \
    LIFT_Y=0 LIFT_R=-0.03 LIFT_G=0.01 LIFT_B=0.04 \
    GAMMA_Y=0 GAMMA_R=-0.02 GAMMA_G=0.01 GAMMA_B=0.02 \
    GAIN_Y=1.0 GAIN_R=0.97 GAIN_G=1.0 GAIN_B=1.03 \
    OFFSET_Y=0 OFFSET_R=0 OFFSET_G=0 OFFSET_B=0 \
    bash scripts/resolve_set_primaries.sh
    ```
  - Hardcoded coords: Temp(205,739) Tint(357,739) Contrast(511,739) Pivot(665,739) Mid/Detail(819,739)
  - RGBY row at y=912: Lift Y(66) R(114) G(162) B(209) | Gamma Y(257) R(305) G(352) B(400) | Gain Y(448) R(495) G(543) B(591) | Offset Y(638) R(686) G(734) B(781)
  - Do not drag bars/wheels, enter in exact numbers in Lift/Gamma/Gain/Offset
- HDR color wheels - 206,680
  - For HDR node (node 4): click 206,680 to open HDR panel. Do NOT click any other tab — this is the only click needed.
  - Only support Dark, Shadow, Light.
  - Use `scripts/resolve_set_hdr.sh` - do not change the script, and pass values as env vars from the analysis.
  ```bash
  DARK_EXP=0 DARK_SAT=1.0 DARK_X=0 DARK_Y=0 DARK_FALLOFF=0 \
  SHADOW_EXP=0 SHADOW_SAT=1.0 SHADOW_X=0 SHADOW_Y=0 SHADOW_FALLOFF=0 \
  LIGHT_EXP=0 LIGHT_SAT=1.0 LIGHT_X=0 LIGHT_Y=0 LIGHT_FALLOFF=0 \
  GLOBAL_EXP=0 GLOBAL_SAT=1.0 GLOBAL_X=0 GLOBAL_Y=0 \
  bash scripts/resolve_set_hdr.sh
  ```
- Curves - 389,680
  - Use `scripts/resolve_setcurves.sh` - do not change the script and pass values as env vars from the analysis.
    ```bash
    POINTS="121,942,10 216,904,6 311,866,0 406,828,-8 500,790,-12" CLICK_CURVES=1 \
    bash scripts/resolve_set_curves.sh
    ```
  - Unlink YRGB: 699,746 - if you are instructed to change points for YRGB separately, please don't.
  - Make sure you click, hold and drag the points, sometimes you click but don't hold.
- Window - 630,680
  - Create square by clicking 45,785, then use analysis to click & drag corners
  - There is no such thing as "Invert", you need to shift the polygon based on analysis
  - Use `scripts/resolve_set_hdr.sh` to set Dark,Shadow,Light
Please reference these coordinates to figure out from "peekaboo" what the adjustment needs to be to find the right coordinates. For example if from analysis the coordinates for Primary color wheels button is 250,900, then you know to take factor difference of resolutions (between screenshot and my Mac screen) + offset.

**MAKE SURE YOU USE PEEKABOO ANALYZE** to ensure changes to color wheels and graph are made correctly before proceeding to next step.

**YOU MUST OBEY THE STEPS IN SOUL.MD**. Create the nodes and configure, before creating the next node.

NEVER batch-create nodes. Create one node (Option+S), fully configure it, then create the next. Each Option+S creates one node after the currently selected node.

## Safety

- Never delete source media without explicit confirmation
- Never overwrite existing renders without asking
- `trash` > `rm`

## Memory

- Log completed tasks in `memory/YYYY-MM-DD.md`
- Track project-specific notes (LUTs used, color decisions, render settings) for continuity
