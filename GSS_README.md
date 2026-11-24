# Godot Scene Snapshot (GSS) User Guide

Godot Scene Snapshot (GSS) is a tool for taking inspectable snapshots and frame-by-frame recordings of any Godot 4 game.

There are two modes:

1. **Static GSS**: Takes a screenshot of the current frame and saves all node data (positions, sizes, physics, script variables, and shaders) into a browser-ready HTML file.
2. **Live GSS**: Records a starting frame and then saves only what changes on each frame after that. You can play it back in your browser, scrub frame by frame, and see movement paths, bounces, and shader changes.

## Files Created

- **Static GSS** creates `<name>.png`, `<name>.gss.json`, and `<name>.gss.html`.
- **Live GSS** creates `<name>.gss.live.json` and `<name>.gss.live.html`.

By default, everything is saved in `<your_project>/artifacts/gss/`.

---

## 1. How to Capture Snapshots

You can capture snapshots in three ways: with in-game hotkeys, from the terminal, or directly in GDScript.

### Option A: In-Game Hotkeys (Easiest While Playing)

You can add `GSSOverlay` to your project so you can take snapshots while playing your game normally.

**Setup (pick one):**

Run this command once to add `GSSOverlay` as an Autoload in `project.godot`:

```bash
python3 packages/gdtest/tools/gss_cli.py enable-overlay path/to/your/project
```

Or add it by hand in Godot:
1. Go to **Project > Project Settings > Globals > Autoload**.
2. Pick `res://addons/gdtest/core/gss_overlay.gd` and name it `GSSOverlay`.
3. Click **Add**.

**Controls while playing:**

- **F9 (Snap)**: Takes a static screenshot snapshot.
- **F10 (Live)**: Starts a Live GSS recording. Press **F10** again to stop and save it.
- **F11 (Open)**: Opens the last snapshot or recording in your web browser.

The small toolbar in the top-right corner hides itself automatically while taking a screenshot so it never gets in the way.

### Option B: Command Line (No Code Needed)

Use `packages/gdtest/tools/gss_cli.py` to capture any scene right from your terminal.

**Take a static snapshot:**

```bash
# Capture the main scene and open it in your browser
python3 packages/gdtest/tools/gss_cli.py snap demo_2d --open

# Capture a specific scene with a custom name
python3 packages/gdtest/tools/gss_cli.py snap showcase_mega \
  --scene res://main_master_showcase.tscn \
  --name my_shader_snap \
  --wait-frames 10 \
  --open
```

**Record a Live GSS timeline:**

```bash
# Record 60 physics frames and open the player
python3 packages/gdtest/tools/gss_cli.py live demo_3d \
  --scene res://main_3d.tscn \
  --name my_3d_live \
  --frames 60 \
  --open

# Record 45 process frames (good for UI animations or shaders)
python3 packages/gdtest/tools/gss_cli.py live showcase_mega \
  --frames 45 \
  --step-mode process \
  --open
```

**Useful options:**

- `--scene res://...tscn`: Pick which scene to open (uses the project's main scene if left out).
- `--name my_name`: Set the output filename.
- `--out res://...`: Change where files are saved (default is `res://artifacts/gss`).
- `--wait-frames 5`: Wait a few frames before capturing so lights, shaders, and physics settle.
- `--frames 60`: How many frames to record in `live` mode.
- `--step-mode physics|process`: Record on physics ticks (default) or normal frames.
- `--headless`: Run without opening a GPU window. Faster for data checks, but uses a simple wireframe preview instead of a real rendered screenshot.
- `--open`: Open the HTML report in your browser as soon as it finishes.

### Option C: From Your Own GDScript

```gdscript
# Take a single snapshot
GSS.capture(self, "boss_phase_2")

# Record 60 frames
var live_res := await GSS.record_frames(self, 60, "boss_jump")

# Start and stop manually
var rec := GSS.start_recording(self, "manual_clip")
# ... gameplay happens ...
var result := rec.stop()
```

---

## 2. How to Open and Use the HTML Inspector

Every `.gss.html` and `.gss.live.html` file works on its own. You can open one by:

- Pressing **F11** in-game.
- Double-clicking the file in Finder or File Explorer.
- Running `open` from the terminal:

```bash
# Open a specific file
python3 packages/gdtest/tools/gss_cli.py open showcase_mega/artifacts/gss/mega_showcase_05_shaders.gss.html

# Open the newest capture in a project folder
python3 packages/gdtest/tools/gss_cli.py open showcase_mega
```

### What You See in the Inspector

- **Left side (Component Tree)**: Lists every node in the scene. You can search by name or class. Shaded nodes, scripted nodes, and nodes that changed on the current frame are clearly marked.
- **Middle (Viewport)**: Shows the screenshot with clickable boxes around each node. Click any box to inspect that node. In Live GSS files, you also see motion trails, bounce markers, and Play / Pause / Next / Prev / Speed controls.
- **Right side (Inspector)**: Shows the selected node's path, screen box, position, physics values, script variables, signals, and shader uniforms (with color swatches for color uniforms).

---

## 3. How to Check Snapshots from the Terminal

You can inspect snapshot files in the terminal with `analyze`:

```bash
# Readable summary of all captures in a project
python3 packages/gdtest/tools/gss_cli.py analyze showcase_mega

# Check a single Live GSS file
python3 packages/gdtest/tools/gss_cli.py analyze demo_3d/artifacts/gss/sphere_bounce_3d.gss.live.json

# Print JSON output for scripts
python3 packages/gdtest/tools/gss_cli.py analyze showcase_mega --json
```

`analyze` tells you:
- Whether the HTML inspector file is present and valid.
- Whether the screenshot was rendered on the GPU or in headless mode.
- How many nodes and shaders are in the scene.
- For Live GSS: how many frames were recorded, which nodes moved the farthest, and how many bounces were detected.

You can also rebuild any past frame in GDScript:

```gdscript
# Get the full scene state at frame 24
var frame_24: Dictionary = GSS.reconstruct_frame(live_data, 24)

# Move live nodes in your scene back to where they were at frame 24
GSS.apply_frame_to_scene(scene_root, live_data, 24)
```

---

## 4. Installing Into Another Godot Project

```bash
# Copy the addon into your project
python3 packages/gdtest/tools/gdtest_cli.py install path/to/your/project

# Optional: turn on F9/F10/F11 hotkeys
python3 packages/gdtest/tools/gss_cli.py enable-overlay path/to/your/project
```

---

## 5. Common Questions

**Why is my screenshot a dark wireframe instead of my real game?**
You ran with `--headless`. Godot's headless mode turns off GPU rendering. Run `gss_cli.py snap` or `live` without `--headless` to get real screenshots.

**Godot binary not found?**
Set `GODOT_BIN` to your Godot executable path:

```bash
export GODOT_BIN="/Applications/Godot.app/Contents/MacOS/Godot"
```

**F9, F10, or F11 conflicts with my game keys?**
Select `GSSOverlay` in your scene or edit its exported key settings in `gss_overlay.gd` to pick different keys.
