# TCR Multi-Language

## Yellow (Story)

TCR (Test && Commit || Revert) works for unit tests across Ruby, Elixir, .NET, and Node by auto-detecting the project's stack from file extensions and project conventions. Each TCR cycle runs the test suite for the detected stack, then either commits green code or reverts red code to the last known good state.

## Blue (Rules)

### Whitelist (file extension → stack)

| Extension     | Stack   |
|---------------|---------|
| `.rb`         | Ruby    |
| `.ex`, `.exs` | Elixir  |
| `.cs`         | .NET    |
| `.ts`, `.js`  | Node.js |

All files in a TCR cycle must resolve to the same stack. Mixed extensions are rejected. Unknown extensions are rejected.

### Stack Markers (validation at git root)

| Stack   | Marker      |
|---------|-------------|
| Ruby    | `Gemfile`   |
| Elixir  | `mix.exs`   |
| .NET    | `*.csproj`  |
| Node.js | `package.json` |

Markers are looked up by walking up from `Dir.pwd` toward the git root. The first matching marker wins (monorepo safety). The marker must exist for the file-detected stack, otherwise an `unknown-stack` error is raised.

Detection is two-phase:
1. **File-detected stack:** Extension whitelist determines candidate stack
2. **Marker confirmation:** Walk-up from cwd finds the marker

If phase 1 and phase 2 disagree (e.g., `.ex` file but no `mix.exs` reachable), the error describes both the detected stack and the missing marker.

### Validation Order (Kent K2)

`StackDetector.detect(files)` validates in this order, batching errors per phase:

1. File exists (else `file not found`)
2. Extension is in whitelist (else `unknown-stack: <ext> not allowed`)
3. All extensions agree (else `mixed: <file> (<ext>) + <file> (<ext>)`)
4. Marker exists for the detected stack (else `unknown-stack: <ext> file detected, but no <marker> found`)

### Stack Commands (defaults)

| Stack   | Test Command         |
|---------|----------------------|
| Ruby    | `bundle exec rspec`  |
| Elixir  | `mix test`           |
| .NET    | `dotnet test`        |
| Node.js | `npm test`           |

### Settings Override

User overrides at `~/.claude/settings.json` under `dude.tcr.test`. Project-local overrides at `<git-root>/.claude/settings.local.json` with the same shape. The whole `dude.tcr` namespace is merged across the two scopes; project-local wins on key conflict.

```json
{
  "dude": {
    "tcr": {
      "test": "mix credo --all && mix test"
    }
  }
}
```

**Precedence (highest to lowest):**
1. Project-local `<git-root>/.claude/settings.local.json` → `dude.tcr.test` (if present and non-empty)
2. User global `~/.claude/settings.json` → `dude.tcr.test` (if present and non-empty)
3. Stack default (e.g., `bundle exec rspec` for Ruby)

**Empty string behavior:**
- Key present with value `""` (empty string) → run no test command, auto-commit on completion (nothing failed = green)
- Key absent → use stack default
- Empty string is an explicit user choice to skip the test gate for this repo; no fallback to default

### Files Always Required

`StackDetector.detect(files)` requires non-empty files array. There is no file-less inference. No hierarchy fallback.

### Git Root

Walk up from `Dir.pwd` by checking for `.git/` directory at each level, following the pattern established in `PubFinder.walk_up_from`. Stop at the first `.git/` found. That directory is the git root.

## Green (Examples)

### Happy Paths

| Files                   | pwd                  | Marker at git root | Stack   | Command              |
|-------------------------|----------------------|--------------------|---------|----------------------|
| `spec/foo_spec.rb`      | `~/dude/code`        | `Gemfile`          | Ruby    | `bundle exec rspec`  |
| `test/foo_test.exs`     | `~/dev/self/el`      | `mix.exs`          | Elixir  | `mix test`           |
| `Foo.Tests.cs`          | `~/work/proj`        | `Foo.csproj`       | .NET    | `dotnet test`        |
| `src/foo.test.ts`       | `~/work/proj`        | `package.json`     | Node.js | `npm test`           |

### Override Present

| Setup                                          | Result                         |
|------------------------------------------------|--------------------------------|
| `~/.claude/settings.json` has `"mix credo --all && mix test"`, TCR in Elixir repo | Runs `mix credo --all && mix test` instead of `mix test` |
| `<git-root>/.claude/settings.local.json` has `"bin/rspec --seed=123"`, global has no override | Runs `bin/rspec --seed=123` |
| Both global and project-local exist with different values | Project-local value wins |

### Override Empty String

| Setup                                          | Result                         |
|------------------------------------------------|--------------------------------|
| `dude.tcr.test: ""` in project settings, TCR on `.exs` file | Skips test run, auto-commits |
| Global has `"mix test"`, project has `""` | Project empty string wins, skips test |

### Error Paths

**Mixed extensions:**
```
tcr spec/foo.rb test/router.exs
→ mixed: spec/foo.rb (.rb) + test/router.exs (.exs)
```

**Unknown extension:**
```
tcr spec/foo.feature
→ unknown-stack: .feature not allowed. Allowed: .rb, .ex, .exs, .cs, .ts, .js
```

**Missing marker (Elixir):**
```
tcr lib/router.ex  [in a repo with no mix.exs reachable from cwd]
→ unknown-stack: .ex file detected, but no mix.exs found in git root. Is this an Elixir project?
```

**Missing marker (Ruby) — per Dude D1:**
```
tcr spec/foo_spec.rb  [in a repo with no Gemfile reachable from cwd]
→ unknown-stack: .rb file detected, but no Gemfile found in git root. Is this a Ruby project?
```

**File not found (validation edge case):**
```
tcr nonexistent.rb
→ file not found: nonexistent.rb
```

## Red (Parked)

1. **Worktree / submodule edge cases** — .NET and Node path stability. Defer until first real consumer hits it.
2. **Test input format** — does TCR pass file paths to the test command, or does the command auto-discover? Depends on stack conventions. Treat as per-stack responsibility.
3. **Linter settings override** — "should `dude.tcr.lint` mirror `dude.tcr.test`?" Parked. Test override ships first; if Linter override is needed, reopen as follow-up story (YAGNI for now).
4. **.NET multi-project ambiguity** — if five `.csproj` files exist, which one does `dotnet test` target? Assumption: `dotnet test` from git root finds them all. Verify with first .NET consumer.
5. **Secondary stacks in mono-repos** — repo has Gemfile + package.json. Current rule: file extension drives stack, marker gates. Walk-up returns first match. Confirmed.
6. **Exit code semantics** — assumed exit code 0 = green, non-zero = red. Override commands may break this (e.g., `credo && test` fails if credo fails). Users own the risk of custom commands.
7. **Commit failure handling (Dude D1)** — if `git commit` itself fails on green, behavior is loud exit, no revert. Examples cover detection/test gate, not commit failure. Park dedicated example until a consumer hits it.
8. **Nested per-stack settings (Dude D2)** — `dude.tcr.test.<stack>` with flat fallback. Flat-only ships first. Reopen if a user requests per-stack overrides.

## Glossary

| Term                    | Definition |
|-------------------------|------------|
| TCR cycle               | One invocation: edit → detect stack → run test → commit (green) or revert (red) |
| Stack                   | Project's tooling identity (Ruby, Elixir, .NET, Node.js). Detected from file extension and confirmed by marker at git root. |
| Stack detection         | Process of determining the stack from files and markers. Two-phase: (1) extension → candidate stack, (2) marker → confirmation. |
| File-detected stack     | Stack inferred from whitelist extensions of provided files. Phase 1 of detection. |
| Marker                  | A file at git root that confirms the project is for that stack (Gemfile, mix.exs, *.csproj, package.json). Phase 2 of detection. First match wins on walk-up. |
| Stack resolution        | Files agree on a stack AND the matching marker is found at git root. Detection succeeds. |
| Hierarchy fallback      | (Removed.) Files are required; no inference path needs it. |
| Mixed-extension error   | Files span stacks. Error names the offenders with paths and extensions. |
| Unknown-stack error     | Unknown extension, or file-detected stack has no marker at git root. Error message specifies which. |
| Settings override       | `dude.tcr.test` value at user (`~/.claude/settings.json`) or project (`<git-root>/.claude/settings.local.json`) scope, replaces stack default. |
| Auto-commit (empty string) | Settings key present with empty string `""` → skip test, commit automatically (explicit user choice to disable the gate). |
| Git root                | Directory containing `.git/`. Marker search scope. Found by walking up from `Dir.pwd`. |

## CRC Cards

| Object             | Responsibilities                                                        | Collaborators                  |
|--------------------|-------------------------------------------------------------------------|--------------------------------|
| Tcr                | Orchestrate one cycle: detect → run tests → commit-or-revert            | StackDetector, TestsRunner, GitStageCommit, GitRevert |
| StackDetector      | Validate files (whitelist), resolve to stack, find marker via walk-up, raise descriptive errors in phase order | files (input), GitRoot |
| GitRoot            | Walk up from `Dir.pwd` until `.git` is found                            | filesystem |
| TestsRunner        | `TestsRunner.new(stack, settings).pass?` — read settings override or stack default, run the command | Settings, StackDetector |
| Settings           | Read `dude.tcr.test` from user + project settings, project-local wins, return command or nil | `~/.claude/settings.json`, `<git-root>/.claude/settings.local.json` |
| GitStageCommit     | (Unchanged.) Stage and commit on green. Loud exit on failure.           | git |
| GitRevert          | (Unchanged.) Revert on red.                                             | git |

## Files to Change

| File                                       | Change                                                                |
|--------------------------------------------|-----------------------------------------------------------------------|
| `lib/dude/dudes/platform_detector.rb`      | Rename to `stack_detector.rb`, validate whitelist, find marker via walk-up, raise precise errors in phase order |
| `lib/dude/dudes/git_root.rb`               | New, walk up from `Dir.pwd` to find `.git` (reuse PubFinder pattern) |
| `lib/dude/dudes/settings.rb`               | New, read `dude.tcr.test` from user + project settings, project-local wins, return value or nil |
| `lib/dude/dudes/tests_runner.rb`           | Accept stack + settings, fall back to stack default, handle empty string → no-op |
| `lib/dude/dudes/tcr.rb`                    | Wire StackDetector and Settings |
| `spec/dudes/stack_detector_spec.rb`        | Rename from platform_detector_spec, cover whitelist, mixed, unknown, missing-marker cases, error messages, validation order |
| `spec/dudes/git_root_spec.rb`              | Walk-up cases, .git detection |
| `spec/dudes/settings_spec.rb`              | Override absent / present / empty string, precedence (project > global), namespace merge |
| `spec/dudes/tests_runner_spec.rb`          | Stack default vs override vs empty-string-no-op |
| `spec/dudes/tcr_spec.rb`                   | End-to-end wiring, happy path per stack, error cases |

## Current Consumers

| Project | Path              | Stack  | Notes                                  |
|---------|-------------------|--------|----------------------------------------|
| code    | `~/dude/code`     | Ruby   | The dude gem itself, dogfoods TCR      |
| el      | `~/dev/self/el`   | Elixir | Messaging CLI between dudes            |

## Decisions (Resolved in 3-Amigos)

1. **Terminology:** Use "Stack" not "Platform." StackDetector, not PlatformDetector. Domain language matters.
2. **Empty string:** `""` → skip test, auto-commit. User explicitly chose to disable the gate.
3. **Settings scope:** Per-repo only (project-local + user global, no per-stack). One repo = one primary stack.
4. **Settings precedence:** Project-local (`<git-root>/.claude/settings.local.json`) wins over user global. Whole `dude.tcr` namespace is merged.
5. **Marker precedence:** File extension drives stack, marker gates it. Walk-up from cwd, first match wins.
6. **Error messages:** Name files, extensions, stacks, and markers explicitly. User never sees "marker" jargon in errors.
7. **Detection is two-phase:** Extension (phase 1) + marker (phase 2). Error messages reflect both. Validation order: exists → extension → mixed → marker.
8. **Git root:** Walk up from cwd, stop at `.git`. Reuse PubFinder.walk_up_from pattern.
9. **.NET and Node:** Ship skeleton code, marked "untested in production." First real consumer will validate.
10. **Linter override:** Defer. Test override ships first (YAGNI).
11. **Commit failure (Dude D1):** Loud exit, no revert. Dedicated example parked (Red 7).
12. **Per-stack settings keys (Dude D2):** Flat-only ships first. Nested `dude.tcr.test.<stack>` parked (Red 8).

## Sign-Off

- **Liz:** Authored green examples (happy paths, errors, override cases).
- **Dude:** LANGUAGE OK. Glossary terms match. D1 added as Ruby missing-marker variant. D2/D3 reconciled.
- **Kent:** Round 2 positions (K1 walk-up + first match, K2 phased validation order, K3 `TestsRunner.new(stack, settings).pass?` shape) baked into Blue rules and CRC cards. Round 3 sign-off: not received before timeout.
