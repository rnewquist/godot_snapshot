# GDTest and Godot Scene Snapshot (GSS)

A Godot 4 addon for taking inspectable scene snapshots, recording frame-by-frame timelines, and running unit and integration tests.

## Main Features

- **Unit and Integration Tests**: Write GDScript test suites with scene mounting, frame stepping, simulated input, and automatic cleanup.
- **Static GSS**: Save a screenshot along with all node properties, screen bounds, and shader uniforms into a browser-ready HTML file.
- **Live GSS**: Record a starting frame and per-frame changes to replay movement paths, bounces, and shader updates.
- **In-Game Hotkeys and CLI**: Press `F9`, `F10`, and `F11` while playing, or run `tools/gss_cli.py` from the terminal.

## Quick Start

```bash
# Install the addon into a Godot 4 project
python3 tools/gdtest_cli.py install path/to/your/project

# Run test suites
python3 tools/gdtest_cli.py run path/to/your/project

# Capture a static or live snapshot from the terminal
python3 tools/gss_cli.py snap path/to/your/project --open
python3 tools/gss_cli.py live path/to/your/project --frames 60 --open
```

## License

MIT License.
