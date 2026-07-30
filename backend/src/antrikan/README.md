# Antrikan Subapp - API Documentation

Queue management system for managing spaces, their operating hours, and channels.

> [!NOTE]
> Run this script to seed database with baseline content, good for E2E test. Be careful that this script truncates your database.
>
> ```bash
> crystal run manage.cr -- seed
> ```

Add features for: refund, proper permission at queue update handler, max_item_piece, and then order. Allow creating sub-channel (so channel now has parent_channel_id), this is needed so that hospital can create sub-queue based on doctor, so the queue estimation will be more proper

- [Entities](#entities)
  - [Space](#space)
  - [Business](#business)
  - [Space Review](#space-review)
  - [Space Member](#space-member)
  - [Operating Hour](#operating-hour)
  - [Channel](#channel)
  - [Queuer](#queuer)
  - [Item](#item)
  - [Voucher](#voucher)
  - [Applied Voucher](#applied-voucher)
  - [Queue](#queue)
  - [Queued Item](#queueditem)
  - [Payment](#payment)
  - [Refund](#refund)
- [API Endpoints](#api-endpoints)
  - [Space CRUD](#space-crud)
  - [Space Review CRUD](#space-review-crud)
  - [Space QR Code](#space-qr-code)
  - [Space Membership By Code](#space-membership-by-code)
  - [Operating Hour CRUD](#operating-hour-crud)
  - [Channel CRUD](#channel-crud)
  - [Queuer CRUD](#queuer-crud)
  - [Item CRUD](#item-crud)
  - [Voucher CRUD](#voucher-crud)
  - [Queue CRUD](#queue-crud)
  - [Queued Item CRUD](#queued-item-crud)
  - [Queued Item History](#queued-item-history)
  - [Payment CRUD](#payment-crud)
  - [Refund CRUD](#refund-crud)
- [Error Responses](#error-responses)
- [Running Tests](#running-tests)
- [Dev Scripts](#dev-scripts)
- [Dependencies](#dependencies)

## Entities

### Space

A physical or virtual location where queuing or booking occurs. Each space has a unique auto-generated 5-character code used for joining, etc. It has defined operating hours, and channels for which bookable/orderable item entries get defined.

### Business

The owning entity of a space. We can think of it as the corporate entity, and space as a branch. This way, it's possible that a space "branched out" to a different city, but still under the same business entity.

### Space Review

A rating and free-text review left by a user against a space. A space's rating summary is computed live from its non-deleted reviews, not a stored/synced column.

### Space Member

Join table representing the membership of a user in a space. Created when a user joins a space via its code.

### Operating Hour

Defines the opening and closing times for a specific day of the week. Each entry belongs to exactly one of a Space, a Channel, or an Item, and there can be at most one entry per day for a given owner. A Channel or Item without its own entry for a day falls back to its parent's hours (Item → Channel → parent Channel, if any → Space), so per-item exceptions only need to be defined where they differ.

### Channel

A named sub-queue or category within a space (e.g. "General", "VIP"). Supports an optional description and logo. Configurable cancellation cutoff - see [Queued Item CRUD](#queued-item-crud). Can be soft-deleted and restored.

A channel may optionally have a `parent_channel_id`, making it a sub-channel - for example, each doctor at a hospital can be its own channel nested under a specialty channel (e.g. "Orthodontics"), giving that doctor an independent line and operating hours instead of sharing the specialty's. Nesting is one level deep only: a channel that already has a parent cannot itself be set as another channel's parent, and a parent must belong to the same space as its sub-channel. A sub-channel without its own operating hours for a day falls back to its parent channel's hours for that day (before falling back further to the space's).

### Queuer

Represents a queueing identity inside a space. A queuer has a name, an auto-generated password (returned once at creation), and can optionally be associated with a registered user.

### Item

A bookable slot or entry within a channel (e.g. "8AM", "Slot A"). Each item has a unique auto-generated 6-character slug, an order, a daily cap, a price with an explicit currency, and an optional description, main image, and photo gallery (same gallery semantics as [Space](#space)). Can be soft-deleted and restored.

### Voucher

A discount code, scoped to a space. Can carry a space-wide rate, a rate targeting one specific channel, and per-item rate overrides, all summed or combined depending on each rule's `mode`. Usable forever by default, or bounded to an active window. Mutable - editing it never changes discounts already locked in on a queue (see [Applied Voucher](#applied-voucher)).

### Applied Voucher

An immutable snapshot of a Voucher's rates, taken the moment it's redeemed against a Queue. A Queue can have more than one over its lifetime. Queued items reference which Applied Vouchers discount them, and discounts stack (chained) if more than one applies. Records who redeemed it, but only when the voucher isn't anonymously redeemable.

### Queue

A cart: a queuer's line-entry into a space, created when a queuer submits an order or enters a line. Its items (see [Queued Item](#queued-item)) can span multiple channels within that space - each item carries its own channel. Each queue has a unique 8-character slug, the first two characters are the last two digits of the current year (e.g. `26` for 2026) and the rest are randomly generated. Queue status advances through a state machine from `queued` through to `done` (or `canceled`). All status changes are timestamped and logged.

### Queued Item

An individual item entry within a queue. Multiple queued items can reference the same `item_id`, duplicates are allowed and each is treated as a distinct entry. The queued item has its own status state machine that mirrors the parent queue's states. Status transitions on queued items can automatically trigger status changes on the parent queue. All changes are logged. Cancellation can carry a reason - see [Queued Item CRUD](#queued-item-crud).

### Payment

An append-only record of money actually collected against a Queue, essentially just a ledger of what was actually paid.

### Refund

A request, not necessarily always approved, to give back some or all of a specific Payment's amount. The same payment can have more than one refund request, each one needs an explicit accept or reject from staff before it counts against that payment's balance.

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
  "description": "A cozy queue space downtown",
  "need_manual_approval": true,
  "has_operating_hours": false,
  "address": "123 Main St",
  "address_city_code": 100010001,
  "address_postal_code": "23615",
  "latitude": 5.5577,
  "longitude": 95.3222,
  "phone": "555-1234",
  "email": "office@example.com",
  "logo": { "base64_bytes": "iVBORw0KGgo...", "mimetype": "image/png" },
  "carousel_images": [
    { "base64_bytes": "iVBORw0KGgo...", "mimetype": "image/png" }
  ],
  "business_name": "Acme Inc."
}
```

| Field                     | Required | Description                                                                                                                                  |
| ------------------------- | -------- | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `name`                    | yes      | Space name (max 255 chars)                                                                                                                   |
| `description`             | no       | Free-form description                                                                                                                        |
| `need_manual_approval`    | no       | Whether join requests need manual approval (default: `true`)                                                                                 |
| `has_operating_hours`     | no       | Whether the space enforces operating hour restrictions (default: `false`)                                                                    |
| `address`/`phone`/`email` | no       | Optional contact/location details                                                                                                            |
| `address_city_code`       | no       | An entry id from a `data/countries/<country_code>_<ISO 3166-1 alpha-3>.json` file (e.g. `data/countries/100_IDN.json`) - rejected with `422` if it doesn't match a known entry |
| `address_postal_code`     | no       | Postal/ZIP code                                                                                                                              |
| `latitude`/`longitude`    | no       | Geocoordinates                                                                                                                               |
| `logo`                    | no       | Image payload with `base64_bytes` and `mimetype`                                                                                             |
| `carousel_images`         | no       | Up to 6 fresh-upload image payloads (`base64_bytes`/`mimetype` each); `keep_id` is rejected here since there's nothing to keep yet on create |
| `business_name`           | no       | Name for the auto-created owning [Business](#business) (default: same as `name`)                                                             |

**Response (201 Created):**

```json
{
  "id": "abc123",
  "code": "X7K2Q",
  "name": "My Office",
  "description": "A cozy queue space downtown",
  "need_manual_approval": true,
  "has_operating_hours": false,
  "require_registered_queuer": false,
  "logo": null,
  "carousel_images": [],
  "business_id": "hashedBusinessId",
  "address": null,
  "address_city_code": null,
  "address_postal_code": null,
  "latitude": null,
  "longitude": null,
  "phone": null,
  "email": null,
  "average_rating": 0.0,
  "review_count": 0
}
```

#### List Spaces

```
GET /antrikan/api/space/index
```

**Response (200 OK):** `{ "spaces": [<Space object>, ...] }` - each entry same shape as the [Create Space](#create-space) response.

#### Get Space

```
GET /antrikan/api/space/<hashed_id>
```

**Response (200 OK):** Space object (same shape as the [Create Space](#create-space) response).

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
  "description": "Now with a rooftop view",
  "need_manual_approval": false,
  "has_operating_hours": true,
  "logo": { "base64_bytes": "iVBORw0KGgo...", "mimetype": "image/png" },
  "carousel_images": [
    { "keep_id": "550e8400-e29b-41d4-a716-446655440000" },
    { "base64_bytes": "iVBORw0KGgo...", "mimetype": "image/png" }
  ],
  "address": "456 Side St",
  "address_city_code": 100010001,
  "address_postal_code": "23615",
  "latitude": 5.5577,
  "longitude": 95.3222,
  "phone": "555-6789",
  "email": "updated@example.com"
}
```

All fields are optional; only provided fields are changed.

| Field                                                            | Description                                                                                                                                                                                                                                |
| ---------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `description`                                                    | Free-form description                                                                                                                                                                                                                      |
| `logo`                                                           | New image payload; pass `null` to clear it                                                                                                                                                                                                 |
| `carousel_images`                                                | Full replacement list (up to 6), in the given order. Each entry is either `{ "keep_id": "<uploaded_file_id>" }` (reuse an image already on this space) or a fresh upload payload. `keep_id` values not currently on the space return `422` |
| `address`/`phone`/`email`                                        | Contact/location details                                                                                                                                                                                                                   |
| `address_city_code`/`address_postal_code`/`latitude`/`longitude` | Geo/postal details - see [Create Space](#create-space)                                                                                                                                                                                     |

**Supported Methods:** `PATCH`, `POST`

**Response (200 OK):** Updated space object

#### Delete Space (Soft Delete)

```
DELETE /antrikan/api/space/<hashed_id>/delete
```

**Response (200 OK):** Deleted space object (same shape as the [Create Space](#create-space) response).

---

### Space Review CRUD

Reviews are nested under spaces. Creating a review requires authentication (the authenticated user becomes `reviewer_id`); no ownership check beyond that.

#### Create Space Review

```
POST /antrikan/api/space/<space_hashed_id>/reviews/create
Content-Type: application/json
```

```json
{ "rating": 8.5, "review": "Great service!" }
```

| Field    | Required | Description                    |
| -------- | -------- | ------------------------------ |
| `rating` | yes      | Float between `0.0` and `10.0` |
| `review` | no       | Free-form text                 |

**Response (201 Created):**

```json
{
  "id": "hashedReviewId",
  "space_id": "hashedSpaceId",
  "reviewer_id": "hashedUserId",
  "rating": 8.5,
  "review": "Great service!"
}
```

#### List Space Reviews

```
GET /antrikan/api/space/<space_hashed_id>/reviews/index
```

Accepts optional query parameter `with_deleted=true` to include soft-deleted reviews.

**Response (200 OK):** `{ "reviews": [<Space Review object>, ...] }`

#### Get / Update / Delete Space Review

```
GET    /antrikan/api/space_review/<space_review_hashed_id>
PATCH  /antrikan/api/space_review/<space_review_hashed_id>/update
DELETE /antrikan/api/space_review/<space_review_hashed_id>/delete
```

Update accepts `rating`/`review`, both optional. **Response:** Space Review object (same shape as create).

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
  "users": [{ "user_id": "usrHashA" }, { "user_id": "usrHashB" }]
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

The same four endpoints are mounted under a Space, a Channel, or an Item - whichever owns the operating hour:

| Owner   | Base path                                                   |
| ------- | ----------------------------------------------------------- |
| Space   | `/antrikan/api/space/<space_hashed_id>/operating_hours`     |
| Channel | `/antrikan/api/channel/<channel_hashed_id>/operating_hours` |
| Item    | `/antrikan/api/item/<item_slug>/operating_hours`            |

> [!NOTE]
> An Item or Channel only needs its own entries where its hours differ from its parent's - see [Operating Hour](#operating-hour) for the fallback behavior.

#### Create Operating Hour

```
POST <base path>/create
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
| `day`        | yes      | Day of the week: `0`=Mon, `1`=Tue, ..., `6`=Sun — unique per owner |
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
GET <base path>/index
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
PATCH <base path>/<operating_hour_hashed_id>/update
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
DELETE <base path>/<operating_hour_hashed_id>/delete
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
  },
  "predeletable_state": "PACKED",
  "enforce_operating_hours": false,
  "max_item_piece": -1,
  "parent_channel_id": null
}
```

| Field                     | Required | Description                                                                                                                     |
| ------------------------- | -------- | ------------------------------------------------------------------------------------------------------------------------------- |
| `name`                    | yes      | Channel name (max 255 chars)                                                                                                    |
| `description`             | no       | Short description of the channel                                                                                                |
| `logo`                    | no       | Image payload with `base64_bytes` and `mimetype`                                                                                |
| `predeletable_state`      | no       | Latest [Queue Status](#queue-status) name a queued item on this channel may be in and still be cancelable (default: `ATTENDED`) |
| `enforce_operating_hours` | no       | Whether adding a queued item is rejected if it's outside its effective operating hours (default: `false`)                       |
| `max_item_piece`          | no       | Max non-canceled queued items of this channel allowed in a single queue at once (default: `-1`, unlimited)                      |
| `parent_channel_id`       | no       | Hashed ID of a parent channel in the same space, making this a sub-channel (see below)                                          |

**Response (201 Created):**

```json
{
  "id": "hashedChannelId",
  "name": "General",
  "description": "General announcements",
  "logo": "/uploaded_file/<uuid>",
  "predeletable_state": 20,
  "enforce_operating_hours": false,
  "max_item_piece": -1,
  "parent_channel_id": null
}
```

`logo` is `null` when no logo has been uploaded. `parent_channel_id` is `null` unless this channel is a sub-channel.

#### List Channels

```
GET /antrikan/api/space/<space_hashed_id>/channels/index
```

Accepts optional query parameter `with_deleted=true` to include soft-deleted channels.

**Response (200 OK):** `{ "channels": [<Channel object>, ...] }` - each entry same shape as the [Create Channel](#create-channel) response.

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
  "logo": { "base64_bytes": "iVBORw0KGgo...", "mimetype": "image/png" },
  "predeletable_state": "READY",
  "enforce_operating_hours": true,
  "max_item_piece": 1,
  "parent_channel_id": "hashedParentChannelId"
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
  "unit_price": 15000,
  "unit_currency": "IDR",
  "is_monitored": false,
  "description": "Morning slot",
  "main_image": { "base64_bytes": "iVBORw0KGgo...", "mimetype": "image/png" },
  "carousel_images": [
    { "base64_bytes": "iVBORw0KGgo...", "mimetype": "image/png" }
  ]
}
```

| Field             | Required | Description                                                                                                 |
| ----------------- | -------- | ----------------------------------------------------------------------------------------------------------- |
| `name`            | yes      | Item name (max 255 chars)                                                                                   |
| `order`           | no       | Display order (default: `0`)                                                                                |
| `daily_cap`       | no       | Maximum bookings per day (default: `0` = unlimited)                                                         |
| `unit_price`      | no       | Price in the smallest currency unit (default: `0`)                                                          |
| `unit_currency`   | no       | Currency name, see [Currency](#currency) (default: `IDR`)                                                   |
| `is_monitored`    | no       | Whether the item is actively monitored (default: `false`)                                                   |
| `description`     | no       | Free-form description                                                                                       |
| `main_image`      | no       | Image payload with `base64_bytes` and `mimetype`                                                            |
| `carousel_images` | no       | Up to 6 fresh-upload image payloads; `keep_id` is rejected here since there's nothing to keep yet on create |

**Response (201 Created):**

```json
{
  "id": "abc123",
  "channel_id": "hashedChannelId",
  "name": "8AM",
  "order": 0,
  "daily_cap": 10,
  "unit_price": 15000,
  "unit_currency": 100,
  "is_monitored": false,
  "description": "Morning slot",
  "main_image": "/uploaded_file/<uuid>",
  "carousel_images": []
}
```

`main_image` is `null` when no image has been uploaded.

#### List Items

```
GET /antrikan/api/channel/<channel_hashed_id>/items/index
```

Accepts optional query parameter `with_deleted=true` to include soft-deleted items.

**Response (200 OK):** `{ "items": [<Item object>, ...] }` - each entry same shape as the [Create Item](#create-item) response, ordered by `order` ascending.

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
  "unit_price": 17500,
  "unit_currency": "USD",
  "is_monitored": true,
  "description": "Updated slot",
  "main_image": { "base64_bytes": "iVBORw0KGgo...", "mimetype": "image/png" },
  "carousel_images": [
    { "keep_id": "550e8400-e29b-41d4-a716-446655440000" },
    { "base64_bytes": "iVBORw0KGgo...", "mimetype": "image/png" }
  ]
}
```

All fields are optional; only provided fields are changed. `carousel_images`, when provided, is a full replacement list (up to 6) - same `keep_id`-or-fresh-upload semantics as [Update Space](#update-space).

**Supported Methods:** `PATCH`, `POST`

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

### Voucher CRUD

**Authentication:** Create, list, get, update, delete, and restore all require the space owner/manager.

#### Create Voucher

```
POST /antrikan/api/space/<space_hashed_id>/voucher/create
Content-Type: application/json
```

```json
{
  "code": "SAVE10",
  "name": "10% off everything",
  "channel_id": "hashedChannelId",
  "space_percentage_discount": 5.0,
  "space_fixed_discount": 0,
  "channel_percentage_discount": 5.0,
  "channel_fixed_discount": 0,
  "discountable_items": [
    { "item_id": "abc123", "percentage_discount": 15.0, "mode": "override" }
  ],
  "indeterminate": false,
  "starts_at": "2026-01-01T00:00:00Z",
  "expires_at": "2026-12-31T23:59:59Z",
  "anon_redeemable": false,
  "max_redeem_per_user": 1
}
```

| Field                         | Required                       | Description                                                                                                                                                                   |
| ----------------------------- | ------------------------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `code`                        | no                             | Redemption code (auto-generated if omitted)                                                                                                                                   |
| `name`                        | no                             | Human-readable label                                                                                                                                                          |
| `channel_id`                  | no                             | Hashed ID of the single channel the channel-wide rates below target                                                                                                           |
| `space_percentage_discount`   | no                             | Percentage off space-wide, e.g. `10` means 10% off                                                                                                                            |
| `space_fixed_discount`        | no                             | Flat amount off space-wide                                                                                                                                                    |
| `channel_percentage_discount` | no                             | Percentage off items in `channel_id`                                                                                                                                          |
| `channel_fixed_discount`      | no                             | Flat amount off items in `channel_id`                                                                                                                                         |
| `discountable_items`          | no                             | Per-item rate overrides - each entry is `item_id` (an Item's `slug`), `percentage_discount`/`fixed_discount`, and `mode`                                                      |
| `indeterminate`               | no                             | `true` (default): usable forever, `starts_at`/`expires_at` are ignored. `false`: bounded by the active window below.                                                          |
| `starts_at`/`expires_at`      | only if `indeterminate: false` | ISO 8601 timestamps bounding when the voucher can be redeemed; `starts_at` must be before `expires_at`                                                                        |
| `anon_redeemable`             | no                             | `true` (default): redeemable without a registered user. `false`: the queue's queuer must be linked to a registered user to redeem this voucher.                               |
| `max_redeem_per_user`         | no                             | Max times the same registered user can redeem this voucher. `-1` (default): unlimited. Only enforceable when `anon_redeemable: false` - otherwise the redeemer isn't tracked. |

`mode` on a `discountable_items` entry controls how it combines with the space/channel-wide rates:

| Mode             | Behavior                                                                                                                                   |
| ---------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| `override`       | Replaces the space/channel-wide discount entirely for that item                                                                            |
| `sum` (default)  | Summed with the space+channel rates, applied together in one pass                                                                          |
| `sum_separately` | Space+channel discount applied first, then the item discount applied again on the already-discounted remainder (compounding, not additive) |

**Response (201 Created):**

```json
{
  "id": "hashedVoucherId",
  "code": "SAVE10",
  "name": "10% off everything",
  "channel_id": "hashedChannelId",
  "space_percentage_discount": 5.0,
  "space_fixed_discount": null,
  "channel_percentage_discount": 5.0,
  "channel_fixed_discount": null,
  "discountable_items": [
    {
      "item_id": "abc123",
      "percentage_discount": 15.0,
      "fixed_discount": null,
      "mode": "override"
    }
  ],
  "indeterminate": true,
  "starts_at": null,
  "expires_at": null,
  "anon_redeemable": true,
  "max_redeem_per_user": -1
}
```

> [!NOTE]
> Redeeming a voucher (`voucher_code` on [Create Queue](#create-queue)/[Update Queue](#update-queue)) is rejected with `422` if the voucher is outside its active window, if the queuer has no linked registered user and the voucher is not anonymously redeemable, or if that user already redeemed it the maximum allowed number of times. The error message contains a machine-readable code (ie `ERR_VOUCH_INACTIVE`) rather than a numeric value, so clients don't need to guess what it means.

> [!NOTE]
> Redeeming a voucher (`voucher_code` on [Create Queue](#create-queue)/[Update Queue](#update-queue)) only attaches it - discounts aren't computed until the queue's `payment_status` first leaves `unpaid`. See [Applied Voucher](#applied-voucher).

#### List Vouchers

```
GET /antrikan/api/space/<space_hashed_id>/voucher/index
```

Accepts optional query parameter `with_deleted=true` to include soft-deleted vouchers.

**Response (200 OK):** `{ "vouchers": [<Voucher object>, ...] }` - each entry same shape as the [Create Voucher](#create-voucher) response.

#### Get Voucher

```
GET /antrikan/api/voucher/<voucher_hashed_id>
```

**Response (200 OK):** Voucher object (same shape as create response).

#### Update Voucher

```
PATCH /antrikan/api/voucher/<voucher_hashed_id>/update
Content-Type: application/json
```

Accepts the same fields as [Create Voucher](#create-voucher). All fields are optional. **Supported Methods:** `PATCH`, `POST`

**Response (200 OK):** Updated voucher object.

> [!NOTE]
> Editing a voucher never changes discounts already locked in on a queue - see [Applied Voucher](#applied-voucher).

#### Delete Voucher (Soft Delete)

```
DELETE /antrikan/api/voucher/<voucher_hashed_id>/delete
```

**Response (200 OK):** Deleted voucher object.

#### Restore Voucher

Restores a soft-deleted voucher.

```
POST /antrikan/api/voucher/<voucher_hashed_id>/undelete
```

**Response (200 OK):** Restored voucher object.

#### Check Voucher Redeemability

No authentication required. Lets a client check whether a code is redeemable before actually submitting a queue/order - doesn't attach anything or create an [Applied Voucher](#applied-voucher).

```
GET /antrikan/api/voucher/redeemable?queue_id=<queue_slug>&code=<code>
```

| Parameter  | Required | Description                                                                                                                    |
| ---------- | -------- | ------------------------------------------------------------------------------------------------------------------------------ |
| `queue_id` | yes      | The queue's slug (same value as [Queue](#queue)'s `id` in responses) - determines the space/queuer the code is checked against |
| `code`     | yes      | The voucher code to check                                                                                                      |

**Response (200 OK):**

```json
{
  "redeemable": true,
  "error_code": null
}
```

If not redeemable, `error_code` is one of the codes described above:

```json
{
  "redeemable": false,
  "error_code": "ERR_VOUCH_INACTIVE"
}
```

Returns `422` if `queue_id` or `code` is missing, `404` if `queue_id` doesn't match any queue.

---

### Queue CRUD

**Authentication:** The index and show endpoints are public (no auth required). The create endpoint is throttled per IP and per `queuer_id`. Update requires authentication.

#### Create Queue

```
POST /antrikan/api/space/<space_hashed_id>/queue/create
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

| Field            | Required | Type   | Description                                                                                                                                                                     |
| ---------------- | -------- | ------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `queuer_id`      | yes      | string | Hashed ID of the queuer placing the order                                                                                                                                       |
| `handler_id`     | no       | string | Hashed ID of the staff member handling this queue; must belong to the same organization                                                                                         |
| `note`           | no       | string | Free-form note (max 255 chars)                                                                                                                                                  |
| `status`         | no       | string | Initial queue status as a string name (default: `"queued"`). See [Queue Status](#queue-status).                                                                                 |
| `payment_status` | no       | string | Initial payment status as a string name (default: `"unpaid"`). See [Payment Status](#payment-status).                                                                           |
| `fully_paid_at`  | no       | string | ISO 8601 timestamp of when the queue was fully paid                                                                                                                             |
| `items`          | no       | array  | Bulk-create the queue's initial items - each entry same shape as [Create Queued Item](#create-queued-item)'s request body. Atomic: if any entry is invalid, nothing is created. |
| `voucher_code`   | no       | string | Redeem a [Voucher](#voucher)'s code against this queue - see [Voucher CRUD](#voucher-crud)                                                                                      |

> [!WARNING]
> **Throttling:** This endpoint is rate-limited per remote IP and per `queuer_id`. Exceeding the limit returns `429 Too Many Requests` and blocks further requests for a period.

> [!NOTE]
> **Slug format:** The generated slug is 8 characters long. The first two characters are the last two digits of the current year (e.g. `26` for 2026); the remaining six are randomly generated.

**Response (201 Created):**

```json
{
  "id": "26xK9mQp",
  "space_id": "hashedSpaceId",
  "queuer_id": "hashedQueuerId",
  "handler_id": "hashedHandlerId",
  "note": "Table 4 — no MSG please",
  "status": 10,
  "payment_status": 0,
  "total_price": "0.0",
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
> `total_price` is a string to represent an exact decimal (via BigFloat), so voucher discounts never lose precision to floating-point/int rounding. It starts at `"0.0"` and is recalculated automatically whenever a queued item is added or removed.

#### List Queues

```
GET /antrikan/api/space/<space_hashed_id>/queue/index
```

No authentication required. Returns every queue in the space, regardless of which channel(s) their items are in.

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
      "space_id": "hashedSpaceId",
      "queuer_id": "hashedQueuerId",
      "handler_id": null,
      "note": null,
      "status": 10,
      "payment_status": 0,
      "total_price": "0.0",
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

#### Get Queue Estimation

```
GET /antrikan/api/queue/<queue_slug>/estimation
```

No authentication required. Scans the queue's own active (not yet `done`, not canceled) queued items, groups them by channel, and for each channel reports how many other active items - from any queue - arrived in that channel before this queue's did. Position-only: no derived wait-time-in-minutes is returned. A channel is omitted entirely once every item this queue has there is `done`.

**Response (200 OK):**

```json
[
  { "channel_id": "hashedChannelId", "items_ahead": 3 },
  { "channel_id": "hashedOtherChannelId", "items_ahead": 0 }
]
```

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

| Field            | Description                                                                                    |
| ---------------- | ---------------------------------------------------------------------------------------------- |
| `handler_id`     | Assign or reassign a handler; must belong to the same organization                             |
| `note`           | Free-form note (max 255 chars)                                                                 |
| `status`         | Advance or change the queue state (see [Queue Status](#queue-status))                          |
| `payment_status` | Update payment status                                                                          |
| `fully_paid_at`  | ISO 8601 timestamp of when the queue was fully paid                                            |
| `voucher_code`   | Redeem a [Voucher](#voucher)'s code against this queue - space-owner only (rejected otherwise) |

> [!IMPORTANT]
> `queuer_id` cannot be changed after creation.

Status transitions follow the defined state machine order: `queued -> attended -> packed -> ready -> dispatching -> done`. Setting status to `0` marks the queue as canceled. The corresponding timestamp field is set automatically on each transition (e.g. transitioning to `attended` sets `attended_at`).

> [!NOTE]
> The first time `payment_status` moves away from `unpaid` (here or at create), every voucher attached to the queue gets matched against its queued items and `total_price` is recalculated with discounts applied - see [Voucher CRUD](#voucher-crud).

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

| Field        | Required | Type    | Description                                                                    |
| ------------ | -------- | ------- | ------------------------------------------------------------------------------ |
| `item_slug`  | yes      | string  | Slug of the item being added to the queue                                      |
| `quantity`   | no       | integer | Number of units (default: `1`, must be ≥ 1)                                    |
| `note`       | no       | string  | Free-form note (max 255 chars, default: `null`)                                |
| `status`     | no       | string  | Initial status by name (default: `queued`). See [Queue Status](#queue-status). |
| `handler_id` | no       | string  | Hashed ID of the handler for this individual item                              |

> [!NOTE]
> **Duplicate behavior:** If the same `item_slug` already exists in the queue, a new queued item record is created regardless. No merging or quantity-updating occurs.

> [!WARNING]
> Rejected with `422` once the queue's `payment_status` is no longer `unpaid` - items can't be added to an already-paid queue, or if the channel has `enforce_operating_hours` enabled, and an item falls outside its effective operating hours right (if defined).

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
  "status": 10,
  "note": "Extra spicy",
  "cancel_note": null,
  "unit_price": 15000,
  "quantity": 2,
  "rank": null,
  "applied_voucher_ids": [],
  "discount_amount": "0.0",
  "discounted_total": "30000.0"
}
```

`applied_voucher_ids`/`discount_amount`/`discounted_total` reflect any [Voucher](#voucher)s discounting this item - see [Voucher CRUD](#voucher-crud).

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
      "note": "Updated note",
      "cancel_note": "Customer changed their mind"
    }
  ]
}
```

Only the following fields may be updated per item. All are optional (at least one must be provided).

| Field         | Required | Description                                                                                                                                   |
| ------------- | -------- | ----------------------------------------------------------------------------------------------------------------------------------------------|
| `id`          | yes      | Queued item UUID                                                                                                                               |
| `handler_id`  | no       | Assign or reassign a handler for this individual item                                                                                          |
| `status`      | no       | Advance the item's state (see [Queue Status](#queue-status) and parent queue behavior below)                                                  |
| `note`        | no       | Free-form note (max 255 chars)                                                                                                                 |
| `cancel_note` | no       | Reason for cancellation (max 255 chars); only persisted when `status` is set to `CANCELED` in this same request - silently ignored otherwise  |

> [!IMPORTANT]
> `item_slug` and `quantity` cannot be modified after creation. Each item must provide at least one of `handler_id`, `status`, or `note` — an item with none of these returns `422`.

> [!NOTE]
> Canceled (soft-deleted) queued items can still be targeted by this endpoint — e.g. to correct a `note` or reassign a `handler_id` after cancellation. Only `status` transitions are constrained by the state machine; canceling is terminal and cannot be transitioned out of.

> [!IMPORTANT]
> The whole batch is applied atomically: if any item fails (not found, invalid transition, unauthorized), no items in the request are updated and no `queued_item_updated` events are broadcast.

> [!WARNING]
> **Cancellation cutoff:** setting `status` to `CANCELED` (deleting the item) is rejected with `422` once the item has progressed past its channel's configured cancellation cutoff (see [Channel](#channel)). The cutoff is inclusive - an item exactly at the cutoff state can still be canceled.

> [!WARNING]
> Rejected with `422` once the queue's `payment_status` is no longer `unpaid` - items can't be edited or canceled on an already-paid queue.

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
      "cancel_note": null,
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

### Payment CRUD

**Authentication:** Both endpoints require staff access to the queue's space - the manager, the business owner, or any admin-level member of the same organization (not owner-only).

#### Record Payment

```
POST /antrikan/api/queue/<queue_slug>/payment/create
Content-Type: application/json
```

```json
{
  "amount": "100000",
  "method": "cash",
  "note": "Paid in full at counter"
}
```

| Field    | Required | Type   | Description                                            |
| -------- | -------- | ------ | ------------------------------------------------------ |
| `amount` | yes      | string | Amount collected, must be greater than 0               |
| `method` | no       | string | Free-form payment method (e.g. `"cash"`, `"transfer"`) |
| `note`   | no       | string | Free-form note (max 255 chars)                         |

> [!NOTE]
> `amount` is a string to represent an exact decimal (via BigFloat), same convention as `total_price` on [Queue](#queue).

There's no review step here - recording a payment is trusted the same way `payment_status` itself is manually asserted by staff today. It's purely additive: nothing here changes `payment_status` or `total_price`.

**Response (201 Created):**

```json
{
  "id": "hashedPaymentId",
  "queue_id": "26xK9mQp",
  "amount": "100000",
  "method": "cash",
  "note": "Paid in full at counter",
  "recorded_by_id": "hashedUserId",
  "amount_refunded": "0",
  "remaining_refundable_amount": "100000",
  "created_at": "2026-05-31T12:00:00Z",
  "updated_at": null,
  "deleted_at": null
}
```

`amount_refunded`/`remaining_refundable_amount` are computed live from this payment's accepted [Refund](#refund)s, not stored columns - a refund always draws down against a specific payment, never a vague pool of money against the whole queue.

#### List Payments

```
GET /antrikan/api/queue/<queue_slug>/payment/list
```

**Response (200 OK):** `{ "payments": [<Payment object>, ...] }` - each entry same shape as the [Record Payment](#record-payment) response. Soft-deleted payments are excluded.

---

### Refund CRUD

**Authentication:** Create and Get Refund require no special access - any identified requester can ask for a refund (same as [Create Queued Item](#create-queued-item)), and knowing a refund's slug is enough to check on it (same as [Get Queue](#get-queue)), since requesters are often anonymous. Every other endpoint below requires staff access to the underlying space (the manager, the business owner, or any admin-level member of the same organization).

#### Request Refund

```
POST /antrikan/api/payment/<payment_hashed_id>/refund/create
Content-Type: application/json
```

```json
{
  "amount": "20000",
  "reason": "Item was cold on arrival",
  "forceful": false,
  "images": [{ "base64_bytes": "iVBORw0KGgo...", "mimetype": "image/png" }]
}
```

| Field      | Required | Type    | Description                                                                                      |
| ---------- | -------- | ------- | ------------------------------------------------------------------------------------------------ |
| `amount`   | yes      | string  | Amount to refund, must be greater than 0                                                         |
| `reason`   | no       | string  | Free-form reason (max 255 chars)                                                                 |
| `forceful` | no       | boolean | See below (default: `false`)                                                                     |
| `images`   | no       | array   | Up to 2 evidence photos, same payload shape as `carousel_images` - see [Space CRUD](#space-crud) |

> [!WARNING]
> Rejected with `422` if the payment's queue is still `unpaid` as there's nothing collected yet to refund, or if this amount would leave the payment's refundable balance negative (i.e. it refunds more than what's left), unless `forceful: true` is set.

**Response (201 Created):**

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "payment_id": "hashedPaymentId",
  "amount": "20000",
  "reason": "Item was cold on arrival",
  "forceful": false,
  "status": "PENDING",
  "review_note": null,
  "images": [],
  "requested_by_id": "hashedUserId",
  "reviewed_by_id": null,
  "reviewed_at": null,
  "created_at": "2026-05-31T12:00:00Z",
  "updated_at": null,
  "deleted_at": null
}
```

`requested_by_id` is `null` when the requester isn't an identified/registered user. `images` entries are resolved uploaded files (`id`, `url`, `original_name`, `content_type`, `byte_size`), same shape as `carousel_images` elsewhere.

#### List Refunds For A Payment

```
GET /antrikan/api/payment/<payment_hashed_id>/refund/list
```

**Response (200 OK):** `{ "refunds": [<Refund object>, ...] }` - each entry same shape as the [Request Refund](#request-refund) response. Soft-deleted refunds are excluded.

#### List Refunds For A Space

A staff-wide dashboard view across every channel/queue/payment in the space, not scoped to one payment.

```
GET /antrikan/api/space/<space_hashed_id>/refund/list
```

**Response (200 OK):** `{ "refunds": [<Refund object>, ...] }`, same shape as above.

#### Get Refund

No authentication required - knowing the refund's slug is enough, the same tradeoff as [Get Queue](#get-queue).

```
GET /antrikan/api/refund/<refund_slug>
```

**Response (200 OK):** Refund object (same shape as create response), with `review_note` visible only for a staff viewer.

#### Accept Refund

```
POST /antrikan/api/refund/<refund_slug>/accept
Content-Type: application/json
```

```json
{ "review_note": "Confirmed with customer" }
```

| Field         | Required | Description                    |
| ------------- | -------- | ------------------------------ |
| `review_note` | no       | Free-form note (max 255 chars) |

The payment's remaining refundable balance is re-checked at this point too, not just at request time - other refunds against the same payment may have been accepted in the meantime. Rejected with `422` if that check fails and the refund wasn't requested with `forceful: true`, or if the refund has already been accepted/rejected.

**Response (200 OK):** Updated refund object, with `status: "ACCEPTED"`, `reviewed_by_id`, and `reviewed_at` set.

#### Reject Refund

```
POST /antrikan/api/refund/<refund_slug>/reject
Content-Type: application/json
```

Same request body as [Accept Refund](#accept-refund). No balance check applies - rejecting never affects a payment's balance.

**Response (200 OK):** Updated refund object, with `status: "REJECTED"`, `reviewed_by_id`, and `reviewed_at` set.

> [!NOTE]
> A queue's `payment_status` cannot be moved back to `unpaid` while it has any `PENDING` or `ACCEPTED` refund - see [Update Queue](#update-queue). A `REJECTED` refund doesn't block this.

---

## Enums

> [!WARNING]
> **Requests vs. responses are asymmetric.** Every enum-backed field below is validated on input by name (e.g. `"status": "ATTENDED"`, case-insensitive) but is stored as a plain integer column and comes back in responses as that raw integer (e.g. `"status": 20`), not the name. This applies to `status`, `payment_status`, `unit_currency`, and `predeletable_state` everywhere they appear.

### Queue Status

Also the type of `predeletable_state` on [Channel](#channel).

| Value | Name          | Description                                 |
| ----- | ------------- | ------------------------------------------- |
| `0`   | `CANCELED`    | Marked as canceled; treated as soft-deleted |
| `10`  | `QUEUED`      | Newly entered into the queue                |
| `20`  | `ATTENDED`    | Being actively handled                      |
| `30`  | `PACKED`      | Order has been packed                       |
| `40`  | `READY`       | Ready for dispatch or collection            |
| `50`  | `DISPATCHING` | Out for delivery or being processed         |
| `60`  | `DONE`        | Fully completed                             |

Values are spaced by 10 to leave room for future in-between states without renumbering existing ones.

### Payment Status

| Value | Name      | Description                         |
| ----- | --------- | ----------------------------------- |
| `0`   | `UNPAID`  | No payment has been received        |
| `1`   | `PARTIAL` | A partial payment has been recorded |
| `2`   | `FULL`    | The queue total is fully paid       |

### Currency

Type of `unit_currency` on [Item](#item).

| Value | Name  |
| ----- | ----- |
| `100` | `IDR` |
| `200` | `USD` |

### Refund Status

| Value | Name       | Description                                             |
| ----- | ---------- | ------------------------------------------------------- |
| `0`   | `PENDING`  | Requested, awaiting staff review                        |
| `10`  | `ACCEPTED` | Accepted - counts against the payment's balance         |
| `20`  | `REJECTED` | Rejected - does not count against the payment's balance |

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

# Payment handlers only
crystal spec spec/apps/antrikan/handlers/payment/

# Refund handlers only
crystal spec spec/apps/antrikan/handlers/refund/

# Specific handler
crystal spec spec/apps/antrikan/handlers/space/qr_handler_spec.cr

# Join-by-code handler
crystal spec spec/apps/antrikan/handlers/space/join_handler_spec.cr
```

## Dependencies

- `qr-code` (spider-gazelle/qr-code) - QR code generation
- `stumpy_png` (stumpycr/stumpy_png) - PNG export for QR codes
- `aasm.cr` (veelenga/aasm.cr) — State machine management for Queue and QueuedItem
- `prorate-cr` (WJWH/prorate-cr) — Token-bucket rate limiting for the queue create endpoint
