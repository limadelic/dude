# Port

## What

Copy a dom to another node, the node never names itself or another node.

## How

- Port a silo the way it runs on the source node (home, cwd, launch). An order from the human (model, flags, method) beats the source. Use the plugin method only for a silo that runs as a plugin there, or on the human's order.
- The node layer holds its own keep list and launch details. Read it before a port.
- Core has no node names, no ssh, no user paths, no hard ports, no `claude -p` or `codex exec` shot lines, node facts come from env vars or `${CLAUDE_PLUGIN_ROOT}`
- `<node>.<x>` becomes `<x>`, a plain silo in its dom
- No CLAUDE.md in a plugin, the identity goes in the agent file
- Clean job first: grep the node names on the node, cut (git is the backup)
- Binding next: put PATH and env in settings, creds in `~/.zshenv`, add the dom link, one shot minion checks `command -v` of each tool and `pwd`
- One silo at a time, smallest first:
  - Port the files, validate with grep 0 for node names and `plugin.json` parses
  - One-shot test: `claude -p --plugin-dir <plugin> --agent <x> --permission-mode bypassPermissions`, the answer names itself
  - Commit, push the branch, never main, never force
  - Marketplace update and install on the node
  - Before a launch, the cwd's CLAUDE.md and .claude/CLAUDE.md must not name or import a silo identity. A silo loads its identity only from its home by --add-dir.
  - Launch live from the dom label: `claude --bg --agent <x> --permission-mode bypassPermissions --name <x> --model <model> "<first prompt>"`
  - Set `state.json` `cwd` to the label per [move.md](move.md)
- Pass: a minion re-checks the whole dom, one live row per silo, flags, settings, repo in sync, grep 0
- Trap: a symlinked dom label leaves `sessions/<pid>.json` on the realpath, check the label per [move.md](move.md)
