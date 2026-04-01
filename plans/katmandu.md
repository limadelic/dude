# Katmandu — The Middle Loop

Task-level. Kenny codes, Cartman reviews, Dude decides.

## When to Use

- Making scenarios pass (called from DDD step 6)
- Quick fixes ("just fix this")
- Any coding task that doesn't need the full DDD ceremony

## The Flow

1. Dude describes the BEHAVIOR change to Kenny — not the implementation
2. Kenny TCRs until he has a commit (inner loop)
3. Cartman reviews Kenny's commit — adversarial, checks code rules
4. Dude evaluates Cartman's feedback:
   - Real violations → send Kenny back (another TCR cycle)
   - Nitpicking → work is done
5. Commit after each task exits the loop

## What We Learned

- Kenny works best with ONE small task per invocation. Big tasks fail.
- Never dictate code, paths, or commands to Kenny — he knows. Describe behavior.
- Cartman is useful but noisy. Most of his complaints are valid style points but not blockers. Dude needs judgment to know when to push back vs accept.
- Three parallel Kennys work IF they touch different files. Same file = collision risk.
- Bob is NOT part of Katmandu. Bob runs commands. Bob doesn't code. Bob got caught refactoring when told to push — had to lock him down (disallowedTools: Edit, Write).
- When Kenny fails, don't send the same prompt. Ralph him — revert, fresh context, better instructions.

## Status

Skill at `.claude/skills/katmandu/SKILL.md`. No changes needed — works as designed.
