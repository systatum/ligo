# Ligo

What is Ligo? Ligo is our "Everything Backend." It is a latin word, a related word of which is ligandus, or in chemistry: ligand, or in toys: lego.

Before moving forward, please install `asdf` and `asdf crystal`. Make sure to use the same version as that specified in `.tool-versions`.

Quick start:

```bash
cd backend # must be in the backend folder

shards install
marten genmigrations # reflect a new migration; in Marten, migrations are created automatically through `genmigrations` after you change/add/remove columns reflected within model files.
marten routes # print all the routes in the app
marten migrate
marten migrate main <migration-date-to-unapply>
MARTEN_ENV=test marten migrate
marten serve -p 3003 # to run the server
marten play -p 8080 -b 0.0.0.0 # to run playground

# running spec
crystal spec [--fail-fast]
crystal spec spec/handlers/product_state_handler_spec.cr
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
- When manipulating relationship, avoid using `relationship.add`, since that [won't trigger a callback](https://github.com/martenframework/marten/discussions/309) and thus no changelog will be recorded. Please follow the example of `Employee` which defines `add_team_divisions`.
- We believe in a quality software: let's write spec! Write spec whenever possible.
- General status code:
  - 200: on successful signing in
  - 404: on user not found
  - 400: on invalid payload

## Deployment

The project uses **Capistrano** for automated deployment to Azure VM with GitHub Actions CI/CD.

### Overview

- **CI/CD**: GitHub Actions builds, tests, and deploys automatically
- **Infrastructure**: Azure VMs (production & staging)
- **Database**: Azure Database for MySQL flexible server
- **Deployment Tool**: Capistrano (Ruby-based deployment automation)
- **Health Monitoring**: Systemd timers with Ruby health check scripts
<details>
<summary>Key Folders & Files</summary>

```
deployer/                          # Capistrano deployment configuration
├── Capfile                        # Capistrano entry point
├── config/
│   ├── deploy.rb                  # Global deployment settings
│   └── deploy/
│       ├── production.rb          # Production environment config
│       └── staging.rb             # Staging environment config
├── lib/capistrano/tasks/
│   └── ligo.rake                  # Custom deployment tasks
└── scripts/
    ├── production/                # Production service files
    │   ├── ligo-prod.service      # Systemd service for app
    │   ├── health-check-prod.service  # Health check service
    │   ├── health-check-prod.timer    # Health check timer (every second)
    │   └── health-check-prod.rb       # Health check script
    └── staging/                   # Staging service files (similar structure)

backend/
├── mybin/                         # Built binaries (created during CI)
│   ├── ligo-prod                  # Production binary
│   ├── ligo-stage                 # Staging binary
│   └── manage                     # Database migration tool (Marten)
└── config/settings/
    └── concerns/
        └── database_config.cr     # Database connection (SSL=PREFFERED by default)
```
</details>

### GitHub Secrets Required

Set these in our repository's Settings > Secrets and variables > Actions:

```bash
# Azure VM Access
AZURE_CLIENT_ID=our-service-principal-client-id
AZURE_TENANT_ID=our-azure-tenant-id 
AZURE_SUBSCRIPTION_ID=our-subscription-id
AZURE_RG=our-resource-group-name
AZURE_VM_NAME=our-vm-name
AZURE_USER=our-vm-username

# Deployment Paths
PROD_PATH="/home/$AZURE_USER/ligo-prod"
STAGE_PATH="/home/$AZURE_USER/ligo-stage"

# Database (multi-line environment variables)
LIGO_DB_ENV="LIGO_DB_HOST=our-db-host\nLIGO_DB_NAME=our-db-name\nLIGO_DB_USERNAME=our-db-user\nLIGO_DB_PASSWORD=our-db-password\nLIGO_DB_PORT=our-db-port"
```

### Database Configuration

Database connections use environment variables:

```crystal
# In database_config.cr
db.host = ENV.fetch("LIGO_DB_HOST", AppSettings.instance.ligo_database_host)
db.name = ENV.fetch("LIGO_DB_NAME", AppSettings.instance.ligo_database_name)
# ... other settings
```

**Note**: MySQL 8.0+ requires `mysql_native_password` for compatibility. The CI workflow configures this automatically.

### Deployment Flow

1. **Test**: Automated tests run on GitHub Actions (Crystal specs, database migrations)
2. **Manual Approval**: Production deployment requires manual approval via GitHub issue
3. **Build**: Crystal binaries built in GitHub Actions
4. **Deploy**: Capistrano uploads binaries and symlinks scripts
5. **Services**: Systemd services started/restarted
6. **Health Checks**: Timer-based monitoring begins

### Health Check & Monitoring System

**Health Check Script** (`scripts/*/health-check-*.rb`):
- Pings `/ping` endpoint every second via systemd timer
- **On Success**: Logs "." to `~/server-logs/server_fine_YYYY_MM_DD_HH.txt`
- **On Failure**: Restarts service, logs crash to `~/server-logs/server_crashes.txt`

### Local Deployment

For emergency deployments, testing, or when GitHub Actions is unavailable.

#### Option A: Docker-based Build (Recommended for Cross-Platform)

<details>
<summary>Step 1: Build with Docker</summary>

**Important**: Use Docker to ensure binaries are compatible with the Azure VM (Ubuntu), especially when building from non-Linux platforms:

- Build binaries using the official Crystal Docker image:

  ```bash
  cd backend
  docker run --rm -v $PWD:/workspace -w /workspace crystallang/crystal:latest sh -c \
      "apt-get update && apt-get install -y libsqlite3-dev && \
       shards install && mkdir -p mybin && \
       crystal build manage.cr -o mybin/manage && \
       crystal build src/server.cr -o mybin/ligo-server --release
      "
  ```

- Copy binary for target environment:

  ```bash
  cp mybin/ligo-server mybin/ligo-prod    # For production
  # OR
  cp mybin/ligo-server mybin/ligo-stage   # For staging
  ```
</details>

#### Option B: Native Crystal Build (Linux Only)

<details>
<summary>Step 1: Build the Application (Native)</summary>

**Note**: Only use this option if you're building on Linux Ubuntu 24.04 or compatible system. For macOS/Windows, use Option A to ensure server compatibility.

- Install required system dependencies:

  ```bash
  # Ubuntu/Debian
  sudo apt-get update && sudo apt-get install -y libsqlite3-dev
  ```

- Navigate to the backend directory and install dependencies:

  ```bash
  cd backend
  shards install
  ```

- Create the binary directory and build the application:

  ```bash
  mkdir -p mybin
  crystal build manage.cr -o mybin/manage
  crystal build src/server.cr -o mybin/ligo-prod --release # For production
  # OR
  # crystal build src/server.cr -o mybin/ligo-stage --release # For staging
  ```
</details>

**Note**: After building with either option above, continue with the following shared steps:

<details>
<summary>Step 2: Configure Environment Variables</summary>

Set the required Azure and deployment variables:

```bash
export AZURE_RG=our-resource-group-name
export AZURE_VM_NAME=our-vm-name
export AZURE_IP=our-vm-ip
export AZURE_USER=our-vm-username
export MARTEN_ENV=production
export LIGO_DB_ENV=$(cat << 'EOF'
LIGO_DB_HOST=our-db-host
LIGO_DB_NAME=our-db-name
LIGO_DB_USERNAME=our-db-username
LIGO_DB_PASSWORD=our-db-password
LIGO_DB_PORT=our-db-port
EOF
)

# Choose one based on your target environment
export PROD_PATH=/home/$AZURE_USER/ligo-prod     # For production
export STAGE_PATH=/home/$AZURE_USER/ligo-stage   # For staging
```

</details>

<details>
<summary>Step 3: Setup GitHub Access Token</summary>

Since Capistrano needs to clone the repository, you need a GitHub Personal Access Token:

- Go to [GitHub Settings > Developer settings > Personal access tokens > Tokens (classic)](https://github.com/settings/tokens)

- Click "Generate new token (classic)"

- Set the following:
  - **Note**: "Ligo Local Deployment"
  - **Expiration**: Choose appropriate duration (e.g., 30 days)
  - **Scopes**: Select `repo` (Full control of private repositories)

- Copy the generated token and export it:

  ```bash
  export GITHUB_TOKEN=your-generated-token-here
  ```

**Note**: Store this token securely and delete it after deployment if it's temporary.

</details>

<details>
<summary>Step 4: Azure Authentication</summary>

- Install [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest) if not already installed

- Login to Azure CLI (if not already logged in):

  ```bash
  az login
  ```

- Verify you're in the correct subscription:

  ```bash
  az account show
  ```

</details>

<details>
<summary>Step 5: Setup Temporary SSH Access</summary>

- Generate a temporary SSH key pair for this deployment:

  ```bash
  ssh-keygen -t ed25519 -f ~/.ssh/deploy_key -N ""
  ```

- Inject your public key to the Azure VM's authorized_keys:

  ```bash
  az vm run-command invoke \
    -g "$AZURE_RG" \
    -n "$AZURE_VM_NAME" \
    --command-id RunShellScript \
    --scripts "mkdir -p /home/$AZURE_USER/.ssh && \
      echo '$(cat ~/.ssh/deploy_key.pub) # local-deploy' >> \
      /home/$AZURE_USER/.ssh/authorized_keys"
  ```

- Setup SSH agent for Capistrano to use:

  ```bash
  eval $(ssh-agent -s)
  ssh-add ~/.ssh/deploy_key
  ```

</details>

<details>
<summary>Step 6: Deploy with Capistrano</summary>

- Install Ruby and Bundler using asdf (if not already installed):

  ```bash
  # Install Ruby plugin for asdf
  asdf plugin add ruby https://github.com/asdf-vm/asdf-ruby.git
  
  # Install Ruby (check .tool-versions for the correct version)
  asdf install ruby
  
  # Install Bundler
  gem install bundler
  ```

- Navigate to the deployer directory and install Ruby dependencies:

  ```bash
  cd ../deployer
  bundle install
  ```

- Run the deployment for your target environment:

  ```bash
  # For production
  cap production deploy
  
  # For staging
  cap staging deploy
  ```

</details>

<details>
<summary>Step 7: Cleanup</summary>

After deployment completes, clean up the temporary SSH access:

- Remove the public key from the VM:

  ```bash
  az vm run-command invoke \
    -g "$AZURE_RG" \
    -n "$AZURE_VM_NAME" \
    --command-id RunShellScript \
    --scripts "grep -v '# local-deploy' \
      /home/$AZURE_USER/.ssh/authorized_keys > \
      /tmp/ak && mv /tmp/ak \
      /home/$AZURE_USER/.ssh/authorized_keys"
  ```

- Remove local SSH files and kill the SSH agent:

  ```bash
  rm -f ~/.ssh/deploy_key ~/.ssh/deploy_key.pub
  kill $SSH_AGENT_PID
  ```

</details>

<details>
<summary>Verification</summary>

After deployment, verify the service is running:

```bash
# SSH to the server
az ssh vm --ip $AZURE_IP -- -t "sudo -u $AZURE_USER --login"

# Check service status
sudo systemctl status ligo-prod.service  # or ligo-stage.service

# Check health check timer
sudo systemctl status health-check-prod.timer

# View recent logs
sudo journalctl -u ligo-prod.service -n 50
sudo journalctl -u health-check-prod.timer -n 50
```

</details>

### Important Note

- **MySQL Version**: Azure Database uses MySQL 8.4, but for compatibility with `crystal-mysql` requires changing user authentication to `mysql_native_password`: `ALTER USER '$LIGO_DB_USERNAME'@'%' IDENTIFIED WITH mysql_native_password BY '$LIGO_DB_PASSWORD';`
- **Crystal MySQL driver**: Use `crystal-mysql` version 0.16.0 as specified in shard.lock, even though it comes from the master branch. Do not update this dependency without testing compatibility with the current MySQL setup.

## Reference

- [Testing](https://crystal-lang.org/reference/1.14/guides/testing.html)
