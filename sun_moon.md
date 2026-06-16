# Sun/Moon — Enterprise Spend Test Runbook

You are a haiku agent on the CORPORATE (enterprise) machine. Goal: prove the
status line shows ☀️ daily-spend and 🌙 monthly-spend burn bars on this box.

Run each step. Do NOT skip. Report the EXACT output of every command back to the
human. If a step fails, STOP and report — do not improvise.

## Background (read once)

- Pro accounts: payload has `rate_limits` → ☀️/🌙 are RATE-LIMIT bars.
- Enterprise accounts: payload has NO `rate_limits` → ☀️/🌙 become SPEND bars:
  - ☀️ daily spend vs today's locked budget
  - 🌙 monthly spend vs $175/month
- Spend comes from the Anthropic usage API; needs a token from
  `~/.claude/.credentials.json` or the macOS keychain.

## Steps

### 1. Get the code

```
cd ~/dude && git fetch origin && git checkout wip && git pull origin wip
```

### 2. Build + install the gem

```
cd ~/dude/code && gem build dude.gemspec && gem install ./dude-0.1.1.gem --local
```

### 3. Find the installed binary

```
gem contents dude | grep '/bin/dude$'
```

Save that full path — call it `DUDE_BIN` below.

### 4. Run the full test suite (must be 0 failures)

```
cd ~/dude/code && bundle exec rspec spec/ 2>&1 | tail -3
```

Expect: `... examples, 0 failures`. If any red, STOP and report.

### 5. Enterprise smoke test (NO rate_limits → spend bars)

```
echo '{"model":{"id":"claude-opus-4-8"}}' | $DUDE_BIN status_line
```

Expect a line containing 🧠 then ☀️ then 🌙 (a model emoji may follow).
Report the EXACT raw output. ☀️ AND 🌙 MUST both be present.

### 6. Confirm it's reading the real token / real spend

```
cat ~/.claude/.credentials.json 2>/dev/null | head -c 60; echo
cat ~/.claude/status.json 2>/dev/null; echo
```

After step 5, `~/.claude/status.json` should contain `month_spend_at_day_start`
and `days_left` for today. Report what's there.

### 7. Pro sanity check (WITH rate_limits → should stay rate bars, not spend)

```
echo '{"model":{"id":"claude-opus-4-8"},"rate_limits":{"five_hour":{"used_percentage":10,"resets_at":0},"seven_day":{"used_percentage":5,"resets_at":0}}}' | $DUDE_BIN status_line
```

Expect 🧠 ☀️ 🌙 — this confirms the Pro path still renders (different data
source, same emojis). Report exact output.

### 8. Wire the live status line (only if human confirms)

The real status line is configured in `~/.claude/settings.json` under
`statusLine.command`. It must point at the FULL path from step 3:

```
"command": "<DUDE_BIN> status_line"
```

Show the human the current value first; change it ONLY if they say so.

## Report back

- Step 4: examples / failures count
- Step 5: exact output string + "☀️ present? 🌙 present?"
- Step 6: contents of status.json (the lock fields)
- Step 7: exact output string
- Any errors, verbatim

## Troubleshooting

- No ☀️/🌙 at all in step 5 → token fetch failed. Check step 6: is there a
  credentials.json or keychain entry? Without a token, spend can't be fetched
  and the bars are correctly hidden (graceful). Report that.
- ☀️ missing but 🌙 present → daily lock not set. Check `status.json` has
  `month_spend_at_day_start` and `days_left`. Report the file contents.
- Gem won't install (permissions) → report the exact error; do NOT sudo.
