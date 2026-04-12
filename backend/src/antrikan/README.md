# Antrikan Subapp - API Documentation

Queue management system for managing spaces, their operating hours, and channels.

- [Entities](#entities)
  - [Space](#space)
  - [Space Member](#space-member)
  - [Operating Hour](#operating-hour)
  - [Channel](#channel)
- [API Endpoints](#api-endpoints)
  - [Space CRUD](#space-crud)
  - [Space QR Code](#space-qr-code)
  - [Space Membership By Code](#space-membership-by-code)
  - [Operating Hour CRUD](#operating-hour-crud)
  - [Channel CRUD](#channel-crud)
- [Error Responses](#error-responses)
- [Running Tests](#running-tests)
- [Dependencies](#dependencies)

## Entities

### Space

A physical or virtual location where queuing or booking occurs. Each space has a unique auto-generated 5-character code used for joining. Owned by a user and can have members, operating hours, and channels.

### Space Member

Join table representing the membership of a user in a space. Created when a user joins a space via its code.

### Operating Hour

Defines the opening and closing times for a space on a specific day of the week. A space can have at most one operating hour entry per day.

### Channel

A named sub-queue or category within a space (e.g. "General", "VIP"). Supports an optional description and logo. Can be soft-deleted and restored.

---

## API Endpoints

All endpoints require authentication via `Authorization: Bearer <jwt_token>` header.

### Space CRUD

#### Create Space

```
POST /antrikan/api/space/create
Content-Type: application/json

{
  "name": "My Office",
  "need_manual_approval": true,
  "has_operating_hours": false
}
```

| Field                  | Required | Description                                                       |
| ---------------------- | -------- | ----------------------------------------------------------------- |
| `name`                 | yes      | Space name (max 255 chars)                                        |
| `need_manual_approval` | no       | Whether join requests need manual approval (default: `true`)      |
| `has_operating_hours`  | no       | Whether the space enforces operating hour restrictions (default: `false`) |

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

**Response (200 OK):** Space object (same shape as above).

#### Update Space

```
PATCH /antrikan/api/space/<hashed_id>/update
Content-Type: application/json

{
  "name": "Updated Office Name",
  "need_manual_approval": false,
  "has_operating_hours": true,
  "logo": {
    "base64_bytes": "iVBORw0KGgo...",
    "mimetype": "image/png"
  }
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
POST /antrikan/api/space/<space_hashed_id>/operating_hours/create
Content-Type: application/json

{
  "day": 0,
  "open_time": "09:00",
  "close_time": "17:00"
}
```

| Field        | Required | Description                                              |
| ------------ | -------- | -------------------------------------------------------- |
| `day`        | yes      | Day of the week: `0`=Mon, `1`=Tue, ..., `6`=Sun — unique per space |
| `open_time`  | yes      | Opening time in `HH:MM` format                           |
| `close_time` | yes      | Closing time in `HH:MM` format — must be after `open_time` |

**Response (201 Created):**

```json
{
  "id": "xyz789",
  "day": 0,
  "open_time": "09:00",
  "close_time": "17:00"
}
```

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

### Channel CRUD

Channels belong to a Space. Creating, deleting, and restoring channels requires the `admin` role.

#### Create Channel

```
POST /antrikan/api/space/<space_hashed_id>/channels/create
Content-Type: application/json

{
  "name": "General",
  "description": "General announcements",
  "logo": {
    "base64_bytes": "iVBORw0KGgo...",
    "mimetype": "image/png"
  }
}
```

| Field         | Required | Description                                  |
| ------------- | -------- | -------------------------------------------- |
| `name`        | yes      | Channel name (max 255 chars)                 |
| `description` | no       | Short description of the channel             |
| `logo`        | no       | Image payload with `base64_bytes` and `mimetype` |

**Response (201 Created):**

```json
{
  "id": "hashedChannelId",
  "name": "General",
  "description": "General announcements",
  "logo": "/uploaded_file/<uuid>"
}
```

`logo` is `null` when no logo has been uploaded.

#### List Channels

```
GET /antrikan/api/space/<space_hashed_id>/channels/index
```

Accepts optional query parameter `with_deleted=true` to include soft-deleted channels.

**Response (200 OK):**

```json
{
  "channels": [
    {
      "id": "hashedChannelId",
      "name": "General",
      "description": "General announcements",
      "logo": null
    }
  ]
}
```

#### Get Channel

```
GET /antrikan/api/channel/<channel_hashed_id>
```

**Response (200 OK):** Channel object (same shape as create response).

#### Update Channel

```
PATCH /antrikan/api/channel/<channel_hashed_id>/update
Content-Type: application/json

{
  "name": "Announcements",
  "description": "Official announcements only",
  "logo": {
    "base64_bytes": "iVBORw0KGgo...",
    "mimetype": "image/png"
  }
}
```

All fields are optional. **Supported Methods:** `PATCH`, `POST`

**Response (200 OK):** Updated channel object.

#### Delete Channel (Soft Delete)

Requires `admin` role.

```
DELETE /antrikan/api/channel/<channel_hashed_id>/delete
```

**Response (200 OK):** Deleted channel object.

#### Restore Channel

Restores a soft-deleted channel. Requires `admin` role.

```
POST /antrikan/api/channel/<channel_hashed_id>/undelete
```

**Response (200 OK):** Restored channel object.

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
