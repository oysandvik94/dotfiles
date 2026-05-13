#!/usr/bin/env python3

from __future__ import annotations

import json
import os
import secrets
import time
import urllib.error
import urllib.parse
import urllib.request
import hashlib
import base64
from dataclasses import dataclass
from pathlib import Path


DEFAULT_ENV_PATH = Path.home() / ".config" / "slack-mcp.env"
STATE_DIR = Path.home() / ".local" / "state" / "slack-mcp"
TOKEN_PATH = STATE_DIR / "token.json"
DEFAULT_REDIRECT_HOST = "localhost"
DEFAULT_REDIRECT_PORT = 8765
AUTHORIZE_URL = "https://slack.com/oauth/v2_user/authorize"
TOKEN_URL = "https://slack.com/api/oauth.v2.user.access"
USER_TOKEN_SCOPES = [
    "channels:read",
    "groups:read",
    "im:read",
    "mpim:read",
    "channels:history",
    "groups:history",
    "im:history",
    "mpim:history",
    "channels:write",
    "groups:write",
    "im:write",
    "mpim:write",
    "chat:write",
    "users:read",
    "search:read",
]


class SlackMcpError(RuntimeError):
    pass


@dataclass(frozen=True)
class SlackAppConfig:
    client_id: str
    client_secret: str = ""
    redirect_host: str = DEFAULT_REDIRECT_HOST
    redirect_port: int = DEFAULT_REDIRECT_PORT

    @property
    def redirect_uri(self) -> str:
        return f"http://{self.redirect_host}:{self.redirect_port}/callback"


def load_env_file(path: Path = DEFAULT_ENV_PATH) -> dict[str, str]:
    if not path.exists():
        raise SlackMcpError(f"Missing env file: {path}")

    values: dict[str, str] = {}
    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip("'").strip('"')
    return values


def load_app_config(path: Path = DEFAULT_ENV_PATH) -> SlackAppConfig:
    values = load_env_file(path)
    client_id = values.get("SLACK_CLIENT_ID", "").strip()
    client_secret = values.get("SLACK_CLIENT_SECRET", "").strip()
    if not client_id:
        raise SlackMcpError(f"Expected SLACK_CLIENT_ID in {path}")
    redirect_host = values.get("SLACK_REDIRECT_HOST", DEFAULT_REDIRECT_HOST).strip()
    redirect_port = int(values.get("SLACK_REDIRECT_PORT", DEFAULT_REDIRECT_PORT))
    return SlackAppConfig(
        client_id=client_id,
        client_secret=client_secret,
        redirect_host=redirect_host,
        redirect_port=redirect_port,
    )


def ensure_private_dir(path: Path) -> None:
    path.mkdir(parents=True, exist_ok=True)
    os.chmod(path, 0o700)


def write_private_json(path: Path, payload: dict) -> None:
    ensure_private_dir(path.parent)
    path.write_text(json.dumps(payload, indent=2, sort_keys=True), encoding="utf-8")
    os.chmod(path, 0o600)


def load_token(path: Path = TOKEN_PATH) -> dict:
    if not path.exists():
        raise SlackMcpError(
            f"Slack token missing at {path}. Run slack_mcp_auth.py first."
        )
    return json.loads(path.read_text(encoding="utf-8"))


def save_token(payload: dict, path: Path = TOKEN_PATH) -> None:
    write_private_json(path, payload)


def generate_state() -> str:
    return secrets.token_urlsafe(32)


def generate_code_verifier() -> str:
    return secrets.token_urlsafe(64)


def build_code_challenge(code_verifier: str) -> str:
    digest = hashlib.sha256(code_verifier.encode("utf-8")).digest()
    return base64.urlsafe_b64encode(digest).decode("utf-8").rstrip("=")


def build_authorize_url(
    config: SlackAppConfig,
    scopes: list[str] | None = None,
    state: str | None = None,
    code_challenge: str | None = None,
) -> str:
    params = {
        "client_id": config.client_id,
        "scope": ",".join(scopes or USER_TOKEN_SCOPES),
        "redirect_uri": config.redirect_uri,
        "state": state or generate_state(),
    }
    if code_challenge:
        params["code_challenge"] = code_challenge
        params["code_challenge_method"] = "S256"
    return f"{AUTHORIZE_URL}?{urllib.parse.urlencode(params)}"


def exchange_code_for_token(
    config: SlackAppConfig,
    code: str,
    code_verifier: str | None = None,
) -> dict:
    fields = {
        "code": code,
        "client_id": config.client_id,
        "redirect_uri": config.redirect_uri,
    }
    if code_verifier:
        fields["code_verifier"] = code_verifier
    elif config.client_secret:
        fields["client_secret"] = config.client_secret
    payload = urllib.parse.urlencode(fields).encode("utf-8")
    request = urllib.request.Request(
        TOKEN_URL,
        data=payload,
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        method="POST",
    )
    return _json_request(request)


def slack_api_get(token: str, method: str, params: dict | None = None) -> dict:
    query = urllib.parse.urlencode(params or {})
    url = f"https://slack.com/api/{method}"
    if query:
        url = f"{url}?{query}"
    request = urllib.request.Request(
        url,
        headers={"Authorization": f"Bearer {token}"},
        method="GET",
    )
    return _json_request(request)


def slack_api_post(token: str, method: str, payload: dict | None = None) -> dict:
    request = urllib.request.Request(
        f"https://slack.com/api/{method}",
        data=json.dumps(payload or {}).encode("utf-8"),
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json; charset=utf-8",
        },
        method="POST",
    )
    return _json_request(request)


def _json_request(request: urllib.request.Request) -> dict:
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            payload = response.read().decode("utf-8")
    except urllib.error.HTTPError as exc:
        payload = exc.read().decode("utf-8", errors="replace")
        raise SlackMcpError(
            f"Slack HTTP error {exc.code}: {payload or exc.reason}"
        ) from exc
    except urllib.error.URLError as exc:
        raise SlackMcpError(f"Slack request failed: {exc.reason}") from exc

    data = json.loads(payload)
    if not data.get("ok", False):
        error = data.get("error", "unknown_error")
        raise SlackMcpError(f"Slack API error: {error}")
    return data


def build_token_payload(token_response: dict, auth_info: dict) -> dict:
    access_token = token_response.get("access_token")
    if not access_token:
        raise SlackMcpError("Slack OAuth response did not contain an access token.")

    expires_in = token_response.get("expires_in")
    expires_at = None
    if expires_in:
        expires_at = int(time.time()) + int(expires_in) - 60

    return {
        "access_token": access_token,
        "refresh_token": token_response.get("refresh_token"),
        "scope": token_response.get("scope", ""),
        "team": token_response.get("team"),
        "authed_user": token_response.get("authed_user"),
        "auth_test": auth_info,
        "expires_at": expires_at,
    }


def token_is_expired(token_data: dict) -> bool:
    expires_at = token_data.get("expires_at")
    return bool(expires_at and int(time.time()) >= int(expires_at))


def refresh_token(config: SlackAppConfig, current_token: dict) -> dict:
    refresh_value = current_token.get("refresh_token")
    if not refresh_value:
        raise SlackMcpError("Slack token expired and no refresh token is available.")

    fields = {
        "grant_type": "refresh_token",
        "refresh_token": refresh_value,
        "client_id": config.client_id,
    }
    if config.client_secret:
        fields["client_secret"] = config.client_secret
    request = urllib.request.Request(
        TOKEN_URL,
        data=urllib.parse.urlencode(fields).encode("utf-8"),
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        method="POST",
    )
    response = _json_request(request)
    auth_info = slack_api_get(response["access_token"], "auth.test")
    return build_token_payload(response, auth_info)
