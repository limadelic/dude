---
description: Abide the FIRST inbox message
---

# GOAL

Follow Actor model process only 1 msg at a time.    
Watch: keeps a bg task detecting if FIRST msg is ready for Abide.  
Abide: Process one msg at a time.  

# WATCH

- Run `~/.claude/skills/await/wait-until.sh "jq -e 'length > 0 and .[0].status == \"new\"' {cwd}/.claude/dudes/inbox.json" 5` in background (run_in_background: true). When it fires, run `/abide`.

# ABIDE

- Pick the first message it must be in new otherwise keep watching
- Create a todo capturing the essence of the message
- Set `status: "wip"` on that message to ensure process 1 at a time
- Start watching again so you can Abide the new msg
