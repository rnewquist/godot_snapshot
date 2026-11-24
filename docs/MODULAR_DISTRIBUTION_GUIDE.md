# Installing and Sharing the Addon Across Projects

This guide explains how to copy or share the `gdtest` and Godot Scene Snapshot (GSS) addon across your Godot 4 projects.

## Folder Layout

The main addon files live in `packages/gdtest/addons/gdtest/`:

- `core/`: Main GSS snapshot engine, live recorder, in-game hotkey overlay, test runner, and helpers.
- `ui/`: Godot Editor bottom panel and new test suite dialog.
- `script_templates/`: Starter GDScript templates for Godot.
- `plugin.gd` and `plugin.cfg`: Godot Editor plugin setup.

## Option 1: Install with the CLI (Fastest)

Run the install script and point it at your Godot project folder:

```bash
python3 packages/gdtest/tools/gdtest_cli.py install path/to/your/project
```

This copies `addons/gdtest` into your project, turns on the plugin in `project.godot`, and creates `tests/` and `artifacts/` folders if they do not exist yet.

If you also want the in-game `F9`, `F10`, and `F11` snapshot hotkeys, run:

```bash
python3 packages/gdtest/tools/gss_cli.py enable-overlay path/to/your/project
```

To update an existing project later, run:

```bash
python3 packages/gdtest/tools/gdtest_cli.py update path/to/your/project
```

## Option 2: Copy by Hand

1. Copy `packages/gdtest/addons/gdtest/` into `<your_project>/addons/gdtest/`.
2. Open your project in Godot.
3. Go to **Project > Project Settings > Plugins** and enable **GDTest**.
4. (Optional) Go to **Project > Project Settings > Globals > Autoload** and add `res://addons/gdtest/core/gss_overlay.gd` as `GSSOverlay` for in-game hotkeys.

## Option 3: Use as a Git Submodule

If you want to track this repository inside another Git project:

```bash
cd path/to/your/project
git submodule add https://github.com/rnewquist/godot_snapshot.git vendor/godot_snapshot
```

Then copy or link `vendor/godot_snapshot/packages/gdtest/addons/gdtest` into `addons/gdtest`.

To pull newer updates later:

```bash
git submodule update --remote --merge
```

## Syncing Across Multiple Local Projects

If you have several local projects in one workspace, you can copy updates across them with `godot_test.py`:

```bash
# Copy the latest addon files to all projects in the workspace
python3 framework/cli/godot_test.py sync workspace

# Preview what would change without modifying any files
python3 framework/cli/godot_test.py sync --dry-run
```
