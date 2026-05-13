#!/usr/bin/env python3

from __future__ import annotations

import argparse
import http.server
import threading
import urllib.parse
import webbrowser
from pathlib import Path

from slack_mcp_common import (
    DEFAULT_ENV_PATH,
    TOKEN_PATH,
    USER_TOKEN_SCOPES,
    SlackMcpError,
    build_code_challenge,
    build_token_payload,
    build_authorize_url,
    exchange_code_for_token,
    generate_code_verifier,
    load_app_config,
    save_token,
    slack_api_get,
)


class OAuthCallbackHandler(http.server.BaseHTTPRequestHandler):
    server_version = "SlackMcpAuth/1.0"

    def do_GET(self) -> None:  # noqa: N802
        query = urllib.parse.urlparse(self.path).query
        params = urllib.parse.parse_qs(query)
        self.server.oauth_params = {key: values[0] for key, values in params.items()}

        if params.get("error"):
            self._send_page("Slack auth failed. You can close this tab.")
            return

        self._send_page("Slack auth complete. You can close this tab.")

    def log_message(self, format: str, *args) -> None:
        return

    def _send_page(self, message: str) -> None:
        body = (
            "<html><body><h1>"
            + message
            + "</h1><p>Return to Codex.</p></body></html>"
        ).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Authenticate Slack MCP user token")
    parser.add_argument("--env-file", default=str(DEFAULT_ENV_PATH))
    parser.add_argument("--no-open", action="store_true")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    config = load_app_config(path=Path(args.env_file))
    state = __import__("secrets").token_urlsafe(32)
    code_verifier = generate_code_verifier()
    code_challenge = build_code_challenge(code_verifier)
    url = build_authorize_url(
        config=config,
        scopes=USER_TOKEN_SCOPES,
        state=state,
        code_challenge=code_challenge,
    )

    with http.server.ThreadingHTTPServer(
        (config.redirect_host, config.redirect_port),
        OAuthCallbackHandler,
    ) as server:
        server.timeout = 1
        stop_event = threading.Event()

        def serve() -> None:
            while not stop_event.is_set() and not getattr(server, "oauth_params", None):
                server.handle_request()

        thread = threading.Thread(target=serve, daemon=True)
        thread.start()

        print(f"Slack auth URL:\n{url}\n")
        if not args.no_open:
            webbrowser.open(url)

        thread.join(timeout=300)
        stop_event.set()

    params = getattr(server, "oauth_params", None)
    if not params:
        raise SlackMcpError("Timed out waiting for Slack OAuth callback.")
    if params.get("state") != state:
        raise SlackMcpError("Slack OAuth state mismatch.")
    if params.get("error"):
        raise SlackMcpError(f"Slack OAuth error: {params['error']}")

    token_response = exchange_code_for_token(
        config=config,
        code=params["code"],
        code_verifier=code_verifier,
    )
    auth_info = slack_api_get(token_response["access_token"], "auth.test")
    save_token(build_token_payload(token_response, auth_info), path=TOKEN_PATH)
    print(f"Saved Slack token to {TOKEN_PATH}")
    print(f"Authenticated as {auth_info.get('user')} in {auth_info.get('team')}")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except SlackMcpError as exc:
        print(f"Error: {exc}")
        raise SystemExit(1)
