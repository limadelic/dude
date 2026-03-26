# FS Refactor Plan

## Problem
FS is a god object wrapping stdlib + process ops. No need for it.

## Solution
Kill FS. Use stdlib directly. Mock stdlib in specs.

### 1. File/Dir ops → stdlib
- `@fs.read(path)` → `File.read(path)`
- `@fs.write(path, data)` → `File.write(path, data)`
- `@fs.exist?(path)` → `File.exist?(path)`
- `@fs.dir_exist?(path)` → `Dir.exist?(path)`
- `@fs.children(path)` → `Dir.children(path)`
- `@fs.mkdir_p(path)` → `FileUtils.mkdir_p(path)`
- `@fs.rm_rf(path)` → `FileUtils.rm_rf(path)`
- `@fs.newest_child(dir, sfx)` → inline with Dir + File.mtime

### 2. Symlink ops → stdlib
- `@fs.symlink?(path)` → `File.symlink?(path)`
- `@fs.readlink(path)` → `File.readlink(path)`
- `@fs.symlink(t, l)` → `File.symlink(t, l)`
- `@fs.rm_symlink(path)` → `File.delete(path)`

### 3. Process ops → new class (Helpers::Proc or Helpers::Shell)
- `pgrep(pattern)` → shells out
- `pgrep_all(pattern)` → shells out
- `orphaned?(pid)` → checks ppid
- `kill(pid)` → Process.kill
- `claude_cwds` → shells out

Only this needs a wrapper because it shells out.

## Test style
Mock stdlib directly:
```ruby
allow(File).to receive(:read).with('/path').and_return('content')
allow(Dir).to receive(:exist?).with('/path').and_return(true)
```

## Scope for Dude/Tasks (now)
- Tasks already uses stdlib (done)
- Dude dropped fs (done, aggregate bug to fix)
- Fix Dudes::List to not pass fs to Dude
- Rewrite tasks_spec + dude_spec mocking stdlib

## Scope for rest (later)
- Home, Inbox, Pub, Tell, Unpub, Watch, Health, Pomo, Renderer
- Helpers::Json drops @fs, uses File.read directly
- Kill FS class
- Extract Helpers::Shell for process ops
