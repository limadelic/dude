# El2El: Inter-Session Messaging

Issues: UKGEPIC/dude#178 (@dude), UKGEPIC/dude#179 (dogfood burrito with amigos)

## Story (Yellow)

El sessions talk to each other via `@name>` routing — one session sends a message to another without leaving el.

## Rules (Blue)

1. **`@name>` is the routing trigger** — bare `@name` is text, `@name>` routes. The `>` is the send signal (shell redirection metaphor).
2. **Start-of-line detection** — `~r/^@(\w+)>\s*(.*)$/m`. Multiline flag. One route per matching line. Works for both human input and Claude output.
3. **Pure relay** — sender's Claude never processes routed messages. El intercepts, routes, logs. Attribution without processing.
4. **`detect_routes/1`** — pure function. Regex in, route specs out: `[{target, payload}]`. No side effects, no Registry lookup. Validation at relay time.
5. **Two call sites** — incoming message (`handle_cast {:tell}`) and outgoing response (`handle_cast {:store_tell}`). Same function, different insertion points. Human-directed vs Claude-directed.
6. **Self-route filtered** — `if target != state.name`.
7. **Target not running → error** — no silent drops. `"donnie is not running"`.
8. **Relay log type** — sender logs `{"relay", "@donnie> msg", "-> donnie"}`. Third type alongside tell/ask.
9. **Log: 4-element tuple** — `{type, msg, response, %{from: name}}`. Default `%{}` for non-el2el messages.
10. **Prompt prefix for Claude** — `[from dude] you are out of your element`. Metadata for system, context for Claude.
11. **Full output stays in log** — nothing stripped from the response. Routes extracted and relayed as side-effects.

## Examples (Green)

### Tell happy path (human-directed)
```
Given dude and donnie sessions are running
When el dude tell @donnie> you are out of your element
Then El detects @donnie> at start, extracts route spec {:donnie, "you are out of your element"}
And donnie receives [from dude] you are out of your element
And dude log shows {"relay", "@donnie> you are out of your element", "-> donnie"}
And donnie log shows the message with %{from: :dude}
```

### Claude-directed routing
```
Given alice and donnie sessions are running
When user runs: el alice tell "coordinate with donnie on the API"
And alice's Claude responds with:
  I'll review the auth flow.
  @donnie> review the token refresh logic in auth_controller.ex
Then El detects @donnie> in response at start-of-line
And donnie receives [from alice] review the token refresh logic in auth_controller.ex
And alice's full response stays in alice's log
And donnie's log shows the relayed message with %{from: :alice}
```

### Target not running
```
Given only dude session is running
When el dude tell @donnie> you are out of your element
Then relay fails, error logged: "donnie is not running"
```

### Self-route
```
Given dude session is running
When dude's Claude outputs @dude> talking to myself
Then self-route filtered, no relay
```

### Multi-route in one response
```
Given alice, donnie, and walter sessions are running
When alice's Claude responds with:
  I'll handle migration.
  @donnie> handle auth middleware
  @walter> update the test suite
Then donnie receives [from alice] handle auth middleware
And walter receives [from alice] update the test suite
And alice's full response stays in alice's log
```

## Questions (Red — parked)

- **Ask + @name>**: could work as dual action — return full response AND relay @name> lines as side-effect. Explore when needed.
- **Context problem**: recipient gets a decontextualized message. May need richer context injection beyond `[from name]`. Explore when it becomes friction.
- **Loops**: no TTL for now. If autonomous loops become a problem, add a hop counter then.

## CRC Cards

| Object | Responsibilities | Collaborators |
|--------|-----------------|---------------|
| El.Session | call detect_routes on incoming + outgoing, relay route specs, log with metadata, filter self-routes | Registry, El.Session (target) |
| Registry | resolve names to PIDs, validate target alive | El.Session |
| detect_routes/1 | pure function: parse `@name>` from text, return `[{target, payload}]` | none (pure) |
| Route Spec | `{target, payload}` — what detect_routes returns, what relay executes | El.Session |

## Glossary

| Term | Definition | Code anchor |
|------|-----------|-------------|
| **Session** | Named GenServer, unit of identity | `El.Session`, `state.name` |
| **Tell** | Fire-and-forget message | `El.tell/2`, `GenServer.cast` |
| **Ask** | Blocking message | `El.ask/2`, `GenServer.call` |
| **Route** | `@name> payload` directive detected at start-of-line | `detect_routes/1` |
| **Route Spec** | `{target, payload}` — detected, not yet executed | return value of `detect_routes/1` |
| **From** | Session whose Claude produced the route | `state.name` at detection time |
| **Target** | Session the route dispatches to | atom validated via Registry |
| **Relay** | Executing a route spec via `El.tell/2` | the mechanical forwarding |
| **Log** | Message history, 4-element tuples | `state.messages` |

## Dogfooding Notes (#179)

Observed during this amigos session using el:
- El sessions can't read files outside the project (permissions). Had to send plan content via tell.
- Manual routing between amigos is exactly the friction @name> would eliminate.
- `el ask` in bg + cross-pollinate pattern works well for async multi-agent facilitation.
- Session lifecycle (start/kill/ls) is solid. The plumbing works.
