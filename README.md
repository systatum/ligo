# Ligo

What is Ligo? Ligo is our "Everything Backend." It is a latin word, a related word of which is ligandus, or in chemistry: ligand, or in toys: lego.

Quick start:

```bash
docker compose up
docker compose run ligo_backend shards install
docker compose run ligo_backend marten genmigrations # create a new migration
docker compose run ligo_backend marten routes # print all the routes in the app
docker compose run ligo_backend marten migrate
docker compose run ligo_backend marten migrate main <migration-date-to-unapply>
docker compose run ligo_backend MARTEN_ENV=test marten migrate
docker compose run ligo_backend marten play -p 8080 -b 0.0.0.0

# running spec
docker compose run ligo_backend crystal spec [--fail-fast]
docker compose run ligo_backend crystal spec spec/handlers/product_state_handler_spec.cr
```

In Marten, migrations are created automatically through `genmigrations` after you change/add/remove columns reflected within model files.

You can get into the container by doing:

```bash
docker compose run ligo_backend bash
```

## Development

Before committing, run:

```bash
crystal tool format
```

Our app is consist of multiple mini-apps, such as "auth" which handles authentication and user-related handling. In each app, there's `app.cr` which handles loading files in order. And yes, each app would have their own `routes.cr` where all routes are defined, like in Rails.

## Endpoints

Unlike in Rails where actions are put into the same controller, in Marten each action has its own handler.

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

- Routing convention:

  | path                                | handler       | description                     |
  |-------------------------------------|---------------|---------------------------------|
  | `""`                                | CreateHandler | Route to create a new record    |
  | `"/<resource_id:some_type>"`        | ShowHandler   | Route to retrieve/show a record |
  | `"/<resource_id:some_type>/update"` | UpdateHandler | Update a record                 |
  | `"/<resource_id:some_type>/delete"` | DeleteHandler | Delete a record                 |\

  If the resource is a `Candidate` then it would be `<candidate_hashed_id:str>` or `<candidate_slug:str>`, for example.

- Scope model with proper app, ie `Workaty::Candidate`.
- The class veriable `@@` should be at the very top, followed by `includes` and any other macro.
- Use either `SlugGenerator` or `IdConcealer` always, never use raw ID. Choose either, adhering to your objective, sound, and based guestimation.
- Any `macro included` on any module should be the last block (look ad `IdConcealer` for a role model).
- Each handler needs a helper class.
- Auhtorization functions are put into helper closely related to handlers.
- We believe in a quality software: let's write spec! Write spec whenever possible.

## Upon deployment

- Set `LIGO_SALT_FOR_HASHED_ID`

## Reference

- [Testing](https://crystal-lang.org/reference/1.14/guides/testing.html)
