# Dude Channels — Local Dude-to-Dude Messaging via Claude Channels

## Status: BLOCKED — API key auth not supported

Channels require claude.ai Pro/Max subscription auth. `ANTHROPIC_API_KEY` takes precedence
and disables channels entirely. Output: `Channels are not currently available`.

Viable on personal machine with Pro/Max login. Not viable on work setup with API billing.

## What We Learned

### Auth hierarchy (channels won't activate unless top-level auth is subscription)
1. Cloud provider creds (Bedrock/Vertex/Foundry)
2. `ANTHROPIC_API_KEY` env var — **blocks channels**
3. claude.ai subscription (OAuth) — **channels work here**

### The POC works (code deleted, but for reference)
- MCP server with `claude/channel` capability + stdio transport + HTTP listener — works
- `notifications/claude/channel` fires over stdio correctly (verified)
- `--dangerously-load-development-channels server:name` is the dev flag (not in `--help`)
- Server name must match key in `.mcp.json`
- `console.error` before `mcp.connect()` can break the stdio handshake
- Zombie node processes on the port crash the MCP spawn — handle EADDRINUSE
- `--dangerously-load-development-channels` hides MCP tools (channel-only mode)
- Without the flag, MCP tools work but channel notifications are silently dropped

### Flag syntax
```bash
# dev/custom channels (bypasses allowlist)
claude --dangerously-load-development-channels server:mcp-name

# approved plugins
claude --channels plugin:name@marketplace
```

### Reference implementations
- `anthropics/claude-plugins-official` repo has fakechat, telegram, discord, imessage
- fakechat is the minimal reference — same pattern we used
- All use: Server constructor, StdioServerTransport, notifications/claude/channel
- All are plugins, not bare MCP servers (but `server:` mode works too)

### yolo_channel function
- Lives in `yolo.sh` — separate from regular `yolo`
- Needs `ANTHROPIC_API_KEY=` (unset) to fall through to subscription auth
- No `--dangerously-skip-permissions` (channels need interactive confirmation)

## To Resume (personal machine, Pro/Max auth)

1. Recreate `poc/dude-channel/dude-channel.ts` (see git history)
2. `source ~/.zshrc && yolo_channel`
3. Should see channel confirmation prompt
4. Test with `curl -X POST localhost:9100/msg -d '{"from":"test","text":"hello"}'`
5. Should see `<channel source="dude-channel" from="test">hello</channel>` in session
