import json
import os
import shutil
import sys
import tempfile
import unittest
from pathlib import Path

TOOLS_DIR = Path(__file__).resolve().parent.parent / "tools"
WORKSPACE_ROOT = Path(__file__).resolve().parent.parent.parent.parent
sys.path.insert(0, str(TOOLS_DIR))

import gss_cli  # noqa: E402


class TestGSSCli(unittest.TestCase):
    def test_parse_cli_result(self) -> None:
        stdout = (
            "Godot Engine v4.6.2\n"
            "[GSS_CLI_RESULT] {\"success\": true, \"mode\": \"snap\", \"total_nodes\": 19}\n"
        )
        parsed = gss_cli.parse_cli_result(stdout)
        self.assertIsNotNone(parsed)
        self.assertTrue(parsed["success"])
        self.assertEqual(parsed["mode"], "snap")
        self.assertEqual(parsed["total_nodes"], 19)

    def test_check_html_inspector_static_and_live(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            valid_static = tmp_path / "ok.gss.html"
            valid_static.write_text(
                "<div id='tree-container'></div><div id='bbox-overlay'></div><div id='props-container'></div>",
                encoding="utf-8",
            )
            self.assertEqual(gss_cli.check_html_inspector(valid_static, is_live=False), [])

            broken_live = tmp_path / "broken.gss.live.html"
            broken_live.write_text(
                "<div id='tree-container'></div><div id='bbox-overlay'></div><div id='props-container'></div>",
                encoding="utf-8",
            )
            issues = gss_cli.check_html_inspector(broken_live, is_live=True)
            self.assertEqual(len(issues), 1)
            self.assertIn("frame-scrubber", issues[0])

    def test_resolve_html_to_open(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            tmp_path = Path(tmp)
            html1 = tmp_path / "a.gss.html"
            json1 = tmp_path / "a.gss.json"
            html1.write_text("<html></html>", encoding="utf-8")
            json1.write_text("{}", encoding="utf-8")

            self.assertEqual(gss_cli.resolve_html_to_open(html1), html1)
            self.assertEqual(gss_cli.resolve_html_to_open(json1), html1)
            self.assertEqual(gss_cli.resolve_html_to_open(tmp_path), html1)

    def test_enable_overlay_in_project_godot_idempotent(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            proj = Path(tmp)
            (proj / "addons" / "gdtest" / "core").mkdir(parents=True)
            proj_godot = proj / "project.godot"
            proj_godot.write_text('[application]\nconfig/name="Demo"\n', encoding="utf-8")

            added_first = gss_cli.enable_overlay_in_project_godot(proj)
            self.assertTrue(added_first)
            content = proj_godot.read_text(encoding="utf-8")
            self.assertIn("[autoload]", content)
            self.assertIn('GSSOverlay="*res://addons/gdtest/core/gss_overlay.gd"', content)
            self.assertTrue((proj / "addons" / "gdtest" / "core" / "gss_overlay.gd").exists())

            added_second = gss_cli.enable_overlay_in_project_godot(proj)
            self.assertFalse(added_second)

    def test_e2e_snap_live_and_analyze_on_demo_2d(self) -> None:
        demo_2d = WORKSPACE_ROOT / "demo_2d"
        if not demo_2d.exists():
            self.skipTest("demo_2d project not present")

        tmp_out_dir = demo_2d / "artifacts" / "gss_cli_test_tmp"
        if tmp_out_dir.exists():
            shutil.rmtree(tmp_out_dir)

        try:
            # 1. Static GSS Screenshot capture via CLI (headless for fast CI determinism)
            rc_snap = gss_cli.main([
                "snap",
                str(demo_2d),
                "--scene", "res://main_2d.tscn",
                "--name", "cli_test_snap",
                "--out", "res://artifacts/gss_cli_test_tmp",
                "--wait-frames", "2",
                "--headless",
            ])
            self.assertEqual(rc_snap, 0)
            self.assertTrue((tmp_out_dir / "cli_test_snap.png").exists())
            self.assertTrue((tmp_out_dir / "cli_test_snap.gss.json").exists())
            self.assertTrue((tmp_out_dir / "cli_test_snap.gss.html").exists())

            # 2. Live GSS Delta capture via CLI
            rc_live = gss_cli.main([
                "live",
                str(demo_2d),
                "--scene", "res://main_2d.tscn",
                "--name", "cli_test_live",
                "--frames", "5",
                "--out", "res://artifacts/gss_cli_test_tmp",
                "--wait-frames", "2",
                "--headless",
            ])
            self.assertEqual(rc_live, 0)
            self.assertTrue((tmp_out_dir / "cli_test_live.gss.live.json").exists())
            self.assertTrue((tmp_out_dir / "cli_test_live.gss.live.html").exists())

            # 3. Analyze both captures via CLI
            rc_an = gss_cli.main(["analyze", str(tmp_out_dir)])
            self.assertEqual(rc_an, 0)

            snap_report = gss_cli.analyze_single_file(tmp_out_dir / "cli_test_snap.gss.json")
            self.assertTrue(snap_report["valid"])
            self.assertTrue(snap_report["html_inspector_present"])
            self.assertGreater(snap_report["total_nodes"], 0)

            live_report = gss_cli.analyze_single_file(tmp_out_dir / "cli_test_live.gss.live.json")
            self.assertTrue(live_report["valid"])
            self.assertTrue(live_report["html_inspector_present"])
            self.assertGreaterEqual(live_report["total_frames"], 5)
        finally:
            if tmp_out_dir.exists():
                shutil.rmtree(tmp_out_dir)


if __name__ == "__main__":
    unittest.main()
