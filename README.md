# Custy

```bash
docker compose up
docker compose run custy_backend rails db:create db:migrate
```

To update outdated NPM package:

```bash
docker compose run custy_frontend npm outdated
docker compose run custy_frontend npm update <package-name>
```

## Troubleshooting

- ERROR  [nitro] [uncaughtException] listen EADDRINUSE: address already in use /tmp/nitro/worker-30-1.sock

  ```
  docker exec -it custy_frontend bash
  rm /tmp/nitro/worker-*
  ```
