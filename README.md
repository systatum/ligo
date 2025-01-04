# Backend

```bash
docker compose run custy_backend shards install
docker compose run custy_backend marten genmigrations
docker compose run custy_backend marten migrate
docker compose run custy_backend marten play -p 8080 -b 0.0.0.0
```

## Reference

- [Testing](https://crystal-lang.org/reference/1.14/guides/testing.html)
