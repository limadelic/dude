# TCR Multi-Language

## Goal

Make TCR work for four platforms: Ruby, Elixir, .NET (C#), Node.js. Detect platform from project conventions. Handle mixed projects via hierarchy.

## Scope

TCR is for **unit tests only**. The allowed file extensions below are the complete whitelist. Files outside this list are rejected — no feature files, no acceptance tests, no config files. If it's not on the list, it doesn't TCR.

## Platform Detection

Two signals, both must agree:

### 1. Allowed file extensions (the whitelist)

Only these extensions can be TCR'd. Anything else is rejected.

| Extension          | Platform |
|--------------------|----------|
| `.ex`, `.exs`      | Elixir   |
| `.cs`              | .NET     |
| `.ts`, `.js`       | Node.js  |
| `.rb`              | Ruby     |

All files in a TCR run must resolve to the **same** platform. Mixed extensions (e.g., `.ex` + `.rb`) = error. Unknown extensions (e.g., `.feature`, `.yml`) = error.

### 2. Project markers (validation — what the project is)

| Platform | Marker        |
|----------|---------------|
| Elixir   | `mix.exs`     |
| .NET     | `*.csproj`    |
| Node.js  | `package.json`|
| Ruby     | `Gemfile`     |

Project marker confirms the file-detected platform exists in this project. If files say Elixir but there's no `mix.exs`, that's also an error.

### Platform commands

| Platform | Test Command                      | Lint Command                          |
|----------|-----------------------------------|---------------------------------------|
| Elixir   | `mix test`                        | `mix credo`                           |
| .NET     | `dotnet test`                     | `dotnet format --verify-no-changes`   |
| Node.js  | `npm test`                        | `npm run lint`                        |
| Ruby     | `bundle exec rspec`               | `bundle exec rubocop`                 |

### Hierarchy (edge case)

When project has multiple markers (Elixir + Gemfile, .NET + package.json), the hierarchy only matters if no files are provided and we need to infer. Order: Elixir > .NET > Node.js > Ruby.

## Design

### Current shape

```
Tcr → TestsRunner (rspec)
    → Linter (rubocop)
    → GitStageCommit (git — already generic)
    → GitRevert (git — already generic)
```

### New shape

```
Tcr → PlatformDetector.detect → :elixir | :dotnet | :node | :ruby
    → TestsRunner.new(files, platform)
    → Linter.new(files, platform)
    → GitStageCommit (unchanged)
    → GitRevert (unchanged)
```

### PlatformDetector

New class. Walks markers top-down by hierarchy. Returns a symbol. Raises if no platform found.

### TestsRunner / Linter

Accept a `platform` param. Map platform to command. Same `pass?` interface.

## Files to change

| File | Change |
|------|--------|
| `lib/dude/dudes/platform_detector.rb` | New — detection logic |
| `lib/dude/dudes/tests_runner.rb` | Add platform → command mapping |
| `lib/dude/dudes/linter.rb` | Add platform → command mapping |
| `lib/dude/dudes/tcr.rb` | Wire in PlatformDetector |
| `spec/dudes/platform_detector_spec.rb` | New — detection specs |
| `spec/dudes/tests_runner_spec.rb` | New/update — platform specs |
| `spec/dudes/linter_spec.rb` | New/update — platform specs |
| `spec/dudes/tcr_spec.rb` | Update — platform wiring |

## Open questions

1. Should `dude tcr` accept a `--platform` flag to override detection?
2. For Elixir+Cucumber, does TCR run `mix test` or both `mix test` and `cucumber`? (Current thinking: just `mix test` — Cucumber is acceptance-level, TCR is unit-level)
3. Lint for Node.js — assume `npm run lint` exists in package.json? Or try `npx eslint`?
4. .NET lint — `dotnet format --verify-no-changes` or skip lint for .NET?
