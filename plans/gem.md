# Dude Gem — Statusline SRP Refactor

Extract one section at a time. Each step: extract → tests pass → commit.

## Order (least dependencies first)

1. **Format** — extract colors, bar, emoji_group, superscripts, clamp, color_for_pct
   - No deps on anything else, everything depends on it
   - Tests: existing bar/color tests still pass

2. **Brain** — extract context_percentage + brain_section
   - Depends on: Format
   - ~10 lines, simplest section

3. **Spend** — extract spend_pct + spend_section + activity_data fetching
   - Depends on: Format
   - ~15 lines

4. **Pomodoro** — extract pomo reading + pomo_section
   - Depends on: Format, FS
   - ~20 lines

5. **Models** — extract model stats + models_section
   - Depends on: Format, activity_data
   - ~30 lines, normalize_to_100 moves here

6. **Dudes** — extract load_dudes, dude_display, abide health, write_status
   - Depends on: Format, FS
   - ~100 lines, biggest chunk, last for a reason

## Rules

- All 62 tests pass after each step
- No new test files yet — keep existing test working against Statusline
- Once all extracted, refactor tests to test sections directly