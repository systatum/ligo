# Antrikan Subapp - API Documentation

Queue management system for managing spaces and their operating hours.

## Models

### Space

Represents a physical or virtual space where queuing/booking occurs.

| Field                  | Type        | Description                                                    |
| ---------------------- | ----------- | -------------------------------------------------------------- |
| `id`                   | BigInt      | Primary key (hashed in API responses)                          |
| `code`                 | String(5)   | Unique auto-generated code [A-Z0-9]                            |
| `name`                 | String(255) | Space name (required)                                          |
| `need_manual_approval` | Boolean     | Whether requests need manual approval (default: true)          |
| `has_operating_hours`  | Boolean     | Whether space has operating hour restrictions (default: false) |
| `owner_id`             | FK          | Owner of the space                                             |
| `created_at`           | DateTime    | Auto-set on create                                             |
| `updated_at`           | DateTime    | Auto-set on update                                             |

Additional relation:

- `members` (M2M to `Auth::User`) via `antrikan_space_members`

### SpaceMember

Join table for the Space-to-User membership relation.

| Field      | Type   | Description                         |
| ---------- | ------ | ----------------------------------- |
| `id`       | BigInt | Primary key                         |
| `space_id` | FK     | Referenced space (`antrikan_space`) |
| `user_id`  | FK     | Referenced user (`auth_user`)       |

### OperatingHour

Defines when a Space is open for business.

| Field        | Type      | Description                                  |
| ------------ | --------- | -------------------------------------------- |
| `id`         | BigInt    | Primary key (hashed in API responses)        |
| `space_id`   | FK        | Parent space                                 |
| `day`        | Int       | Day of week: 0=Mon, 1=Tue, ..., 6=Sun        |
| `open_time`  | BigInt    | Opening time in nanoseconds                  |
| `close_time` | BigInt    | Closing time in nanoseconds                  |
| `created_at` | DateTime  | Auto-set on create                           |
| `updated_at` | DateTime  | Auto-set on update                           |

Note: column `open_time` and `close_time` is interpreted as HH:MM on the application-layer (e.g., "09:00" or "17:00").

---

## API Endpoints

All endpoints require authentication via `Authorization: Bearer <jwt_token>` header.

### Space CRUD

#### Create Space

```
POST /antrikan/api/space/
Content-Type: application/json

{
  "name": "My Office",
  "need_manual_approval": true,
  "has_operating_hours": false
}
```

**Response (201 Created):**

```json
{
  "id": "abc123",
  "code": "X7K2Q",
  "name": "My Office",
  "need_manual_approval": true,
  "has_operating_hours": false
}
```

#### List Spaces

```
GET /antrikan/api/space/index
```

**Response (200 OK):**

```json
{
  "spaces": [
    {
      "id": "abc123",
      "code": "X7K2Q",
      "name": "My Office",
      "need_manual_approval": true,
      "has_operating_hours": false
    }
  ]
}
```

#### Get Space

```
GET /antrikan/api/space/<hashed_id>
```

**Response (200 OK):**

```json
{
  "id": "abc123",
  "code": "X7K2Q",
  "name": "My Office",
  "need_manual_approval": true,
  "has_operating_hours": false
}
```

#### Get Space By Code

```
GET /antrikan/api/space/code/<space_code>
```

`space_code` is the 5-character space code (example: `X7K2Q`).

**Response (200 OK):**

```json
{
  "id": "abc123",
  "code": "X7K2Q",
  "name": "My Office",
  "need_manual_approval": true,
  "has_operating_hours": false
}
```

#### Update Space

```
PATCH /antrikan/api/space/<hashed_id>/update
Content-Type: application/json

{
  "name": "Updated Office Name",
  "need_manual_approval": false
}
```

**Supported Methods:** `PATCH`, `POST`

**Response (200 OK):** Updated space object

#### Delete Space (Soft Delete)

```
DELETE /antrikan/api/space/<hashed_id>/delete
```

**Response (200 OK):**

```json
{
  "id": "abc123",
  "code": "X7K2Q",
  "name": "My Office",
  "need_manual_approval": true,
  "has_operating_hours": false
}
```

---

### Space QR Code

#### Get QR Code

Generates a QR code PNG image for the space code, encoded as Base64.

```
GET /antrikan/api/space/<hashed_id>/qr
```

**Response (200 OK):**

```json
{
  "code": "X7K2Q",
  "qr_base64": "iVBORw0KGgo...",
  "content_type": "image/png"
}
```

**Usage Example (JavaScript):**

```javascript
const response = await fetch("/antrikan/api/space/abc123/qr", {
  headers: { Authorization: "Bearer <token>" },
});
const data = await response.json();
const img = document.createElement("img");
img.src = `data:${data.content_type};base64,${data.qr_base64}`;
document.body.appendChild(img);
```

---

### Space Membership By Code

#### Join Space (Add Members)

Adds users as members to a space looked up by code.

```
POST /antrikan/api/space/code/<space_code>/join
Content-Type: application/json

{
  "users": [
    { "user_id": "usrHashA" },
    { "user_id": "usrHashB" }
  ]
}
```

`users` is optional. If omitted or empty, the endpoint returns empty `added` and `failed` arrays.

**Response (201 Created):** at least one user was successfully added (or already existed as a member)

```json
{
  "added": [
    {
      "id": "usrHashA",
      "first_name": "Jane",
      "last_name": "Doe",
      "email": "jane@example.com",
      "role": "member"
    }
  ],
  "failed": [
    {
      "id": "unknown_user_hash"
    }
  ]
}
```

**Response (200 OK):** no `users` provided or empty users payload

```json
{
  "added": [],
  "failed": []
}
```

**Response (500 Internal Server Error):** all requested users failed to be added

```json
{
  "added": [],
  "failed": [
    { "id": "invalid_id_1" },
    { "id": "invalid_id_2" }
  ]
}
```

**Behavior Notes:**

- Duplicate `user_id` entries in payload are de-duplicated/skipped.
- Non-existing users are returned under `failed` with `{ "id": "<submitted_user_id>" }`.
- Existing members are treated as successful entries and returned in `added`.

---

### Operating Hour CRUD

Operating hours are nested under spaces.

#### Create Operating Hour

```
POST /antrikan/api/space/<space_hashed_id>/operating_hours/
Content-Type: application/json

{
  "day": 0,
  "open_time": "09:00",
  "close_time": "17:00"
}
```

**Response (201 Created):**

```json
{
  "id": "xyz789",
  "day": 0,
  "open_time": "09:00",
  "close_time": "17:00"
}
```

**Validation:**

- `day`: 0-6 (Monday-Sunday), unique per space
- `open_time`/`close_time`: HH:MM format
- `close_time` must be after `open_time`

#### List Operating Hours

```
GET /antrikan/api/space/<space_hashed_id>/operating_hours/index
```

**Response (200 OK):**

```json
{
  "op_hours": [
    { "id": "xyz789", "day": 0, "open_time": "09:00", "close_time": "17:00" },
    { "id": "xyz790", "day": 1, "open_time": "10:00", "close_time": "18:00" }
  ]
}
```

#### Update Operating Hour

```
PATCH /antrikan/api/space/<space_hashed_id>/operating_hours/<operating_hour_hashed_id>/update
Content-Type: application/json

{
  "day": 0,
  "open_time": "08:00",
  "close_time": "16:00"
}
```

**Supported Methods:** `PATCH`, `POST`

**Response (200 OK):** Updated operating hour object

#### Delete Operating Hour (Soft Delete)

```
DELETE /antrikan/api/space/<space_hashed_id>/operating_hours/<operating_hour_hashed_id>/delete
```

**Response (200 OK):**

```json
{
  "id": "xyz789",
  "day": 0,
  "open_time": "09:00",
  "close_time": "17:00"
}
```

---

## Error Responses

| Status | Description                                                     |
| ------ | --------------------------------------------------------------- |
| 400    | Not authenticated or malformed JSON body                        |
| 403    | Not authorized (owner-only endpoints)                           |
| 404    | Resource not found                                              |
| 422    | Validation error                                                |
| 500    | Join endpoint: all submitted users failed to be added           |

**Validation Error Example:**

```json
{
  "error": {
    "messages": [
      "Name: Name cannot be blank",
      "Close time: must be after open time"
    ]
  }
}
```

---

## Running Tests

```bash
# All antrikan tests
crystal spec spec/apps/antrikan/

# Space handlers only
crystal spec spec/apps/antrikan/handlers/space/

# Operating hour handlers only
crystal spec spec/apps/antrikan/handlers/operating_hour/

# Specific handler
crystal spec spec/apps/antrikan/handlers/space/qr_handler_spec.cr

# Join-by-code handler
crystal spec spec/apps/antrikan/handlers/space/join_handler_spec.cr
```

---

## Dependencies

- `qr-code` (spider-gazelle/qr-code) - QR code generation
- `stumpy_png` (stumpycr/stumpy_png) - PNG export for QR codes
