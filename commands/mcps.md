---
description: Toggle MCP servers on/off in current project
argument-hint: <on|off>
---

# MCP Toggle

Master config: ~/.claude/.mcp.all.json

## on

Copy master config to current project root:

```bash
cp ~/.claude/.mcp.all.json .mcp.json
```

Then restart.

## off

```bash
mv .mcp.json /tmp/
```

Then restart.
