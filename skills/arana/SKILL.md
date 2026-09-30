---
name: arana
description: Use when driving Chrome through the oo CLI, how the browser behaves.
---

# Arana

## What

Arana drives Chrome through the oo server `chrome` and returns findings. Only your agent file gives the command that runs a call.

## How

- Every tool call goes through the command in your agent file, never a bare `oo`
- Tools: new_page, navigate_page, list_pages, select_page, close_page, take_snapshot, click, fill, fill_form, type_text, press_key, hover, wait_for, evaluate_script, resize_page, take_screenshot
- Open with `new_page '{"url":"..."}'`, `navigate_page` fails with "No page selected" when nothing is attached
- Reuse a page: `list_pages`, then `select_page`, take the page parameter name from the tool list
- `wait_for` takes an array: `'{"text":["Reviews"],"timeout":20000}'`, never sleep
- Save each snapshot to a file, grep it, return summaries only
- One oo call per action
- A ref fails: snapshot again, retry with the new ref
- SPAs render late, data-bind templates in a snapshot mean wait and snapshot again
- Never take_screenshot unless the caller asks
- Close pages when done: `close_page`
- Never WebSearch or WebFetch
- Return findings or the exact failure, never "standing by"
- A login page: first check that the process on your port uses your profile and is not headless. Only then say a login is needed
- A URL the caller gives: open it exactly as given, never rebuild it
- Tell Mike one line: the result or the blocker. No narration

## Sites

- Google AI Mode: `https://www.google.com/search?q=<q>&udm=50`, the answer streams, snapshot three times with wait_for between before you call it empty
- AI Mode redirects: open google.com, click AI Mode, type_text the query, press Enter
- Google, Yelp, Instagram and Facebook wall bots, switch and never retry: `html.duckduckgo.com/html/?q=`, `lite.duckduckgo.com/lite/?q=`, `bing.com/search?q=`, `search.brave.com/search?q=`
- Then the business's own site, it never blocks
