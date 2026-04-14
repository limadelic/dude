---
name: browse
description: Browse the web when Haiku subagent fails WebSearch or Fetch
---

# Browse

## How
1. Try Haiku first with WebSearch/Fetch
2. If that fails, delegate to the arana agent

## Slack
- NEVER use `/archives/` URLs — they redirect to desktop app
- Use `/messages/` path: `ukginc.enterprise.slack.com/messages/CHANNEL_ID/pTIMESTAMP`
- This redirects cleanly to `app.slack.com` in browser
