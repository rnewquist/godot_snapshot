#!/usr/bin/env python3
"""Unit tests for the godot-testing-and-gss skill CLI (verify_godot_gss.py)."""

from __future__ import annotations

import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

CLI_PATH = Path("/Users/rnewquist/.gemini/config/skills/godot_testing_and_gss/script/verify_godot_gss.py")
WORKSPACE_ROOT = Path("/Users/rnewquist/Documents/Godot/tester")


class TestVerifyGodotGssCli(unittest.TestCase):
    """Tests audit, inspect-gss, and run subcommands of verify_godot_gss.py."""

    def test_cli_exists(self) -> None:
        self.assertTrue(CLI_PATH.is_file(), f"CLI script missing at {CLI_PATH}")

    def test_audit_valid_project_json(self) -> None:
        res = subprocess.run(
            [
                sys.executable,
                str(CLI_PATH),
                "audit",
                "--project-dir",
                str(WORKSPACE_ROOT / "demo_3d"),
                "--json",
            ],
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(res.returncode, 0, msg=res.stderr)
        payload = json.loads(res.stdout)
        self.assertEqual(payload["command"], "audit")
        self.assertTrue(payload["passed"])
        self.assertGreaterEqual(payload["files_scanned"], 1)
        self.assertGreaterEqual(payload["total_gss_calls"], 1)

    def test_audit_missing_path_returns_exit_code_2(self) -> None:
        res = subprocess.run(
            [
                sys.executable,
                str(CLI_PATH),
                "audit",
                "--project-dir",
                "/nonexistent/path/for/gss_audit_test",
                "--json",
            ],
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(res.returncode, 2)
        self.assertIn("ERROR:", res.stderr)

    def test_inspect_gss_static_and_live_synthetic(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            tmp_path = Path(tmpdir)
            static_file = tmp_path / "sample.gss.json"
            static_html = tmp_path / "sample.gss.html"
            static_html.write_text(
                "<html><body><div id='tree-container'></div><div id='bbox-overlay'></div><div id='props-container'></div></body></html>",
                encoding="utf-8",
            )
            static_file.write_text(
                json.dumps(
                    {
                        "format": "godot_scene_snapshot",
                        "gss_version": "1.0.0",
                        "title": "Sample Static GSS",
                        "summary": {
                            "total_nodes": 5,
                            "visible_nodes": 4,
                        },
                        "tree": {
                            "name": "Root",
                            "class": "Node3D",
                            "path": "/root/Root",
                            "categories": {},
                            "children": [],
                        },
                    }
                ),
                encoding="utf-8",
            )

            live_file = tmp_path / "sample.gss.live.json"
            live_html = tmp_path / "sample.gss.live.html"
            live_html.write_text(
                "<html><body><input id='frame-scrubber'><div id='tree-container'></div><div id='bbox-overlay'></div><div id='props-container'></div></body></html>",
                encoding="utf-8",
            )
            live_file.write_text(
                json.dumps(
                    {
                        "format": "godot_scene_snapshot_live",
                        "gss_live_version": "1.0.0",
                        "title": "Sample Live GSS",
                        "frame_count": 12,
                        "initial_gss": {"summary": {"total_nodes": 5}},
                        "frames": [{"frame": i, "delta": {"changed": {}, "added": {}, "removed": []}} for i in range(1, 12)],
                        "summary": {
                            "moving_node_count": 1,
                            "bounce_count": 2,
                        },
                    }
                ),
                encoding="utf-8",
            )

            res = subprocess.run(
                [
                    sys.executable,
                    str(CLI_PATH),
                    "inspect-gss",
                    "--path",
                    str(tmp_path),
                    "--json",
                ],
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(res.returncode, 0, msg=res.stderr)
            payload = json.loads(res.stdout)
            self.assertTrue(payload["passed"])
            self.assertEqual(payload["artifacts_checked"], 2)
            self.assertEqual(payload["static_gss_count"], 1)
            self.assertEqual(payload["live_gss_count"], 1)
            types = {item["type"]: item for item in payload["artifacts"]}
            self.assertEqual(types["GSS_STATIC"]["total_nodes"], 5)
            self.assertTrue(types["GSS_STATIC"]["html_inspector_present"])
            self.assertEqual(types["GSS_LIVE"]["bounces_detected"], 2)
            self.assertTrue(types["GSS_LIVE"]["html_inspector_present"])

            # Verify missing inspector DOM in companion HTML is flagged as invalid
            static_html.write_text("<html><body>No inspector</body></html>", encoding="utf-8")
            bad_res = subprocess.run(
                [sys.executable, str(CLI_PATH), "inspect-gss", "--path", str(static_file), "--json"],
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(bad_res.returncode, 1)
            bad_payload = json.loads(bad_res.stdout)
            self.assertFalse(bad_payload["passed"])
            self.assertFalse(bad_payload["artifacts"][0]["html_inspector_present"])

    def test_run_gdtest_meta_gss_suite(self) -> None:
        res = subprocess.run(
            [
                sys.executable,
                str(CLI_PATH),
                "run",
                "--project-dir",
                str(WORKSPACE_ROOT / "packages/gdtest"),
                "--mode",
                "gdtest",
                "--suite",
                "Meta_GSS_Suite",
                "--json",
            ],
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(res.returncode, 0, msg=res.stderr)
        payload = json.loads(res.stdout)
        self.assertTrue(payload["passed"])
        self.assertEqual(payload["exit_code"], 0)


if __name__ == "__main__":
    unittest.main()
