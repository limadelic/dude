# Magellan Skill Setup

## Status
- [x] MCP configured (`.mcp.json` with Playwright, Jira, Confluence)
- [x] Test MCP: open Google, navigate to Wikipedia
- [x] Create skill (magellan with elkano agent)
- [x] Jira MCP working
- [ ] Test Confluence MCP (needs restart)

## Branch
`magellan`

## PR
#5212

## Structure
```
.claude/
├── agents/
│   └── elkano.md              # Browser navigator
├── skills/
│   └── magellan/
│       ├── SKILL.md           # Voyage orchestrator
│       ├── surfsup.md         # Ensure localhost up
│       ├── chart.yaml         # Env vars
│       └── maps.yaml          # Saved locators
└── voyages/                   # Test routes (Jira stories)
```

## Flow
1. `/magellan PS-XXXXXX` - fetch Jira, create voyage, run tests
2. Elkano handles browser actions
3. Locators saved to maps.yaml
