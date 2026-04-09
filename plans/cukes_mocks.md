# Plan: cukes_mocks

Fix mocking violations in cucumber steps and cuke helpers.

## Violations

### 1. dudes_steps.rb:99-127 — run_with_mocks is end-to-end
**Rule**: mock the next class, no end-to-end through the whole stack
**Problem**: Mocks Gh at the bottom, then creates REAL Paperboy, Sommelier, and News on top. Tests the whole stack through a fake Gh. That's integration testing disguised as cucumber.
**Fix**: Mock Paperboy and Sommelier (the next class from News), not Gh

### 2. dudes_steps.rb:108-112 — brittle command matching
**Rule**: relaxed mocks, no `.with` unless testing that argument
**Problem**: `key.split.all? { |word| run_cmd.include?(word) }` is homebrew `.with` matching — fragile pattern matching on command strings
**Fix**: Use relaxed stubs, return canned data

### 3. cuke/news.rb:97-126 — shadow implementation
**Rule**: mock the next class, relaxed mocks
**Problem**: `run_command()` reimplements Gh behavior with complex conditionals. It's a "shadow Gh" — duplicates domain knowledge of what commands return what
**Fix**: Same as #1 — mock at the right level (Paperboy/Sommelier), not Gh

### 4. Both files — mocking backwards
**Problem**: They mock Gh (2 levels deep) and let real Paperboy/Sommelier run. Should be the opposite: mock Paperboy/Sommelier (direct dependencies of News) and don't care about Gh at all in News tests
**Fix**: News tests mock Paperboy+Sommelier. Paperboy tests mock Gh. Sommelier tests mock Gh. Each layer mocks only the next.
