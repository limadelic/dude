# /pub skill — Issue #36 (limadelic/dude) ✅

## What got done

### /pub skill (`commands/pub.md`)
- `/pub [name]` — name defaults to cwd dirname
- Creates `{cwd}/.claude/dude/inbox.json` with `[]`
- Writes `name` into `{cwd}/.claude/dude/status.json` (merges with existing keys)
- Creates symlink `~/.claude/dudes/{name} -> {cwd}/.claude/` — always, including global sup
- Global sup pubs as "dude" — `~/.claude/dudes/dude -> ~/.claude/`

### Statusline dudes section (`statusline.rb`)
- Icon from `CLAUDE.md` frontmatter (`icon:` field)
- Superscript message count per dude (⁰-⁹, ⁹⁺)
- Context health color (green/yellow/red) from `status.json`
- `status.json` written as side effect of render
- Sup sees all pub dudes, pub dude sees only itself
- FakeFS collaborator — pure unit tests, no I/O
- Active model superscript (always ⁰-¹⁰), white text on bg

### Icons
- sup: 🎳
- rec: 🔴
- smith: 🤖

## Not done (separate stories)
- Cleanup on exit
- Inbox watching via await
