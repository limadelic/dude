# /abide plan (issue #39)

## Goal
Make watch.sh self-sufficient. Less LLM, more shell. Watch is a pure bg loop that detects, marks wip, creates the todo, and keeps watching — all by itself. The dude never looks at watch output.

## Principle
Every decision that can be encoded in shell, MUST be. LLM only does reasoning (abide). Shell does plumbing (watch, wip, done, paths, envelopes).

## Flow

### WATCH (shell, bg, loops forever)
- resolve inbox path itself (don't rely on LLM passing correct path)
- wait-until new message at top of inbox
- mark it wip (jq)
- create a todo in the session ← **unsolved: how?**
- restart watch (loop)

### ABIDE (dude, via task system)
- todo appears → dude abides it
- "Abide: ..." → told, no reply needed
- "Abide {name}: ..." → asked, reply owed

### DONE (shell)
- reply via done.sh if asked
- remove wip from inbox
- mark todo complete

## SOLVED: how does watch.sh create a todo in the session?
Write JSON to `~/.claude/tasks/{sessionId}/{id}.json` — Claude picks it up via TaskList.
Session ID from `~/.claude/sessions/$PPID.json`. Verified working.

## Parked: done.sh reply envelope
- Currently missing "from" in reply
- Parked until /msg gets redesigned → split into /ask and /tell
- That redesign will determine how done.sh builds replies

## Parked: SKILL.md todo.sh step
- Currently LLM runs todo.sh and does TaskCreate itself
- Becomes redundant if watch.sh can create todos directly
- Depends on solving the unsolved blocker above

## Parked: orphan wip recovery
- If abide crashes, wip message sits with no todo
- watch.sh should detect orphaned wip on startup and re-create the todo
- Depends on solving the "todo from shell" blocker
- Encode in shell, not LLM

## Parked: /msg redesign
- Split /msg into /ask and /tell
- Affects done.sh reply logic and envelope format
- Will revisit when we get to it

## Path resolution
- watch.sh finds inbox itself — no LLM path passing
- Convention: every dude runs inside .claude/ dir
- sup: ~/.claude/, pub dudes: ~/dev/X/.claude/
- Shell resolves, not LLM

## Entry point
`/pub` calls `/abide` once to start watch.

## Reply strategy
- Short → `/msg {from} here's the answer`
- Long → write to `plans/`, reply with path
- /msg itself is due for redesign → split into /ask and /tell

## Bugs — fix one at a time

1. [x] inbox.json is 1 byte (not `[]`) — fixed
2. [x] session ID via $PPID — verified, works fine
3. [x] jq command quoting — verified, works fine
4. [x] writing task JSON to disk — verified, it surfaces in TaskList

## Test
1. `/pub` → starts WATCH in bg
2. From another dude: `/msg dude something`
3. Watch detects → marks wip → todo appears in session
4. Dude abides → done.sh → inbox clean → watch keeps going
5. No LLM involved in watch/wip/done — only in abide (reasoning)