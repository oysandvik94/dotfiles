#!/usr/bin/env python3

from __future__ import annotations

import json
import sys
from typing import Any

from slack_mcp_common import (
    SlackMcpError,
    TOKEN_PATH,
    load_app_config,
    load_token,
    refresh_token,
    save_token,
    slack_api_get,
    slack_api_post,
    token_is_expired,
)


PROTOCOL_VERSION = "2024-11-05"


TOOLS = [
    {
        "name": "auth_status",
        "description": "Show which Slack user and workspace this MCP is authenticated as.",
        "inputSchema": {"type": "object", "properties": {}, "additionalProperties": False},
    },
    {
        "name": "list_conversations",
        "description": "List accessible Slack conversations including channels, private channels, DMs, and MPDMs.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "types": {
                    "type": "array",
                    "items": {
                        "type": "string",
                        "enum": ["public_channel", "private_channel", "im", "mpim"],
                    },
                },
                "limit": {"type": "integer", "minimum": 1, "maximum": 999},
                "cursor": {"type": "string"},
                "exclude_archived": {"type": "boolean"},
            },
            "additionalProperties": False,
        },
    },
    {
        "name": "read_messages",
        "description": "Read Slack messages from a conversation or thread.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "channel": {"type": "string"},
                "limit": {"type": "integer", "minimum": 1, "maximum": 999},
                "oldest": {"type": "string"},
                "latest": {"type": "string"},
                "inclusive": {"type": "boolean"},
                "thread_ts": {"type": "string"},
            },
            "required": ["channel"],
            "additionalProperties": False,
        },
    },
    {
        "name": "search_messages",
        "description": "Search Slack messages visible to the authenticated user.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "query": {"type": "string"},
                "count": {"type": "integer", "minimum": 1, "maximum": 100},
                "page": {"type": "integer", "minimum": 1, "maximum": 100},
                "sort": {"type": "string", "enum": ["score", "timestamp"]},
                "sort_dir": {"type": "string", "enum": ["asc", "desc"]},
            },
            "required": ["query"],
            "additionalProperties": False,
        },
    },
    {
        "name": "send_message",
        "description": "Send a Slack message as the authenticated user to a channel, DM, or MPDM.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "channel": {"type": "string"},
                "text": {"type": "string"},
                "thread_ts": {"type": "string"},
                "users": {
                    "type": "array",
                    "items": {"type": "string"},
                    "minItems": 1,
                    "maxItems": 8,
                },
            },
            "required": ["text"],
            "additionalProperties": False,
        },
    },
]


def read_message() -> dict[str, Any] | None:
    headers: dict[str, str] = {}
    while True:
        line = sys.stdin.buffer.readline()
        if not line:
            return None
        decoded = line.decode("utf-8").strip()
        if not decoded:
            break
        key, value = decoded.split(":", 1)
        headers[key.lower()] = value.strip()

    content_length = int(headers.get("content-length", "0"))
    if content_length <= 0:
        return None
    payload = sys.stdin.buffer.read(content_length)
    return json.loads(payload.decode("utf-8"))


def write_message(payload: dict[str, Any]) -> None:
    body = json.dumps(payload).encode("utf-8")
    sys.stdout.buffer.write(f"Content-Length: {len(body)}\r\n\r\n".encode("utf-8"))
    sys.stdout.buffer.write(body)
    sys.stdout.buffer.flush()


def success_text(text: str) -> dict[str, Any]:
    return {"content": [{"type": "text", "text": text}], "isError": False}


def error_text(text: str) -> dict[str, Any]:
    return {"content": [{"type": "text", "text": text}], "isError": True}


def get_token() -> str:
    token_data = load_token()
    if token_is_expired(token_data):
        refreshed = refresh_token(load_app_config(), token_data)
        save_token(refreshed, path=TOKEN_PATH)
        token_data = refreshed
    return token_data["access_token"]


def format_json(data: Any) -> str:
    return json.dumps(data, indent=2, sort_keys=True)


def handle_tool_call(name: str, arguments: dict[str, Any]) -> dict[str, Any]:
    try:
        if name == "auth_status":
            auth = slack_api_get(get_token(), "auth.test")
            return success_text(format_json(auth))

        if name == "list_conversations":
            params = {
                "types": ",".join(arguments.get("types") or ["public_channel", "private_channel", "im", "mpim"]),
                "limit": arguments.get("limit", 100),
                "exclude_archived": json.dumps(arguments.get("exclude_archived", True)),
            }
            if arguments.get("cursor"):
                params["cursor"] = arguments["cursor"]
            response = slack_api_get(get_token(), "conversations.list", params)
            return success_text(format_json(response))

        if name == "read_messages":
            params = {
                "channel": arguments["channel"],
                "limit": arguments.get("limit", 50),
            }
            if arguments.get("oldest"):
                params["oldest"] = arguments["oldest"]
            if arguments.get("latest"):
                params["latest"] = arguments["latest"]
            if arguments.get("inclusive") is not None:
                params["inclusive"] = json.dumps(arguments["inclusive"])
            method = "conversations.history"
            if arguments.get("thread_ts"):
                method = "conversations.replies"
                params["ts"] = arguments["thread_ts"]
            response = slack_api_get(get_token(), method, params)
            return success_text(format_json(response))

        if name == "search_messages":
            response = slack_api_get(
                get_token(),
                "search.messages",
                {
                    "query": arguments["query"],
                    "count": arguments.get("count", 20),
                    "page": arguments.get("page", 1),
                    "sort": arguments.get("sort", "timestamp"),
                    "sort_dir": arguments.get("sort_dir", "desc"),
                },
            )
            return success_text(format_json(response))

        if name == "send_message":
            channel = arguments.get("channel")
            if not channel and not arguments.get("users"):
                raise SlackMcpError("Provide either channel or users.")
            if not channel:
                open_response = slack_api_post(
                    get_token(),
                    "conversations.open",
                    {"users": ",".join(arguments["users"])},
                )
                channel = open_response["channel"]["id"]
            payload = {"channel": channel, "text": arguments["text"]}
            if arguments.get("thread_ts"):
                payload["thread_ts"] = arguments["thread_ts"]
            response = slack_api_post(get_token(), "chat.postMessage", payload)
            return success_text(format_json(response))

        raise SlackMcpError(f"Unknown tool: {name}")
    except SlackMcpError as exc:
        return error_text(str(exc))


def handle_request(request: dict[str, Any]) -> dict[str, Any] | None:
    method = request.get("method")
    request_id = request.get("id")

    if method == "notifications/initialized":
        return None

    if method == "ping":
        return {"jsonrpc": "2.0", "id": request_id, "result": {}}

    if method == "initialize":
        return {
            "jsonrpc": "2.0",
            "id": request_id,
            "result": {
                "protocolVersion": PROTOCOL_VERSION,
                "capabilities": {"tools": {}},
                "serverInfo": {"name": "slack-user", "version": "0.1.0"},
            },
        }

    if method == "tools/list":
        return {"jsonrpc": "2.0", "id": request_id, "result": {"tools": TOOLS}}

    if method == "tools/call":
        params = request.get("params", {})
        result = handle_tool_call(params["name"], params.get("arguments") or {})
        return {"jsonrpc": "2.0", "id": request_id, "result": result}

    return {
        "jsonrpc": "2.0",
        "id": request_id,
        "error": {"code": -32601, "message": f"Method not found: {method}"},
    }


def main() -> int:
    while True:
        request = read_message()
        if request is None:
            return 0
        response = handle_request(request)
        if response is not None:
            write_message(response)


if __name__ == "__main__":
    raise SystemExit(main())
