# El Log — Crash Reason Visibility

> I've been failing at this for a whole week.
> Do NOT claim done until the human confirms it works.

## GOAL

When a session crashes, `el lisa log` shows the crash reason. Period.

## THE OTP WAY

OTP already solves this. Supervisors automatically generate crash reports when children die. Logger writes them to disk. That's it. No custom crash-catching code needed.

### What OTP gives us for free

1. **Supervisor crash reports** — when a supervised GenServer dies, OTP automatically logs: process name, exit reason, stack trace, ancestors
2. **Logger file handler** — built-in, supports rotation, survives VM restarts
3. **SASL reports** — supervisor-level reports with full crash context

### What we need to do

1. Configure Logger to write to a file (not just console)
2. Enable SASL reports in Logger
3. Make `el name log` read from that log file, filtered by session name
4. That's it. Stop inventing.

## CONFIG

```elixir
# config/config.exs or config/runtime.exs
config :logger,
  handle_sasl_reports: true,
  handle_otp_reports: true

config :logger, :default_handler,
  config: [
    file: ~c"#{System.get_env("HOME")}/.el/log/el.log",
    max_no_bytes: 10_485_760,
    max_no_files: 5
  ]
```

## `el name log` COMMAND

Read `~/.el/log/el.log`, filter lines containing the session name, display them. The crash reason is already there because OTP put it there.

## WHAT NOT TO DO

- Do NOT write custom crash-catching code in Session GenServer
- Do NOT store crash reasons in ETS or dets
- Do NOT create per-session log files
- Do NOT intercept EXIT signals to log them manually
- Let OTP do what OTP does

## STATUS

NOT STARTED. Understanding phase.
