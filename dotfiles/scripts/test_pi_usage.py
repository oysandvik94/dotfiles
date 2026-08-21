#!/usr/bin/env python3
import importlib.util
import sys
import unittest
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo

SPEC = importlib.util.spec_from_file_location("pi_usage", Path(__file__).with_name("pi_usage.py"))
pi_usage = importlib.util.module_from_spec(SPEC)
assert SPEC.loader
sys.modules[SPEC.name] = pi_usage
SPEC.loader.exec_module(pi_usage)


class PiUsageFixtureTest(unittest.TestCase):
    def test_root_fork_child_and_resume_are_counted_once(self):
        root = Path(__file__).with_name("fixtures") / "pi-usage"
        tz = ZoneInfo("UTC")
        total, sessions, excluded, errors = pi_usage.scan(
            root,
            datetime(2026, 8, 1, tzinfo=tz),
            datetime(2026, 8, 2, tzinfo=tz),
            tz,
        )
        self.assertEqual(errors, [])
        self.assertEqual(total.cost, 10.5)
        self.assertEqual(total.input, 105)
        self.assertEqual(sessions["11111111-1111-4111-8111-111111111111"].totals.cost, 1)
        self.assertEqual(sessions["22222222-2222-4222-8222-222222222222"].totals.cost, 2)
        self.assertEqual(sessions["33333333-3333-4333-8333-333333333333"].totals.cost, 0.5)
        self.assertEqual(sessions["nested_transcript"].totals.cost, 7)
        self.assertEqual(len(excluded), 3)
        self.assertTrue(all("copied record identity" in entry["reason"] for entry in excluded))

    def test_ccusage_20_0_20_is_not_the_canonical_pi_aggregator(self):
        root = Path(__file__).with_name("fixtures") / "pi-usage"
        payload = pi_usage.ccusage([
            "bunx", f"ccusage@{pi_usage.CCUSAGE_VERSION}", "pi", "daily", "--json", "--pi-path", str(root),
            "--since", "2026-08-01", "--until", "2026-08-01", "--timezone", "UTC",
        ])
        self.assertIsNotNone(payload)
        self.assertNotEqual(pi_usage.ccusage_total(payload), 10.5)


if __name__ == "__main__":
    unittest.main()
