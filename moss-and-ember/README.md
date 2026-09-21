# Moss & Ember

A cozy 3D farm sim — our first product. **Slice 0.1** (proof of concept) is
playable right now in the browser; no installation, no PC required.

## What's in the slice

- Third-person farmer on a small valley farm (walk, run, orbit camera)
- 12 farm cells, 3 crops (wheat / tomato / pumpkin) with 4 growth stages
- Full economy loop: plant → grow → harvest → sell at Pip's stall → buy seeds
- Day/night cycle (~8 real minutes per day) with sunset, stars, glowing barn window
- A chicken that wanders, pecks, flees from you, and can be petted
- Pip the neighbor: dialogue + shop
- Save/continue (persists in your browser's storage)
- Procedural chiptune music + sound effects (no external assets)
- Touch controls (phone): virtual joystick + camera drag + action button
- Keyboard/mouse: **WASD** move · **Shift** run · **drag right side / Q,R** camera
  · **E** interact · **1/2/3** select seed · **M** mute

## How it was built (and how to run it elsewhere)

- **Engine:** Godot 4.7.2 (Forward+ / mobile renderer), pure GDScript, all
  geometry is procedural primitives — zero external art assets.
- **Browser build:** the sandbox builds the Godot engine from source (no
  internet access to the official CDN here), and the web template comes from a
  public npm package; `web/boot.js` stages the project into the engine's
  in-memory FS and boots it. `web/serve.py` assembles + serves the site.
- **Local editor run:** open this folder in Godot 4.7.2 and press F5.
- **Windows export (needs internet once):** install the official Godot
  4.7.2 export templates, then:
  `godot --headless --export-release "Windows Desktop" build/windows/MossEmber.exe`
- **Self-test:** `godot --headless --path . -- --self-test`
  (validates the full economy/plant/save loop headlessly).

## Slice → full game roadmap

1. **Slice 0.1 (this)** — core loop, one day, one villager, one animal
2. Seasons (what you can plant changes), weather, more crops & animals
3. Quest system: villagers give repeatable + story quests
4. More of the valley: forest (chopping), lake (fishing), cave (mining)
5. Upgrades: fence extensions, barn storage, farm tools
6. Art pass: replace primitives with a full stylized art pass
7. Steam page, trailer, Next Fest debut

## Repo layout

```
project.godot         Godot project settings
scenes/               main, player, farm, crop, chicken, villager
scripts/              GDScript (autoloads/, world builder, entities, ui)
audio/                generated WAVs (music + sfx)
web/                  browser bootstrap (boot.js, index.html, serve.py)
build/                generated output (not committed)
```
