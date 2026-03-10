---
name: localhost
description: Start the local REC app (Docker, dotnet, npm) and wait for it to be ready
---

# Localhost

## What
Ensure the local dev environment is running — clean up stale processes, restart Docker, start app fresh.

## How
1. Docker: `docker info` — if fails, `open -a Docker` then /await until `docker info` succeeds
2. Check: `curl -sk -o /dev/null -w "%{http_code}" https://localhost:5001/mordor`
3. If 200 or 302: report ready, stop
4. Otherwise (503, down, anything else), clean slate:
   - Kill stale processes: `lsof -ti:5000,5001 2>/dev/null | xargs kill -9 2>/dev/null`
   - Start backend: `dotnet run --project Product/Presentation.Web.UI.NetCore` (run_in_background)
   - Start frontend: `npm start --prefix Product/Presentation.Web.UI.NetCore` (run_in_background)
   - /await until `https://localhost:5001/mordor` responds 200 or 302 (interval 10s)
5. Report ready

If stuck, see [troubleshooting.md](troubleshooting.md)
