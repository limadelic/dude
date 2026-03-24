# pub-dudes plan

## What
Vibe Coding Friday presentation. 30-60 min. Show the pub/dudes system live.

## Vibe
St. Patrick's week tie-in. Pub theme. Keep it fun.

## Exercise 1: Talk to yourself

### Pre-exercise: /pub
Before anything — `/pub` cold start:
1. I say `/pub`
2. Dude registers as pub (status.json, symlink, inbox)
3. `/abide` kicks in automatically
4. Watcher starts in background
5. Statusline shows: icon, inbox at 0, watcher alive

What audience sees: dude is live, abiding, waiting for messages. No manual setup.

### What needs to work
- `/pub` → creates inbox, status, symlink, starts `/abide`
- `/abide` → starts watch.sh in bg
- Statusline → shows dude icon, inbox count, watcher health
- All of this happens from one command

### What's missing?
TBD — need to exercise it and see what breaks

### The actual exercise: talk to yourself
1. `tell dude don't talk to yourself` (from same session)
2. Watch fires → wip → todo created
3. Dude sees "Abide: don't talk to yourself"
4. Dude abides it (just acknowledges, no reply — it's a tell)
5. done.sh cleans inbox
6. Watcher restarts

### Known failure modes
- Dude gets brainy — tries to be funny instead of following the process
- Dude fails to recognize the Abide todo and follow the flow
- These are the things we'll fix by exercising

### Dependencies
- `/msg` needs to be split into `/tell` and `/ask` (simple commands)
- `/tell` = fire and forget, no reply expected
- `/ask` = reply owed
- These are simple but need to exist before the demo

## Exercise 2: Knock-knock joke

### Setup
- Open second terminal in another folder (ops or smith)
- `/pub` from that folder
- Split screen: two dudes, both pubbed, both abiding
- Statusline shows both icons, inbox zero, watchers alive
- Talking point: no orchestrator — anybody can talk to anybody, nobody leads

### The exercise
1. I tell dude: "tell ops a knock-knock joke"
2. Dude asks ops: "knock knock"
3. Ops tells dude: "who's there?"
4. Dude asks ops: the setup (something funny about ops/dudes)
5. Ops tells dude: "X who?"
6. Dude tells ops: the punchline

### What this proves
- Multi-round conversation between two dudes
- Ask/tell ping-ponging naturally — no orchestrator
- Each dude knows when to reply (ask) and when to just listen (tell)
- Escalation from exercise 1: one message → conversation

### What needs to work
- Two pubs running simultaneously
- Statusline showing both dudes
- Ask/tell working across sessions
- Abide handling multiple rounds without losing the thread
- Each dude independently abides its inbox — no shared state

### Dependencies
- `/tell` and `/ask` must exist (same as exercise 1)
- Cross-dude messaging working (symlinks, inbox resolution)

## Exercise 3: Tic-tac-toe (Big Bang style)

### What it proves beyond knock-knock
- Not just conversation — shared state via a file (scratch pad / plan)
- Two dudes reading and writing to the same game state
- Multi-turn structured interaction, not just chat
- Will the dudes actually play valid moves? (historically agents suck at this)

### The exercise
- Same two-terminal setup as exercise 2
- I tell dude to play tic-tac-toe with ops
- Dudes take turns, each writing their move to a shared file
- Each dude reads the board, makes a move, tells the other

### What this opens up
- Shared scratch pad concept — dudes writing to a common file
- When we split /msg into /tell and /ask, review the message envelope JSON
- Maybe messages carry a path to a scratch pad, not just text
- Synchronization on a file between two independent sessions

### Dependencies
- Everything from exercise 2
- Scratch pad / shared file convention — where does it live? what format?
- Message envelope may need a field for scratch pad path
- Need to figure this out when designing /tell and /ask

## Exercise 4: Dominoes (stretch goal)

### Why it's cool
- Visual — ASCII dominoes on screen
- 4 players + maybe a board agent (5 dudes)
- Escalation from 2 dudes to 4-5 dudes
- UI element: someone draws/renders the board

### Not happening today
- Only if exercises 1-3 are killed in ~20 min (unlikely)
- Needs prep work: UI rendering, 4-player turn logic, board state
- Many open design questions (shared board agent? who renders?)
- Future session material