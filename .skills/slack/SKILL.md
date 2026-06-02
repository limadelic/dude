---
name: slack
description: Use when browsing Slack channels or threads via arana
---

# Slack

## What
Browse Slack in Chrome via arana without desktop app redirect.

## How
1. Convert URL: replace `/archives/` with `/messages/`, use `ukginc.enterprise.slack.com`
2. Delegate to arana agent with the converted URL
3. Arana takes snapshot, saves to `/tmp/snapshot.md`, returns summary

## Refs
- Channel: `ukginc.enterprise.slack.com/messages/CHANNEL_ID`
- Thread: `ukginc.enterprise.slack.com/messages/CHANNEL_ID/pTIMESTAMP`
