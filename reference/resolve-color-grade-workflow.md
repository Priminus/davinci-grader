# DaVinci Resolve 20 — Production-Grade Color Grading Reference

Source: iPhone 16 Pro Max studio tutorial (Apple Log footage)

## Complete Node Tree (exact order, exact values)

### Node 1: CST In (Color Space Transform)
- **OpenFX plugin:** Color Space Transform
- Input Color Space: **Rec. 2020**
- Input Gamma: **Apple Log**
- Output Color Space: **DaVinci Wide Gamut**
- Output Gamma: **DaVinci Intermediate**

### Node 2: CST Out (Color Space Transform)
- **OpenFX plugin:** Color Space Transform
- Input Color Space: **DaVinci Wide Gamut**
- Input Gamma: **DaVinci Intermediate**
- Output Color Space: **Rec. 709**
- Output Gamma: **Rec. 709-A** (Mac display gamma)

### Node 3: Exposure / Contrast
- Tool: **Custom Curves** only
- Shadows: **lift** the bottom of the curve (raise blacks)
- Highlights: **pull down** the top of the curve (tame highlights)
- Midtones: create an **S-curve** to restore contrast
- Net effect: controlled dynamic range, no clipping

### Node 4: Balance (White Balance)
- Tool: **Color Wheels** → **Offset** wheel (global shift)
- Also: **Temperature** slider adjustment
- Verification: open **Vectorscope** → confirm skin tones sit on the **skin tone indicator line**

### Node 5: Saturation
- Tool: **Color Slice** page (Hue vs Sat area)
- Add global saturation boost via Color Slice (more targeted than the sat slider)

### Node 6: Skin
- Tool: **Color Slice** page → Skin section
- Hue: push skin slightly from **red → yellow** (subtle)
- Skin tone density: **+0.03**
- Red channel density: **+0.03** (affects lips, nose — makes them richer)

### Node 7: Window — Right Side
- Tool: **Power Window** → Pen tool (freehand shape)
- Covers the right portion of background
- Softness: **increased** (smooth falloff)
- Adjustment: **HDR Wheels** → Exposure **−0.05**

### Node 8: Window — Left Side
- Tool: **Power Window** → Pen tool
- Covers the left portion of background
- Softness: increased
- Adjustment: **HDR Wheels** → Exposure reduction **stronger than right side** (e.g. −0.08 to −0.10)
- Goal: subject brighter than background on both sides

### Node 9: Haze Removal
- Tool: **Power Window** with **fade/softness** over the haze/bright spot
- Adjustment: **HDR Wheels** → reduce exposure on the problem area
- Use case: teleprompter reflections, lens flare, unwanted bright patches

### Node 10: Blemish / Stain Removal
- Tool: **Power Window** around the defect
- Go to **Blur** palette (not color wheels)
- Blur radius: **~1.0** (just enough to hide the blemish)
- Do NOT sharpen (makes defects worse)

### Node 11: Film Look Creator (built-in DaVinci plugin)
- **Bleach Bypass:** 0.2 (desaturates + adds contrast, cinematic)
- **Vignette:** enabled (darkens edges, draws eye to center)

### Node 12: Look (Final Separation)
- Tool: **Qualifier** → select skin tones
- **Invert** the selection (now affecting everything EXCEPT skin/subject)
- **HDR Wheels:** reduce exposure on background (darken non-subject areas)
- **Color:** add **teal** cast to the background → teal/orange separation
- **Gain:** reduce to **0.8** (tame harshness in background)

---

## Target Look
- **Dark background**, subject clearly separated and well-lit
- Subject skin tones warm and natural (orange side)
- Background cooler (teal cast), darker, receding
- Subtle film texture (grain, bloom), not digital-looking
- Soft highlight rolloff, no harsh clipping
- Vignette drawing eye to center/subject

## Exposure Detection Guidelines
- **Overexposed:** waveform highlights consistently above 80-90 IRE on subject
- **Underexposed:** waveform midtones below 40 IRE on subject face
- **Target:** subject face midtones around 55-65 IRE, highlights soft-rolling under 85 IRE
- Use the **Parade scope** to check per-channel balance
- Use **Vectorscope** to verify skin tones on indicator line

## DaVinci Resolve 20 Keyboard Shortcuts Used
- **Shift+6** → Color page
- **Shift+5** → Edit page
- **Shift+8** → Deliver page
- **Alt+S** → Add Serial Node
- **Alt+P** → Add Parallel Node
- **Ctrl+D** → Toggle node on/off (bypass)
