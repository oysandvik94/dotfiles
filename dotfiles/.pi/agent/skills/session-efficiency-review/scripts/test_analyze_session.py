#!/usr/bin/env python3

import json
import subprocess
import tempfile
import unittest
from pathlib import Path

SCRIPT = Path(__file__).with_name("analyze_session.py")


class AnalyzeSessionTest(unittest.TestCase):
    def test_active_branch_string_content_and_redaction(self):
        records = [
            {"type": "session", "version": 3, "id": "session", "timestamp": "t", "cwd": "/tmp"},
            {"type": "message", "id": "user", "parentId": None, "timestamp": "t", "message": {"role": "user", "content": "task"}},
            {"type": "message", "id": "old", "parentId": "user", "timestamp": "t", "message": {"role": "assistant", "content": [{"type": "toolCall", "id": "call", "name": "bash", "arguments": {"command": "curl -H 'Authorization: Bearer abc'", "apiKey": "key-secret"}}], "usage": {"input": 10, "output": 1, "cacheRead": 0, "reasoning": 0, "totalTokens": 11}}},
            {"type": "message", "id": "result", "parentId": "old", "timestamp": "t", "message": {"role": "toolResult", "toolName": "bash", "isError": True, "content": "{\"token\":\"very-secret\"} token=another-secret"}},
            {"type": "message", "id": "active", "parentId": "user", "timestamp": "t", "message": {"role": "assistant", "content": "done", "usage": {"input": 2, "output": 1, "cacheRead": 1, "reasoning": 0, "totalTokens": 4}}},
        ]
        with tempfile.TemporaryDirectory() as directory:
            session = Path(directory) / "session.jsonl"
            session.write_text("".join(json.dumps(record) + "\n" for record in records))
            report = subprocess.check_output([SCRIPT, session], text=True)
            self.assertIn("Excluded off-branch records: 2", report)
            self.assertIn("1 user, 1 assistant, 0 tool results", report)
            self.assertNotIn("very-secret", report)

            redacted = subprocess.check_output([SCRIPT, session, "--all-branches", "--show", "3,4"], text=True)
            self.assertIn('"token":"[REDACTED]"', redacted)
            self.assertIn("token=[REDACTED]", redacted)
            self.assertNotIn("very-secret", redacted)
            self.assertNotIn("another-secret", redacted)
            self.assertNotIn("key-secret", redacted)
            self.assertNotIn("Bearer abc", redacted)

            raw = subprocess.check_output([SCRIPT, session, "--all-branches", "--show", "4", "--raw-content"], text=True)
            self.assertIn("very-secret", raw)

    def test_repeated_tool_sequence_candidates(self):
        usage = {"input": 1, "output": 1, "cacheRead": 0, "reasoning": 1, "totalTokens": 3}
        tool_calls = [
            {"type": "toolCall", "id": "read", "name": "read", "arguments": {"path": "file.java"}},
            {"type": "toolCall", "id": "test", "name": "bash", "arguments": {"command": "./mvnw test"}},
        ]
        records = [
            {"type": "session", "version": 3, "id": "session", "timestamp": "t", "cwd": "/tmp"},
            {"type": "message", "id": "u1", "parentId": None, "timestamp": "t", "message": {"role": "user", "content": "first"}},
            {"type": "message", "id": "a1", "parentId": "u1", "timestamp": "t", "message": {"role": "assistant", "content": tool_calls, "usage": usage}},
            {"type": "message", "id": "u2", "parentId": "a1", "timestamp": "t", "message": {"role": "user", "content": "second"}},
            {"type": "message", "id": "a2", "parentId": "u2", "timestamp": "t", "message": {"role": "assistant", "content": tool_calls, "usage": usage}},
        ]
        with tempfile.TemporaryDirectory() as directory:
            session = Path(directory) / "session.jsonl"
            session.write_text("".join(json.dumps(record) + "\n" for record in records))
            report = subprocess.check_output([SCRIPT, session], text=True)
            self.assertIn("2× read → bash:maven at L3,L5", report)


if __name__ == "__main__":
    unittest.main()
