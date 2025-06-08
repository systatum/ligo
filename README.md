# Ligo

What is Ligo? Ligo is our "Everything Backend." It is a latin word, a related word of which is ligandus, or in chemistry: ligand, or in toys: lego.

Quick start:

```bash
docker compose up
docker compose run ligo_backend shards install
docker compose run ligo_backend marten genmigrations # reflect a new migration; in Marten, migrations are created automatically through `genmigrations` after you change/add/remove columns reflected within model files.
docker compose run ligo_backend marten routes # print all the routes in the app
docker compose run ligo_backend marten migrate
docker compose run ligo_backend marten migrate main <migration-date-to-unapply>
docker compose run ligo_backend MARTEN_ENV=test marten migrate
docker compose run ligo_backend marten play -p 8080 -b 0.0.0.0

# running spec
docker compose run ligo_backend crystal spec [--fail-fast]
docker compose run ligo_backend crystal spec spec/handlers/product_state_handler_spec.cr
```

You can get into the container by doing:

```bash
docker compose run ligo_backend bash
```

## Running without Docker

We need to install Crystal. One recommended way of doing so is by using asdf.

<details>
<summary>Installing asdf package manager and Crystal</summary>

- Install the [asdf package manager](https://asdf-vm.com/)
- Add [asdf-crystal](https://github.com/asdf-community/asdf-crystal).

  ```bash
  asdf plugin-add crystal https://github.com/asdf-community/asdf-crystal.git
  ```
- Then, install the same Crystal version as in the `Dockerfile`:

  ```bash
  asdf install crystal 1.14.0
  ```
- Then configure to use that version of Crystal on the local directory:

  ```bash
  asdf set crystal 1.14.0
  ```
</details>

<details>
<summary>Setting up your local MariaDB</summary>

You'll also need to have MariaDB installed locally, the [macOS guide is here](https://mariadb.com/kb/en/installing-mariadb-on-macos-using-homebrew/). It could take anywhere from 10 mnutes to 30 minutes or even more to install MariaDB locally. After that:

- Ensure your local MariaDB is running:
  ```bash
  mysql.server start
  ```
- Then, connect to `root` and set your root password:
  ```bash
  mysql -u root
  ```

  Then run the following SQL:

  ```sql
  ALTER USER 'root'@'localhost' IDENTIFIED BY 'rootpwd';
  ```

  You can change `rootpwd` with any password you like using.
- Create 2 databases:
  ```sql
  CREATE DATABASE IF NOT EXISTS ligo_development;
  CREATE DATABASE IF NOT EXISTS ligo_test;
  ```
</details>

<details>
<summary>Setting up the project</summary>

- Installing the project dependencies:

  ```bash
  cd backend
  shards install
  ```

- Change the `development.cr` database setting to:
  ```crystal
  config.database do |db|
    db.host = "127.0.0.1"
    db.name = "ligo_development"
    db.user = "root"
    db.password = "rootpwd"
  end
  ```
- Then run the following commands at your shell to setup the project and get it running on port  `3003`:
  ```crystal
  marten migrate
  marten serve -p 3003
  ```

</details>

## Connecting to the development database

To connect to the database from your host machine

## Email

- On dev, you can inspect all mails sent during development at http://localhost:1080, the MailCatche'r UI.
- On staging, please use mailtrap.
- On production, please use postmark.

## Todo

- Add (top-level) Note model --> user can write note, etc sharing ideas
- Add Offering, package item etc. It must be able to record appointment, so that it can be used for hospital/clinic.
- Add absent system (has image field for selfie (for confirmation)) -- has login and logout time
- Add i18n that's database-overridable, but also cached in memory. For example, so that the word "Item" could be translated differently accross industries (ie: "Tour Package", "Service" etc).

Next release (for hospital):
- Add DailyStock model, which allows for setting the maximum items availability per day. The rationale is for example, in a clinic, we can only serve up to 5 people per day. So we can set the daily items to 5 purchases per day, and set to 0 on saturday and sunday. Perhaps, this can be attached to Pricing

## Convention

- Before committing, please run:

  ```bash
  crystal tool format
  ```
- Our app consists of multiple mini-apps, such as "auth" which handles authentication. In each app, there's `app.cr` to load files in order. And yes, each app would have their own `routes.cr` where all routes are defined, like in Rails.
- Unlike in Rails or most other frameworks where actions are put into the same controller, in Marten each action has its own handler.
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
- General status code:
  - 200: on successful signing in
  - 404: on user not found
  - 400: on invalid payload

## Reference

- [Testing](https://crystal-lang.org/reference/1.14/guides/testing.html)
