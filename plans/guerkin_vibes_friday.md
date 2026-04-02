# Color Sync — Discovery Plan (3 Amigos)

## Story (Yellow Card)

When context health changes (green → yellow → red), the prompt bar color automatically syncs with the status line — no manual `/color` needed.

## Rules (Blue Cards)

1. **Status line is source of truth** — already knows context health thresholds
2. **JSONL is the sync channel** — write `agent-color` entries to `~/.claude/projects/{sessionId}.jsonl`
3. **Auto-restart syncs the prompt bar** — hook calls `restart.sh $PPID`, CC resumes with `--resume`
4. **Only restart on threshold change** — green→yellow, yellow→red. Not within a band.
5. **Hook runs when idle** — no mid-generation risk
6. **No CC changes** — uses existing CC metadata infrastructure

## The Mechanism

1. Status line hook receives `session_id` and `transcript_path` via JSON stdin
2. Dude detects context threshold crossed (green/yellow/red)
3. Appends `{"type":"agent-color","sessionId":"<id>","agentColor":"<color>"}` to transcript JSONL
4. Calls `~/.claude/skills/restart/restart.sh $PPID`
5. CC dies, relaunches with `--resume`
6. CC reads transcript → parses agent-color → populates AppState
7. Prompt bar renders with new color — matches status line

## Where the Logic Lives

**Dude's StatusLine Ruby code.** It already calculates the color. Just add JSONL write + restart call there. One place, no duplication. (Kent confirmed: Ruby is simpler.)

## Examples (Green Cards)

### 1. Automatic Sync After Response
- User sends prompt, CC responds
- Response burns context past yellow threshold
- Hook detects yellow, writes agent-color to JSONL, triggers restart
- CC resumes — prompt bar is yellow, matches status line

### 2. Multiple Thresholds
- User works through green → yellow → red
- Each threshold crossing triggers JSONL write + restart
- Between thresholds, no action — efficient
- Colors always match

### 3. Within Threshold — No Action
- Context goes from 20% to 30% (still green)
- No threshold crossed, no restart
- Nothing happens

### 4. Fresh Session Starts Green
- New session, no agent-color in JSONL
- Default color (green or none)
- Status line shows green — matches

## Questions (Red Cards) — All Resolved

- ~~Does CC re-read JSONL during session?~~ No, only on resume. Solved by restart.
- ~~Can hooks trigger restart?~~ Yes, via `restart.sh $PPID`.
- ~~Is restart safe?~~ Yes, `--resume` preserves full context.
- ~~Mid-generation risk?~~ None, hook runs when CC is idle.
- ~~How does hook know sessionId?~~ CC passes it via JSON stdin.
- ~~Can Dude write to JSONL?~~ Yes, simple file append. Same mechanism `/color` uses.

## Glossary Candidates

- **agent color** — metadata entry in session JSONL that persists prompt bar color across restarts
- **context health** — visual representation of context window usage (green/yellow/red)
- **color sync** — automatic synchronization of prompt bar with status line context health
- **metadata entry** — JSON line in session JSONL storing non-message state
- **session resume** — restoring a conversation via `--resume`, re-populating AppState from transcript

## Confirmed By

- **Kent**: Feasible. Hook can write JSONL + call restart.sh. All pieces exist.
- **Liz**: Examples cover happy path + edge cases. No unresolved unknowns. Auto-restart is seamless.
- **Dude (Claude)**: CC reads agent-color on resume. This is designed CC infrastructure, not a workaround.
