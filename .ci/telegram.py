#!/usr/bin/env python3
"""Announce a release in a Telegram channel, installers attached.

The files are uploaded through the self-hosted Bot API server started by
`.github/workflows/publish-release.yaml`, so they are not subject to the 50 MB
upload limit of Telegram's cloud Bot API. The bot must be an administrator of
the target channel.
"""

import html
import json
import os
import sys

import requests

DIST_DIR = os.environ.get("DIST_DIR", "dist")
TOKEN = os.environ["TELEGRAM_BOT_TOKEN"]
CHAT_ID = os.environ["TELEGRAM_CHAT_ID"]
TAG = os.environ["TAG"]
VERSION = os.environ.get("VERSION", "")
CHANNEL = os.environ.get("CHANNEL", "")
RELEASE_URL = os.environ["RELEASE_URL"]

API_URL = f"http://localhost:8081/bot{TOKEN}/sendMediaGroup"

# One installer per platform, in the order users are most likely to want them.
# Kept well under Telegram's ten item limit for a media group.
KEYWORDS = [
    "android-arm64-v8a",
    "windows-amd64-setup",
    "macos-arm64",
    "macos-amd64",
    "linux-amd64.AppImage",
]


def attachments():
    names = sorted(os.listdir(DIST_DIR))
    for index, keyword in enumerate(KEYWORDS, start=1):
        for name in names:
            path = os.path.join(DIST_DIR, name)
            if os.path.isfile(path) and keyword in name:
                yield f"file{index}", path
                break


media = []
handles = {}
for key, path in attachments():
    media.append({"type": "document", "media": f"attach://{key}"})
    handles[key] = open(path, "rb")

if not media:
    print("nothing to announce: no installer matched in " + DIST_DIR, file=sys.stderr)
    sys.exit(0)

caption = f"<b>FlClash {html.escape(VERSION)} · {html.escape(CHANNEL)}</b>\n"
caption += f"{html.escape(TAG)}\n"
caption += f'<a href="{html.escape(RELEASE_URL)}">GitHub Release</a>'
media[-1]["caption"] = caption
# HTML, not Markdown: the caption is assembled from user visible values and HTML
# is the parse mode with a defined escape for them.
media[-1]["parse_mode"] = "HTML"

try:
    response = requests.post(
        API_URL,
        data={"chat_id": CHAT_ID, "media": json.dumps(media)},
        files=handles,
        timeout=600,
    )
finally:
    for handle in handles.values():
        handle.close()

try:
    payload = response.json()
except ValueError:
    payload = None

print("Response JSON:", payload if payload is not None else response.text)

# A rejected caption comes back as a 400 with a description, not an exception.
if not response.ok or not (payload or {}).get("ok"):
    description = (payload or {}).get("description", response.text)
    print(f"Telegram rejected the release post: {description}", file=sys.stderr)
    sys.exit(1)
