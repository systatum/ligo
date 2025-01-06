# Backend

```bash
docker compose run custy_backend shards install
docker compose run custy_backend marten genmigrations
docker compose run custy_backend marten migrate
docker compose run custy_backend MARTEN_ENV=test marten migrate
docker compose run custy_backend marten play -p 8080 -b 0.0.0.0
docker compose run custy_backend crystal spec [--fail-fast]
```

## Todo

- Add Note --> user can write note, etc sharing ideas
- Add Offering, package item etc. It must be able to record appointment, so that it can be used for hospital/clinic.
- Add tracking of changes
- Add absent system (has image field for selfie (for confirmation)) -- has login and logout time
- Add i18n that's database-overridable, but also cached in memory. For example, so that the word "Item" could be translated differently accross industries (ie: "Tour Package", "Service" etc).

## Reference

- [Testing](https://crystal-lang.org/reference/1.14/guides/testing.html)
