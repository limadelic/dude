# Color Sync — Discovery Plan (3 Amigos)

## Story (Yellow Card)

When the context bar changes color (green → yellow → red), automatically sync that color to Claude Code's prompt bar by writing to the session JSONL and restarting.

## Rules (Blue Cards)

1. **Status line is source of truth** — already knows context health thresholds
2. **JSONL is the sync channel** — write `agent-color` entries to transcript JSONL
3. **Write on transition only** — green→yellow, yellow→red. Not within a band, not on every render.
4. **Restart after write** — hook calls `restart.sh`, CC resumes with `--resume`
5. **No restart on startup** — first render writes current color to JSONL but does NOT restart
6. **Always-on** — baked into `write_status()`, no toggle, no config
7. **Last write wins** — user `/color blue` overrides auto-sync; auto-sync overrides on next transition
8. **Previous color tracked in status.json** — detect transitions, avoid spurious writes/restarts
9. **Hook runs when idle** — no mid-generation risk
10. **No CC changes** — uses existing CC metadata infrastructure

## The Mechanism

1. Status line hook receives `session_id` and `transcript_path` via JSON stdin
2. Dude detects context threshold crossed (green/yellow/red)
3. Appends `{"type":"agent-color","sessionId":"<id>","agentColor":"<color>"}` to transcript JSONL
4. Calls `~/.claude/skills/restart/restart.sh $PPID`
5. CC dies, relaunches with `--resume`
6. CC reads transcript → parses agent-color → populates AppState
7. Prompt bar renders with new color — matches status line

## Where the Logic Lives

`lib/dude/status_line/dudes.rb` — `write_status()` method (line 24-31)

### Data available

- `session['session_id']` — UUID from stdin JSON
- `session['transcript_path']` — full JSONL path from stdin JSON
- `color_name_for_percentage(@context_percentage)` — current color name

### Logic

```
current_color = color_name_for_percentage(@context_percentage)
previous_color = status['color']  # from status.json

if current_color != previous_color
  append agent-color entry to transcript_path
  if previous_color is not nil  # not first render
    shell out to restart.sh
  end
end
```

### Files touched

- `lib/dude/status_line/dudes.rb` — add JSONL write + restart logic to `write_status()`

## Examples (Green Cards)

### E0: No color — bootstrap
- WHEN no previous color exists in status.json (first ever render)
- THEN gem detects no color has been set
- AND writes `{"type":"agent-color","agentColor":"green","sessionId":"<uuid>"}` to transcript_path
- BUT does NOT restart (nothing to resume from)

### E1: Normal climb green → yellow
- WHEN context is at 20% (green) and climbs to 35% (yellow)
- THEN gem writes `{"type":"agent-color","agentColor":"yellow","sessionId":"<uuid>"}` to transcript_path
- AND triggers restart.sh
- AND user sees yellow prompt bar after restart (~1 sec)

### E2: Normal climb yellow → red
- WHEN context is at 60% (yellow) and climbs to 70% (red)
- THEN gem writes `{"type":"agent-color","agentColor":"red","sessionId":"<uuid>"}`
- AND triggers restart.sh

### E3: Startup at yellow (no previous)
- WHEN session opens at 45% context (yellow) and no previous color in status.json
- THEN gem writes `{"type":"agent-color","agentColor":"yellow","sessionId":"<uuid>"}`
- BUT does NOT restart (first render)

### E4: Same color, no action
- WHEN context is at 40% (yellow) and was already yellow last render
- THEN gem does nothing (no write, no restart)

### E5: User overrides with /color
- WHEN auto-sync wrote red, then user runs `/color blue`
- THEN blue is the last entry in JSONL — blue wins on next restart
- AND auto-sync will overwrite blue on next transition (acceptable)

### E6: Threshold bounce
- WHEN context oscillates 32% → 33% → 32% rapidly
- THEN gem writes yellow on first 33%, restarts once
- AND on return to 32%, writes green, restarts once
- NOTE: This is rare and 2 restarts is acceptable

### E7: Within threshold — no action
- WHEN context goes from 20% to 30% (still green)
- THEN no threshold crossed, no restart, nothing happens

## Questions (Red Cards)

- ~~Does CC re-read JSONL during session?~~ No, only on resume. Solved by restart.
- ~~Can hooks trigger restart?~~ Yes, via `restart.sh $PPID`.
- ~~Is restart safe?~~ Yes, `--resume` preserves full context.
- ~~Mid-generation risk?~~ None, hook runs when CC is idle.
- ~~How does hook know sessionId?~~ CC passes it via JSON stdin.
- ~~Can Dude write to JSONL?~~ Yes, simple file append. Same mechanism `/color` uses.
- ~~Conflict with manual /color?~~ Last write wins. No priority field. No conflict.

## Glossary

- **color sync** — feature that auto-syncs context bar color to Claude Code prompt bar
- **context bar** — the 🧠 with 9 blocks showing context window utilization
- **context bar color** — green (0-33%), yellow (33-66%), red (66-100%) — auto-assigned
- **agent color** — CC's color system for the prompt bar (8 named colors)
- **transcript path** — the session JSONL file where agent-color entries are stored
- **session resume** — restoring a conversation via `--resume`, re-populating AppState from transcript
