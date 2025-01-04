# Backend

```bash
docker compose run custy_backend shards install
docker compose run custy_backend marten genmigrations
docker compose run custy_backend marten migrate
docker compose run custy_backend MARTEN_ENV=test marten migrate
docker compose run custy_backend marten play -p 8080 -b 0.0.0.0
docker compose run custy_backend crystal spec
```

## Todo

- Add Note --> user can write note, etc sharing ideas
- Add Offering, package item etc
- Add tracking of changes
- Add absent system (has image field for selfie (for confirmation)) -- has login and logout time

## Reference

- [Testing](https://crystal-lang.org/reference/1.14/guides/testing.html)
