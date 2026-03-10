# Troubleshooting

- **503**: app running but broken — treat as down, full restart
- **Port already in use**: stale dotnet process — kill ports 5000/5001 first
- **RabbitMQ vhost down**: corrupted volume — `docker compose down` + `up -d` (not just restart)
- **docker compose restart not enough**: always down+up for clean state
