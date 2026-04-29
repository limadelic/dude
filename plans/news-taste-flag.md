# News -t Flag: Custom Prompt for Vintage Taste Test

## Why

The sommelier smoke-tests new Claude Code releases by running a prompt via GHA. Today it hardcodes `"1 + 1"` — useless for catching real regressions like broken haiku delegation. We need a `-t` flag so we can pass prompts like `dude news -t "delegate to a haiku subagent and have it return hello"` and taste the vintage with a real scenario before upgrading.

## Use Katmandu

Kenny codes, Cartman reviews, Dude decides. One small task per Kenny invocation. Describe BEHAVIOR not implementation.

## Current Code

### sommelier.rb (`lib/dude/news/sommelier.rb`)

The `trigger` method hardcodes the prompt at line 29:
```ruby
def trigger(vintage)
  cmd = "workflow run dude.yml -R UKGEPIC/dude -f prompt=\"1 + 1\" " \
        "-f version=#{vintage} -f timeout=5"
  @gh.run(cmd)
end
```

`taste` is the public API:
```ruby
def taste(vintage)
  trigger(vintage)
  wait_for_completion
  conclude
end
```

### news.rb (`lib/dude/news/news.rb`)

Orchestrator. Calls sommelier in `smoke_test_lines`:
```ruby
def smoke_test_lines(latest)
  result = @sommelier.taste(latest)
  version = extract_version(latest)
  build_vintage_lines(version, result)
end
```

Constructor:
```ruby
def initialize(limit: 5, paperboy: Paperboy.new, sommelier: Sommelier.new)
  @limit = limit
  @paperboy = paperboy
  @sommelier = sommelier
end
```

### cli.rb (`lib/dude/helpers/cli.rb:113-119`)

Thor entry point. Currently only has `--limit`:
```ruby
News.new(limit: options[:limit]).run
```

### dude.yml (`.github/workflows/dude.yml`)

Already accepts `prompt` as a workflow_dispatch input. No changes needed there.

## Flow After Change

```
cli.rb: News.new(limit:, taste:).run
  -> paperboy.latest_version, paperboy.releases(limit)
  -> sommelier.taste(vintage, prompt: taste)
       -> trigger(vintage, prompt: taste)  # uses taste or defaults to "1 + 1"
       -> wait_for_completion
       -> conclude
```

## Todos for Kenny

- [ ] **cli.rb** - Add `option :taste, type: :string, aliases: '-t', desc: "Custom prompt for vintage taste test"`. Pass `taste: options[:taste]` to `News.new`.
- [ ] **news.rb** - Accept `taste: nil` in initializer. Store as `@taste`. Pass `prompt: @taste` to `@sommelier.taste(latest, prompt: @taste)` in `smoke_test_lines`.
- [ ] **sommelier.rb** - Add `prompt: nil` keyword to `taste(vintage, prompt: nil)` and `trigger(vintage, prompt: nil)`. Default to `"1 + 1"` when nil: `p = prompt || "1 + 1"`.
- [ ] **sommelier_spec.rb** - Add test: custom prompt is passed through to workflow run command. Verify default still sends `"1 + 1"`.
- [ ] **news_spec.rb** - Add test: taste param is forwarded to sommelier. Verify default (no taste) still works.
- [ ] **news.feature** - Add scenario: `dude news -t 'verify haiku delegation is fixed'` triggers workflow with custom prompt string.
- [ ] **paperboy.rb** - No changes needed.
- [ ] **dude.yml** - No changes needed. Already accepts `prompt` input.
