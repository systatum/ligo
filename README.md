# Backend

```bash
docker compose run custy_backend shards install
docker compose run custy_backend marten genmigrations
docker compose run custy_backend marten migrate
docker compose run custy_backend marten migrate main <migration-date-to-unapply>
docker compose run custy_backend MARTEN_ENV=test marten migrate
docker compose run custy_backend marten play -p 8080 -b 0.0.0.0

# running spec
docker compose run custy_backend crystal spec [--fail-fast]
docker compose run custy_backend crystal spec spec/handlers/product_state_handler_spec.cr
```

In Marten, migrations are created automatically through `genmigrations` after you change/add/remove columns reflected within model files.

## Development

Before committing, run:

```bash
crystal tool format
```

## Endpoints

### Auth::User

- `api_sign_in`
  - returns 200: on successful signing in
  - returns 404: on user not found
  - returns 400: on invalid payload
- `api_sign_up`
  - returns 200: on successful signing up
  - returns 400:
    - invalid payload:
      - incomplete fields
      - user already exists
- `api_request_password_reset`
  - returns 200:
    - when there's account associated to a given email address, and email is sent successfully to said address
    - when there's no account associated to a given email address, avoid helping attacker knows if there is/there is no account associated

## Todo

- Add (top-level) Note model --> user can write note, etc sharing ideas
- Add Offering, package item etc. It must be able to record appointment, so that it can be used for hospital/clinic.
- Add absent system (has image field for selfie (for confirmation)) -- has login and logout time
- Add i18n that's database-overridable, but also cached in memory. For example, so that the word "Item" could be translated differently accross industries (ie: "Tour Package", "Service" etc).

Next release (for hospital):
- Add DailyStock model, which allows for setting the maximum items availability per day. The rationale is for example, in a clinic, we can only serve up to 5 people per day. So we can set the daily items to 5 purchases per day, and set to 0 on saturday and sunday. Perhaps, this can be attached to Pricing

## Convention

- The class veriable `@@` should be at the very top, followed by `includes` and any other macro.

## Upon deployment

- Set `CUSTY_SALT_FOR_HASHED_ID`

## Reference

- [Testing](https://crystal-lang.org/reference/1.14/guides/testing.html)
