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
