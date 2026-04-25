# News -t Flag: Analysis & Todos

## Analysis

The `-t` flag threads a custom prompt from CLI down to the GitHub Actions workflow dispatch. Today sommelier hardcodes `prompt="1 + 1"` in `trigger` (sommelier.rb:29). The plumbing is straightforward: CLI option -> News orchestrator -> Sommelier -> workflow `-f prompt=`. Default behavior stays the same when `-t` is omitted.

### Files

| File | Path | Role |
|------|------|------|
| cli.rb | `lib/dude/helpers/cli.rb:113-119` | Thor entry point, `--limit` option, instantiates News |
| news.rb | `lib/dude/news/news.rb` | Orchestrator: paperboy (releases) + sommelier (smoke test) |
| sommelier.rb | `lib/dude/news/sommelier.rb` | Triggers `dude.yml` workflow, polls, returns conclusion |
| paperboy.rb | `lib/dude/news/paperboy.rb` | Fetches releases from anthropics/claude-code. Untouched. |

### Current Flow

```
cli.rb: News.new(limit:).run
  -> paperboy.latest_version, paperboy.releases(limit)
  -> sommelier.taste(vintage)
       -> trigger(vintage)  # hardcoded prompt="1 + 1"
       -> wait_for_completion
       -> conclude
```

### Key Insight

sommelier.trigger already sends `-f prompt="1 + 1"` to the workflow. The `-t` flag just makes that value configurable. When omitted, default to `"1 + 1"`.

## Todos for Kenny

- [ ] **cli.rb** - Add `option :taste, type: :string, aliases: '-t', desc: "Custom prompt for vintage taste test"`. Pass `taste: options[:taste]` to `News.new`.
- [ ] **news.rb** - Accept `taste: nil` in initializer. Store as `@taste`. Pass `prompt: @taste` to `@sommelier.taste(latest, prompt: @taste)` in `smoke_test_lines`.
- [ ] **sommelier.rb** - Add `prompt: nil` keyword to `taste(vintage, prompt: nil)` and `trigger(vintage, prompt: nil)`. Default to `"1 + 1"` when nil: `p = prompt || "1 + 1"`.
- [ ] **sommelier_spec.rb** - Add test: custom prompt is passed through to workflow run command. Verify default still sends `"1 + 1"`.
- [ ] **news_spec.rb** - Add test: taste param is forwarded to sommelier. Verify default (no taste) still works.
- [ ] **news.feature** - Add scenario: `dude news -t 'verify haiku delegation is fixed'` triggers workflow with custom prompt string.
- [ ] **paperboy.rb** - No changes needed.
