#!/usr/bin/env python3
"""
Unit and integration tests for MacOSEmbeddedDebugSession and Godot 4
RemoteDebugger embedded windowless GPU execution and graceful shutdown.
"""

import struct
import subprocess
import time
import unittest
from pathlib import Path

from godot_test import (
    MacOSEmbeddedDebugSession,
    build_remote_debugger_close_packet,
    find_godot_binary,
)


class TestMacOSEmbeddedSession(unittest.TestCase):
    def test_build_remote_debugger_close_packet_wire_format(self) -> None:
        pkt = build_remote_debugger_close_packet()
        self.assertGreater(len(pkt), 4)
        total_payload_len = struct.unpack_from("<I", pkt, 0)[0]
        self.assertEqual(total_payload_len, len(pkt) - 4)

        # Outer Variant::ARRAY (28) of length 3
        outer_type, outer_len = struct.unpack_from("<II", pkt, 4)
        self.assertEqual(outer_type, 28)
        self.assertEqual(outer_len, 3)

        # Element 0: Variant::STRING (4) "embed:win_event" (15 bytes + 1 pad byte)
        str_type, str_len = struct.unpack_from("<II", pkt, 12)
        self.assertEqual(str_type, 4)
        self.assertEqual(str_len, 15)
        self.assertEqual(pkt[20:35], b"embed:win_event")
        self.assertEqual(pkt[35:36], b"\x00")

        # Element 1: Variant::INT (2) = 1 (Thread::MAIN_ID)
        thr_type, thr_id = struct.unpack_from("<Ii", pkt, 36)
        self.assertEqual(thr_type, 2)
        self.assertEqual(thr_id, 1)

        # Element 2: Variant::ARRAY (28) of length 1 containing Variant::INT (2) = 4
        arr_type, arr_len, ev_type, ev_val = struct.unpack_from("<IIIi", pkt, 44)
        self.assertEqual(arr_type, 28)
        self.assertEqual(arr_len, 1)
        self.assertEqual(ev_type, 2)
        self.assertEqual(ev_val, 4)  # DisplayServer.WINDOW_EVENT_CLOSE_REQUEST

    def test_session_lifecycle_and_cli_args(self) -> None:
        session = MacOSEmbeddedDebugSession()
        try:
            args = session.cli_args("1920x1080")
            self.assertGreater(session.port, 0)
            self.assertIn("--embedded", args)
            self.assertIn("embedded", args)
            self.assertIn(f"tcp://127.0.0.1:{session.port}", args)
            self.assertIn("--disable-crash-handler", args)
            self.assertIn("1920x1080", args)
        finally:
            session.close()

    def test_live_godot_embedded_gpu_boot_and_graceful_close(self) -> None:
        godot_bin = find_godot_binary()
        guildmaster_dir = Path("/Users/rnewquist/Documents/Godot/GuildMaster")
        if not guildmaster_dir.exists():
            self.skipTest("GuildMaster project directory not present")

        diag_dir = Path.home() / "Library" / "Logs" / "DiagnosticReports"
        before_ips = set(diag_dir.glob("Godot*.ips")) if diag_dir.exists() else set()

        session = MacOSEmbeddedDebugSession()
        try:
            cmd = (
                [godot_bin, "--path", str(guildmaster_dir)]
                + session.cli_args("1280x720")
                + ["res://scenes/shader_playground_showcase.tscn"]
            )
            proc = subprocess.Popen(
                cmd,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
            )
            time.sleep(1.5)
            # Process should still be running in embedded Metal mode
            self.assertIsNone(proc.poll())

            t0 = time.time()
            rc = session.request_graceful_close(proc, grace_timeout=5.0)
            elapsed = time.time() - t0
            out, _ = proc.communicate(timeout=2.0)

            self.assertEqual(rc, 0)
            self.assertLess(elapsed, 2.5)
            self.assertIn("Metal", out)
        finally:
            session.close()

        after_ips = set(diag_dir.glob("Godot*.ips")) if diag_dir.exists() else set()
        self.assertEqual(before_ips, after_ips, "Zero new crash logs may be generated")


if __name__ == "__main__":
    unittest.main()
