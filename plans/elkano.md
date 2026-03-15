# Elkano — Websearch Skill Plan

## Goal
A `/search` skill for Claude Code that delegates to a haiku subagent, keeps parent context clean, minimizes tokens.

---

## Architecture

```
~/.claude/skills/search.md        ← skill (forks to websearcher subagent)
~/.claude/agents/websearcher.md   ← haiku subagent (WebSearch + WebFetch)
```

**Flow:**
```
/search <query>
  → skill forks context
    → websearcher (haiku) runs WebSearch
    → reads top pages via r.jina.ai/{url} if needed
    → returns concise summary only
  → parent gets summary — context stays clean
```

---

## Files to Create

### `~/.claude/skills/search.md`
```yaml
---
name: search
description: Search the web and return a clean summary. Usage: /search <query>
context: fork
agent: websearcher
---

Search the web for: $ARGUMENTS

Return a concise summary (max 300 words) with key findings and sources.
```

### `~/.claude/agents/websearcher.md`
```yaml
---
name: websearcher
description: Web search specialist — searches and summarizes, returns clean output only
model: haiku
tools: WebSearch, WebFetch
---

You are a focused web researcher. Given a query:
1. Run WebSearch with the query
2. For key pages, fetch via WebFetch (prefer r.jina.ai/{url} for clean markdown)
3. Return ONLY a concise summary (max 300 words) with bullet points and source URLs
4. No preamble, no meta-commentary — just findings

Keep output minimal to preserve parent context.
```

---

## Key Decisions

| Decision | Choice | Why |
|----------|--------|-----|
| Search tool | Native `WebSearch` | Built-in, cited, works on haiku |
| Page reading | `r.jina.ai/{url}` via WebFetch | Free, no auth, LLM-optimized markdown |
| Model | `haiku` in subagent frontmatter | 92% cheaper, sufficient for search |
| Delegation | `context: fork` + `agent:` frontmatter | Skills native mechanism, not Agent tool |
| Playwright | Not needed (optional future tier) | Overkill for standard websearch |
| s.jina.ai | Skip | Requires auth, 10k tokens/call |

---

## Token Strategy
- Haiku processes all raw search results (cheap)
- Only summary reaches parent context (300 words ≈ ~400 tokens)
- No MCP overhead (no playwright, no extra tool schemas)
- `r.jina.ai` strips HTML → clean markdown → fewer tokens than raw pages

---

## Open Questions
- Confirm: does `agent:` field reference agent `name:` or filename?
- Test: `$ARGUMENTS` behavior in global `~/.claude/skills/` vs project `.claude/skills/`
- Future: add Playwright MCP tier for JS-heavy/auth-walled sites

---

## References
- [Claude Code Skills Docs](https://code.claude.com/docs/en/skills)
- [Claude Code Subagents Docs](https://code.claude.com/docs/en/sub-agents)
- [microsoft/playwright-mcp](https://github.com/microsoft/playwright-mcp)
- [jina-ai/reader](https://github.com/jina-ai/reader)
- [VoltAgent/awesome-openclaw-skills](https://github.com/VoltAgent/awesome-openclaw-skills)
- [openclaw-search on fastmcp.me](https://fastmcp.me/skills/details/1766/openclaw-search)
