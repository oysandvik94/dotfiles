#!/usr/bin/env python3

import re
import subprocess
import sys
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("quiet_verify.py")


class QuietVerifierTest(unittest.TestCase):
    def test_success_is_one_line(self):
        result = subprocess.run(
            [SCRIPT, "--label", "demo", "--", sys.executable, "-c", "print('noise')"],
            text=True,
            capture_output=True,
        )
        self.assertEqual(0, result.returncode)
        self.assertRegex(result.stdout, r"^PASS demo \([0-9.]+s\)\n$")

    def test_failure_is_bounded_and_keeps_log(self):
        code = "print('noise'); print('ERROR useful failure'); raise SystemExit(7)"
        result = subprocess.run(
            [SCRIPT, "--label", "demo", "--", sys.executable, "-c", code],
            text=True,
            capture_output=True,
        )
        self.assertEqual(7, result.returncode)
        self.assertIn("FAIL demo (exit 7", result.stdout)
        self.assertIn("ERROR useful failure", result.stdout)
        match = re.search(r"Full output: (.+)\n", result.stdout)
        self.assertIsNotNone(match)
        log = Path(match.group(1))
        self.assertTrue(log.exists())
        self.assertEqual(0o600, log.stat().st_mode & 0o777)
        log.unlink()

    def test_timeout_stops_command(self):
        result = subprocess.run(
            [SCRIPT, "--label", "slow", "--timeout", "0.05", "--", sys.executable, "-c", "import time; time.sleep(30)"],
            text=True,
            capture_output=True,
            timeout=3,
        )
        self.assertEqual(124, result.returncode)
        self.assertIn("FAIL slow (TIMEOUT", result.stdout)
        self.remove_log(result.stdout)

    def test_signal_exit_is_normalized(self):
        code = "import os, signal; os.kill(os.getpid(), signal.SIGTERM)"
        result = subprocess.run(
            [SCRIPT, "--label", "signal", "--", sys.executable, "-c", code],
            text=True,
            capture_output=True,
        )
        self.assertEqual(143, result.returncode)
        self.assertIn("FAIL signal (signal 15", result.stdout)
        self.remove_log(result.stdout)

    def test_non_finite_timeout_is_rejected(self):
        result = subprocess.run(
            [SCRIPT, "--timeout", "nan", "--", sys.executable, "-c", "pass"],
            text=True,
            capture_output=True,
        )
        self.assertEqual(2, result.returncode)
        self.assertIn("positive finite number", result.stderr)

    def remove_log(self, output):
        match = re.search(r"Full output: (.+)\n", output)
        self.assertIsNotNone(match)
        Path(match.group(1)).unlink()


if __name__ == "__main__":
    unittest.main()
