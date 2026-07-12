# Antrikan Subapp - API Documentation

Queue management system for managing spaces, their operating hours, and channels.

- [Entities](#entities)
  - [Space](#space)
  - [Space Member](#space-member)
  - [Operating Hour](#operating-hour)
  - [Channel](#channel)
  - [Queuer](#queuer)
  - [Item](#item)
  - [Queue](#queue)
  - [Queued Item](#queueditem)
- [API Endpoints](#api-endpoints)
  - [Space CRUD](#space-crud)
  - [Space QR Code](#space-qr-code)
  - [Space Membership By Code](#space-membership-by-code)
  - [Operating Hour CRUD](#operating-hour-crud)
  - [Channel CRUD](#channel-crud)
  - [Queuer CRUD](#queuer-crud)
  - [Item CRUD](#item-crud)
  - [Queue CRUD](#queue-crud)
  - [Queued Item CRUD](#queued-item-crud)
  - [Queued Item History](#queued-item-history)
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

### Queuer

Represents a queueing identity inside a space. A queuer has a name, an auto-generated password (returned once at creation), and can optionally be associated with a registered user.

### Item

A bookable slot or entry within a channel (e.g. "8AM", "Slot A"). Each item has a unique auto-generated 6-character slug, an order, a daily cap, and an optional description and main image. Can be soft-deleted and restored.

### Queue

A logical grouping of queued items within a channel. Created when a queuer submits an order or enters a line. Each queue has a unique 8-character slug, the first two characters are the last two digits of the current year (e.g. `26` for 2026) and the rest are randomly generated. Queue status advances through a state machine from `queued` through to `done` (or `canceled`). All status changes are timestamped and logged.

### Queued Item

An individual item entry within a queue. Multiple queued items can reference the same `item_id`, duplicates are allowed and each is treated as a distinct entry. The queued item has its own status state machine that mirrors the parent queue's states. Status transitions on queued items can automatically trigger status changes on the parent queue. All changes are logged.

---

## API Endpoints

All endpoints require authentication via `Authorization: Bearer <jwt_token>` header.

### Space CRUD

#### Create Space

```
POST /antrikan/api/space/create
Content-Type: application/json
```

```json
{
  "name": "My Office",
  "need_manual_approval": true,
  "has_operating_hours": false
}
```

| Field                  | Required | Description                                                               |
| ---------------------- | -------- | ------------------------------------------------------------------------- |
| `name`                 | yes      | Space name (max 255 chars)                                                |
| `need_manual_approval` | no       | Whether join requests need manual approval (default: `true`)              |
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
```

```json
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
```

```json
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
  "failed": [{ "id": "invalid_id_1" }, { "id": "invalid_id_2" }]
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
```

```json
{
  "day": 0,
  "open_time": "09:00",
  "close_time": "17:00"
}
```

| Field        | Required | Description                                                        |
| ------------ | -------- | ------------------------------------------------------------------ |
| `day`        | yes      | Day of the week: `0`=Mon, `1`=Tue, ..., `6`=Sun — unique per space |
| `open_time`  | yes      | Opening time in `HH:MM` format                                     |
| `close_time` | yes      | Closing time in `HH:MM` format — must be after `open_time`         |

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
```

```json
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
```

```json
{
  "name": "General",
  "description": "General announcements",
  "logo": {
    "base64_bytes": "iVBORw0KGgo...",
    "mimetype": "image/png"
  }
}
```

| Field         | Required | Description                                      |
| ------------- | -------- | ------------------------------------------------ |
| `name`        | yes      | Channel name (max 255 chars)                     |
| `description` | no       | Short description of the channel                 |
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
```

```json
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

### Queuer CRUD

Queuers can be managed within a space and referenced individually by their hashed ID.

#### Create Queuer

Creates a queuer in the specified space and returns a generated plain password.

```
POST /antrikan/api/space/<space_hashed_id>/queuer/create
Content-Type: application/json
```

```json
{
  "name": "Table 1",
  "user_id": "optionalUserHashedId"
}
```

| Field     | Required | Description                         |
| --------- | -------- | ----------------------------------- |
| `name`    | yes      | Queuer display name (max 255 chars) |
| `user_id` | no       | Optional associated user hashed ID  |

If the space is configured with `require_registered_queuer = true`, `user_id` is required.

**Response (201 Created):**

```json
{
  "queuer": {
    "id": "hashedQueuerId",
    "space_id": "hashedSpaceId",
    "user_id": "optionalUserHashedId",
    "name": "Table 1"
  },
  "password": "generated_plain_password"
}
```

`password_hash` is never returned in the response.

#### List Queuers

```
GET /antrikan/api/space/<space_hashed_id>/queuer/index
```

Accepts optional query parameter `with_deleted=true` to include soft-deleted queuers.

**Response (200 OK):**

```json
{
  "queuers": [
    {
      "id": "hashedQueuerId",
      "space_id": "hashedSpaceId",
      "user_id": null,
      "name": "Table 1"
    }
  ]
}
```

#### Get Queuer

```
GET /antrikan/api/queuer/<queuer_hashed_id>
```

**Response (200 OK):**

```json
{
  "id": "hashedQueuerId",
  "space_id": "hashedSpaceId",
  "user_id": null,
  "name": "Table 1"
}
```

Soft-deleted queuers return `404` on this endpoint.

#### Update Queuer

```
PATCH /antrikan/api/space/<space_hashed_id>/queuer/update
Content-Type: application/json
```

```json
{
  "queuer_id": "hashedQueuerId",
  "password": "current_plain_password",
  "name": "Table 1 - Updated",
  "user_id": "optionalUserHashedId"
}
```

**Supported Methods:** `PATCH`, `POST`

| Field       | Required | Description                                                                     |
| ----------- | -------- | ------------------------------------------------------------------------------- |
| `queuer_id` | yes      | Target queuer hashed ID (must belong to the space in path)                      |
| `password`  | yes      | Current plain password for verification                                         |
| `name`      | no       | New queuer name                                                                 |
| `user_id`   | no       | Set association to a user; pass `null` to clear it (if allowed by space policy) |

If the space requires a registered queuer, setting `user_id` to `null` returns `422`.

**Response (200 OK):** Updated queuer object.

#### Delete Queuer (Soft Delete)

Requires `admin` role and the authenticated user must own the queuer's space.

```
DELETE /antrikan/api/queuer/<queuer_hashed_id>/delete
```

**Response (200 OK):** Soft-deleted queuer object.

#### Restore Queuer

Restores a soft-deleted queuer. Requires `admin` role and space ownership.

```
PATCH /antrikan/api/queuer/<queuer_hashed_id>/undelete
```

**Supported Methods:** `PATCH`, `POST`

**Response (200 OK):** Restored queuer object.

### Item CRUD

Items belong to a Channel. Creating, updating, deleting, and restoring items requires the `admin` role.

#### Create Item

```
POST /antrikan/api/channel/<channel_hashed_id>/items/create
Content-Type: application/json
```

```json
{
  "name": "8AM",
  "order": 0,
  "daily_cap": 10,
  "is_monitored": false,
  "description": "Morning slot",
  "main_image": {
    "base64_bytes": "iVBORw0KGgo...",
    "mimetype": "image/png"
  }
}
```

| Field          | Required | Description                                               |
| -------------- | -------- | --------------------------------------------------------- |
| `name`         | yes      | Item name (max 255 chars)                                 |
| `order`        | no       | Display order (default: `0`)                              |
| `daily_cap`    | no       | Maximum bookings per day (default: `0` = unlimited)       |
| `is_monitored` | no       | Whether the item is actively monitored (default: `false`) |
| `description`  | no       | Free-form description                                     |
| `main_image`   | no       | Image payload with `base64_bytes` and `mimetype`          |

**Response (201 Created):**

```json
{
  "id": "abc123",
  "channel_id": "hashedChannelId",
  "name": "8AM",
  "order": 0,
  "daily_cap": 10,
  "is_monitored": false,
  "description": "Morning slot",
  "main_image": "/uploaded_file/<uuid>"
}
```

`main_image` is `null` when no image has been uploaded.

#### List Items

```
GET /antrikan/api/channel/<channel_hashed_id>/items/index
```

Accepts optional query parameter `with_deleted=true` to include soft-deleted items.

**Response (200 OK):**

```json
{
  "items": [
    {
      "id": "abc123",
      "channel_id": "hashedChannelId",
      "name": "8AM",
      "order": 0,
      "daily_cap": 10,
      "is_monitored": false,
      "description": "Morning slot",
      "main_image": null
    }
  ]
}
```

Items are returned ordered by `order` ascending.

#### Get Item

```
GET /antrikan/api/item/<slug>
```

`slug` is the 6-character auto-generated identifier for the item.

**Response (200 OK):** Item object (same shape as create response).

#### Update Item

```
PATCH /antrikan/api/item/<slug>/update
Content-Type: application/json
```

```json
{
  "name": "9AM",
  "order": 1,
  "daily_cap": 5,
  "is_monitored": true,
  "description": "Updated slot",
  "main_image": {
    "base64_bytes": "iVBORw0KGgo...",
    "mimetype": "image/png"
  }
}
```

All fields are optional. **Supported Methods:** `PATCH`, `POST`

**Response (200 OK):** Updated item object.

#### Delete Item (Soft Delete)

Requires `admin` role.

```
DELETE /antrikan/api/item/<slug>/delete
```

**Response (200 OK):** Deleted item object.

#### Restore Item

Restores a soft-deleted item. Requires `admin` role.

```
PATCH /antrikan/api/item/<slug>/undelete
```

**Supported Methods:** `PATCH`, `POST`

**Response (200 OK):** Restored item object.

---

### Queue CRUD

**Authentication:** The index and show endpoints are public (no auth required). The create endpoint is throttled per IP and per `queuer_id`. Update requires authentication.

#### Create Queue

```
POST /antrikan/api/channel/<channel_hashed_id>/queue/create
Content-Type: application/json
```

```json
{
  "queuer_id": "hashedQueuerId",
  "handler_id": "hashedHandlerId",
  "note": "table 4,,,no MSG pls :)",
  "status": "queued",
  "payment_status": "unpaid",
  "fully_paid_at": null
}
```

| Field            | Required | Type   | Description                                                                                           |
| ---------------- | -------- | ------ | ----------------------------------------------------------------------------------------------------- |
| `queuer_id`      | yes      | string | Hashed ID of the queuer placing the order                                                             |
| `handler_id`     | no       | string | Hashed ID of the staff member handling this queue; must belong to the same organization               |
| `note`           | no       | string | Free-form note (max 255 chars)                                                                        |
| `status`         | no       | string | Initial queue status as a string name (default: `"queued"`). See [Queue Status](#queue-status).       |
| `payment_status` | no       | string | Initial payment status as a string name (default: `"unpaid"`). See [Payment Status](#payment-status). |
| `fully_paid_at`  | no       | string | ISO 8601 timestamp of when the queue was fully paid                                                   |

> [!WARNING]
> **Throttling:** This endpoint is rate-limited per remote IP and per `queuer_id`. Exceeding the limit returns `429 Too Many Requests` and blocks further requests for a period.

> [!NOTE]
> **Slug format:** The generated slug is 8 characters long. The first two characters are the last two digits of the current year (e.g. `26` for 2026); the remaining six are randomly generated.

**Response (201 Created):**

```json
{
  "id": "26xK9mQp",
  "channel_id": "hashedChannelId",
  "queuer_id": "hashedQueuerId",
  "handler_id": "hashedHandlerId",
  "note": "Table 4 — no MSG please",
  "status": "queued",
  "payment_status": "unpaid",
  "total_price": 0,
  "fully_paid_at": null,
  "attended_at": null,
  "packed_at": null,
  "ready_at": null,
  "dispatched_at": null,
  "delivered_at": null,
  "created_at": "2026-05-31T12:00:00Z",
  "updated_at": "2026-05-31T12:00:00Z"
}
```

> [!NOTE]
> `total_price` starts at `0` and is recalculated automatically whenever a queued item is added or removed.

#### List Queues

```
GET /antrikan/api/channel/<channel_hashed_id>/queue/index
```

No authentication required.

Accepts optional query parameters:

| Parameter | Description                                                             |
| --------- | ----------------------------------------------------------------------- |
| `status`  | Filter by queue status string name (e.g. `?status=queued` for `queued`) |

Canceled (soft-deleted) queues are excluded from results.

**Response (200 OK):**

```json
{
  "queues": [
    {
      "id": "26xK9mQp",
      "channel_id": "hashedChannelId",
      "queuer_id": "hashedQueuerId",
      "handler_id": null,
      "note": null,
      "status": "queued",
      "payment_status": "unpaid",
      "total_price": 0,
      "fully_paid_at": null,
      "attended_at": null,
      "packed_at": null,
      "ready_at": null,
      "dispatched_at": null,
      "delivered_at": null,
      "created_at": "2026-05-31T12:00:00Z",
      "updated_at": "2026-05-31T12:00:00Z"
    }
  ]
}
```

#### Get Queue

```
GET /antrikan/api/queue/<queue_slug>
```

No authentication required. Returns `404` if the queue has been canceled (status `canceled`).

**Response (200 OK):** Queue object (same shape as create response).

#### Update Queue

```
PATCH /antrikan/api/queue/<queue_slug>/update
Content-Type: application/json
```

```json
{
  "handler_id": "hashedHandlerId",
  "note": "Updated note",
  "status": "attended",
  "payment_status": "full",
  "fully_paid_at": "2026-05-31T13:00:00Z"
}
```

Only the following fields may be updated. All are optional, only provided fields are changed.

| Field            | Description                                                           |
| ---------------- | --------------------------------------------------------------------- |
| `handler_id`     | Assign or reassign a handler; must belong to the same organization    |
| `note`           | Free-form note (max 255 chars)                                        |
| `status`         | Advance or change the queue state (see [Queue Status](#queue-status)) |
| `payment_status` | Update payment status                                                 |
| `fully_paid_at`  | ISO 8601 timestamp of when the queue was fully paid                   |

> [!IMPORTANT]
> `queuer_id` cannot be changed after creation.

Status transitions follow the defined state machine order: `queued -> attended -> packed -> ready -> dispatching -> done`. Setting status to `0` marks the queue as canceled. The corresponding timestamp field is set automatically on each transition (e.g. transitioning to `attended` sets `attended_at`).

**Response (200 OK):** Updated queue object.

---

### Queued Item CRUD

**Authentication:** Create requires the queuer to be identified. Update is a protected endpoint.

#### Create Queued Item

```
POST /antrikan/api/queue/<queue_slug>/item/create
Content-Type: application/json
```

```json
{
  "item_slug": "abc123",
  "quantity": 2,
  "note": "Extra spicy",
  "status": "queued",
  "handler_id": "hashedHandlerId"
}
```

| Field        | Required | Type    | Description                                                            |
| ------------ | -------- | ------- | ---------------------------------------------------------------------- |
| `item_slug`  | yes      | string  | Slug of the item being added to the queue                              |
| `quantity`   | no       | integer | Number of units (default: `1`, must be ≥ 1)                            |
| `note`       | no       | string  | Free-form note (max 255 chars, default: `null`)                        |
| `status`     | no       | integer | Initial status (default: `queued`). See [Queue Status](#queue-status). |
| `handler_id` | no       | string  | Hashed ID of the handler for this individual item                      |

> [!NOTE]
> **Duplicate behavior:** If the same `item_slug` already exists in the queue, a new queued item record is created regardless. No merging or quantity-updating occurs.

**Side effects on the parent queue:**

- `total_price` is recalculated: `unit_price` is copied from the item at the time of enqueue and multiplied by `quantity`.
- The `channel_id` is copied from the item at the time of enqueue.

**Response (201 Created):**

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "queue_id": "26xK9mQp",
  "channel_id": "hashedChannelId",
  "item_id": "abc123",
  "handler_id": null,
  "status": "queued",
  "note": "Extra spicy",
  "unit_price": 15000,
  "quantity": 2
}
```

#### Update Queued Items (Bulk)

Update multiple queued items in a single request. All items must belong to queues the authenticated user's organization owns.

```
PATCH /antrikan/api/queued_item/update
Content-Type: application/json
```

**Supported Methods:** `PATCH`, `POST`

```json
{
  "items": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "handler_id": "hashedHandlerId",
      "status": "done",
      "note": "Updated note"
    }
  ]
}
```

| Field        | Required | Description                                    |
| ------------ | -------- | ---------------------------------------------- |
| `id`         | yes      | Queued item UUID                               |
| `handler_id` | no       | Hashed ID of the handler to (re)assign         |
| `status`     | no       | Advance the item's state (see [Queue Status](#queue-status)) |
| `note`       | no       | Free-form note (max 255 chars)                 |

> [!IMPORTANT]
> `item_slug` and `quantity` cannot be modified after creation. Each item must provide at least one of `handler_id`, `status`, or `note` — an item with none of these returns `422`.

> [!NOTE]
> Canceled (soft-deleted) queued items can still be targeted by this endpoint — e.g. to correct a `note` or reassign a `handler_id` after cancellation. Only `status` transitions are constrained by the state machine; canceling is terminal and cannot be transitioned out of.

> [!IMPORTANT]
> The whole batch is applied atomically: if any item fails (not found, invalid transition, unauthorized), no items in the request are updated and no `queued_item_updated` events are broadcast.

**Parent queue status side effects:**

| Queued item condition                                            | Parent queue transition          |
| ---------------------------------------------------------------- | -------------------------------- |
| Any item transitions to a status other than `done` or `canceled` | Parent transitions to `attended` |
| All items are `done`                                             | Parent transitions to `ready`    |
| Some items are `canceled`, all remaining items are `done`        | Parent transitions to `ready`    |

**Response (200 OK):**

```json
{
  "items": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "queue_id": "26xK9mQp",
      "channel_id": "hashedChannelId",
      "item_id": "abc123",
      "handler_id": "hashedHandlerId",
      "status": "done",
      "note": "Updated note",
      "unit_price": 15000,
      "quantity": 2
    }
  ]
}
```

---

### Queued Item History

#### Get State History

Retrieves a timeline of state transitions for a queued item, with time taken between each state.

```
GET /antrikan/api/queued_item/<queued_item_id>/history
```

Requires authentication and org membership. Canceled (soft-deleted) items are accessible.

**Response (200 OK):** Array of state entries ordered chronologically.

```json
[
  {"state": "QUEUED", "timestamp": "2026-05-31T12:00:00Z", "time_taken_seconds": 0},
  {"state": "ATTENDED", "timestamp": "2026-05-31T12:03:00Z", "time_taken_seconds": 180},
  {"state": "READY", "timestamp": "2026-05-31T12:10:00Z", "time_taken_seconds": 420}
]
```

| Field                | Description                                          |
| -------------------- | ---------------------------------------------------- |
| `state`              | State name (matches [Queue Status](#queue-status))   |
| `timestamp`          | ISO 8601 timestamp when the state was entered        |
| `time_taken_seconds` | Seconds elapsed from the previous state (0 for first) |

States are only included when their corresponding timestamp is set (e.g. `attended_at` is non-null). Intermediate states may be skipped if a transition jumped over them. Total elapsed time can be calculated by summing all `time_taken_seconds` values from `QUEUED` through to the final state.

---

## Enums

> [!NOTE]
> Crystal serializes non-flags enums by name (as a lowercase string). Integer values are listed here for reference only, they are not used in JSON request or response bodies.

### Queue Status

| Value | Name          | Description                                 |
| ----- | ------------- | ------------------------------------------- |
| `0`   | `CANCELED`    | Marked as canceled; treated as soft-deleted |
| `1`   | `QUEUED`      | Newly entered into the queue                |
| `2`   | `ATTENDED`    | Being actively handled                      |
| `3`   | `PACKED`      | Order has been packed                       |
| `4`   | `READY`       | Ready for dispatch or collection            |
| `5`   | `DISPATCHING` | Out for delivery or being processed         |
| `6`   | `DONE`        | Fully completed                             |

### Payment Status

| Value | Name      | Description                         |
| ----- | --------- | ----------------------------------- |
| `0`   | `UNPAID`  | No payment has been received        |
| `1`   | `PARTIAL` | A partial payment has been recorded |
| `2`   | `FULL`    | The queue total is fully paid       |

## Error Responses

| Status | Description                                                                                            |
| ------ | ------------------------------------------------------------------------------------------------------ |
| 400    | Not authenticated or malformed JSON body                                                               |
| 403    | Not authorized (for queuer delete/restore: must be `admin` and owner of the queuer's space)            |
| 404    | Resource not found                                                                                     |
| 422    | Validation error (for queuer update: invalid payload, wrong password, or disallowed `user_id` changes) |
| 429    | Rate limit exceeded                                                                                    |
| 500    | Join endpoint: all submitted users failed to be added                                                  |

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

# Queuer handlers only
crystal spec spec/apps/antrikan/handlers/queuer/

# Queue handlers only
crystal spec spec/apps/antrikan/handlers/queue/

# Queued item handlers only
crystal spec spec/apps/antrikan/handlers/queued_item/

# Specific handler
crystal spec spec/apps/antrikan/handlers/space/qr_handler_spec.cr

# Join-by-code handler
crystal spec spec/apps/antrikan/handlers/space/join_handler_spec.cr
```

---

## Dependencies

- `qr-code` (spider-gazelle/qr-code) - QR code generation
- `stumpy_png` (stumpycr/stumpy_png) - PNG export for QR codes
- `aasm.cr` (veelenga/aasm.cr) — State machine management for Queue and QueuedItem
- `prorate-cr` (WJWH/prorate-cr) — Token-bucket rate limiting for the queue create endpoint
