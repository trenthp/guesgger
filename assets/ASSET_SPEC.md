# Theme Park Runner - Asset Specification

Drop PNG files into the folders below. The game automatically loads any assets
it finds and falls back to procedural rendering for anything missing.
You can add assets incrementally — one at a time.

## Directory Structure

```
assets/images/
├── obstacles/          <- one PNG per obstacle type
├── player/             <- sprite sheets for player character
├── npcs/               <- sprite sheets for NPCs
├── backgrounds/        <- parallax layers per zone
│   ├── parking_lot/
│   ├── security/
│   ├── shops/
│   └── ticket_booths/
└── ui/                 <- HUD and menu elements
```

---

## Obstacles (`assets/images/obstacles/`)

One PNG per obstacle. Drawn front-facing with slight isometric 3D angle
(top face and right side visible). Transparent background.

| Filename                  | Description              | Suggested Size |
|---------------------------|--------------------------|----------------|
| `car.png`                 | Red car (parking lot)    | 256×256        |
| `shopping_cart.png`       | Metal shopping cart      | 192×192        |
| `speed_bump.png`          | Yellow/black speed bump  | 384×128        |
| `barricade.png`           | Orange STOP barricade    | 256×256        |
| `metal_detector.png`      | Gray security arch       | 256×320        |
| `bag_check_station.png`   | Blue-gray check table    | 256×256        |
| `security_gate.png`       | Gate doorway frame       | 256×320        |
| `security_gate_blocked.png`| Solid blocked gate wall | 256×320        |
| `merchandise_rack.png`    | Purple display shelf     | 256×256        |
| `food_cart.png`           | Orange cart + umbrella   | 256×256        |
| `bench.png`               | Brown park bench         | 384×128        |
| `rope_line.png`           | Red rope between posts   | 384×192        |
| `turnstile.png`           | Gray metal turnstile     | 192×256        |
| `ticket_kiosk.png`        | Blue ticket machine      | 256×320        |

**Notes:**
- All sprites are scaled dynamically based on depth (perspective). Draw at the
  largest size the object will appear on screen — the engine scales down.
- Wider obstacles (`speed_bump`, `bench`, `rope_line`) span all 3 lanes.
- Transparent PNG backgrounds required.

---

## Player (`assets/images/player/`)

Sprite sheets use a horizontal strip layout: all frames in a single row.

| Filename    | Description               | Frame Size | Frames | Total Size  |
|-------------|---------------------------|------------|--------|-------------|
| `run.png`   | Running animation cycle   | 128×128    | 6      | 768×128     |
| `jump.png`  | Jump arc animation        | 128×128    | 4      | 512×128     |
| `idle.png`  | Standing still            | 128×128    | 1      | 128×128     |
| `hit.png`   | Taking damage             | 128×128    | 1      | 128×128     |

**Character design notes:**
- Front-facing view (character faces the camera / slightly angled)
- Current procedural character: cyan shirt, orange backpack, cap, skin-tone head
- Match the theme park visitor look or go with your own style

---

## NPCs (`assets/images/npcs/`)

| Filename        | Description              | Frame Size | Frames | Total Size |
|-----------------|--------------------------|------------|--------|------------|
| `walker.png`    | Walking civilian cycle   | 96×96      | 4      | 384×96     |
| `security.png`  | Standing security guard  | 96×96      | 1      | 96×96      |

**Notes:**
- NPCs appear smaller than the player
- Civilians should have varied clothing colors (or provide multiple variants:
  `walker_1.png`, `walker_2.png`, etc. — we can add support for that)
- Security guards wear dark navy uniforms

---

## Backgrounds (`assets/images/backgrounds/<zone>/`)

Each zone can have up to 3 parallax layers. These tile horizontally.

| Filename  | Description           | Size       | Scroll Speed |
|-----------|-----------------------|------------|--------------|
| `sky.png` | Sky / atmosphere      | 1920×1080  | Slowest      |
| `far.png` | Distant scenery       | 1920×1080  | Medium       |
| `near.png`| Near scenery          | 1920×1080  | Fastest      |

**Zone themes:**
- `parking_lot/`: Dark asphalt, cars, parking signs, overhead lights
- `security/`: Sterile, blue-tinted, metal detectors in background
- `shops/`: Warm, colorful storefronts, awnings, merchandise
- `ticket_booths/`: Festive, purple-tinted, ticket windows, rope lines

**Notes:**
- `sky.png` is fully opaque; `far.png` and `near.png` need transparent backgrounds
- All layers tile seamlessly when placed side by side horizontally
- Background parallax is not yet implemented — adding these images will
  trigger it to be built

---

## UI (`assets/images/ui/`)

| Filename          | Description              | Size       |
|-------------------|--------------------------|------------|
| `logo.png`        | Game title/logo          | 512×256    |
| `heart_full.png`  | Full life heart          | 48×48      |
| `heart_empty.png` | Empty life heart         | 48×48      |
| `button_bg.png`   | Button background (9-slice) | 256×96  |

---

## Technical Notes

- **Format:** PNG with alpha transparency
- **Resolution:** Draw at 2-3x the expected display size for crisp scaling
- **Color space:** sRGB
- **The engine scales sprites based on 3D depth** — objects far away are rendered
  small, objects close are rendered large. One sprite per obstacle handles all sizes.
- **Naming must match exactly** — the filenames above are what the code looks for
- **Incremental delivery OK** — drop in one asset at a time, the game uses
  procedural rendering for anything missing
