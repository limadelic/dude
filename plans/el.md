# El

*The telepathic bridge between Claude processes. Seed of Elita. El Dude abides.*

## Problem

Claude Code agent teams messaging is broken. SendMessage writes to JSON inbox files, but the polling/receiving side fails across every backend (tmux, iTerm2, in-process, VS Code). Nobody in the wild has it working reliably as a daily workflow.

## Insight

The problem is RECEIVING, not sending. Claude Code has no reliable incoming port for real-time messages. The inbox poller (`useInboxPoller.ts`) polls every 1 second and frequently drops messages.

## Discovery

Kent reviewed Claude Code source and found these injection points:

| Port | Latency | Available | Constraint |
|------|---------|-----------|------------|
| stdin NDJSON | zero | YES | Must own the process |
| Inbox JSON files | 1s poll | YES | Unreliable polling |
| UDS inbox | zero | NO | `UDS_INBOX` feature flag |
| MCP channels | zero | NO | Anthropic-gated (OAuth, org policy) |
| REPL bridge | zero | NO | GrowthBook flag, Claude.ai subscription |

**stdin is the only reliable, ungated, zero-latency port.** But you must own the Claude process to use it.

## The stdin Protocol

```json
{"type":"user","message":{"role":"user","content":"hello"},"parent_tool_use_id":null}
```

- One line of NDJSON per message
- Launch with: `claude -p --input-format=stream-json --output-format=stream-json`
- Mid-conversation injection works — stdin is never paused
- Control subtypes: `interrupt`, `initialize`, `set_permission_mode`
- Structured NDJSON responses on stdout

## Solution: Claude Phone

An Elixir app that spawns and manages multiple Claude processes, routing messages between them via stdin/stdout.

### Architecture

- Each Claude process is wrapped in a GenServer via `Port.open`
- Messages route through a central router GenServer
- Supervision tree manages lifecycle — crash = restart
- No JSON files, no polling, no broken inbox

### Elixir Side

```
Port.open({:spawn, "claude -p --input-format=stream-json --output-format=stream-json"}, [:binary, :stream, {:line, 65536}])
```

GenServer wrapping a Port — the most classic Erlang pattern.

### Three Dynamics It Unifies

1. **Pub** — separate terminals, separate directories. Currently file-based messaging between Claude sessions. Could become Phone-managed processes.
2. **Sub** — nested. A Claude inside another Claude's project. Could become a child process in the supervision tree.
3. **Phone** — spawn Claude from Elixir, own stdin pipe, route messages. The new dynamic.

## What This Is NOT

- NOT Elita — Elita is the full agentic platform (agents as md files → GenServers)
- NOT a patch on Claude Code teams — we're replacing teams entirely
- NOT an MCP server — we own the process, not a plugin

## What This IS

- A reliable phone system for multiple Claude processes
- An Elixir app that wraps Claude CLI via Ports
- A bridge that makes multi-agent workflows work TODAY
- A stepping stone — patterns learned here feed into Elita later

## Open Questions

- Name: "plug" conflicts with Elixir's Plug library. Claude Phone? Switchboard? PBX?
- How does the user interact? Do they talk to one Claude that routes, or do they talk to Phone directly?
- How does this integrate with the existing dude gem and skills?
- Does `claude -p` (print mode) support everything interactive mode does? Tools, edits, etc.?
- How do agents discover each other? Registry in Phone?

## Research Sources

- Kent's source review: `~/.claude/plans/kent-inbox.md`
- Arana's web research: `~/.claude/plans/arana-inbox.md`
- Key files in CC source:
  - `tools/SendMessageTool/SendMessageTool.ts`
  - `utils/teammateMailbox.ts`
  - `hooks/useInboxPoller.ts`
  - `utils/messageQueueManager.ts`
  - `services/mcp/channelNotification.ts`

## Prior Art

- OpenAI Symphony — 96.1% Elixir agent orchestration
- `claude_code` Elixir SDK on Hex — sessions as GenServers
- Sagents — Elixir agents with OTP supervision + LiveView
- Synapse — declarative multi-agent framework with signal bus
- GNAP — git-native agent protocol, 4 JSON files

## Status

Discovery phase. We know the port (stdin), we know the pattern (GenServer wrapping Port), we know the runtime (BEAM). Next step: POC.
