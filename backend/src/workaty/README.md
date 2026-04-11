# Workaty Subapp

The backend system for Workaty - HR and ATS (Application Tracking System).

- [Entities](#entities)
  - [Candidate](#candidate)
  - [Degree](#degree)
  - [Team Division](#team-division)
  - [Employee](#employee)
  - [Email Template](#email-template)
- [Authorization](#authorization)
- [API Endpoints](#api-endpoints)
  - [Candidate CRUD](#candidate-crud)
  - [Degree CRUD](#degree-crud)
  - [Team Division CRUD](#team-division-crud)
  - [Employee CRUD](#employee-crud)
  - [Email Template CRUD](#email-template-crud)
- [Error Responses](#error-responses)
- [Running Tests](#running-tests)

## Entities

### Candidate

A job applicant being tracked through the hiring pipeline. Belongs to an organization and can have multiple degrees attached.

### Degree

An educational qualification attached to a candidate (e.g. Bachelor's in Computer Science).

### Team Division

A team or department within the organization. Can have designated leaders (employees) and members.

### Employee

A current employee of the organization. Can belong to multiple team divisions.

### Email Template

A reusable email template with a title and body content. Supports dynamic custom fields via the shared `FieldDefinition` / `FieldValue` system (resource type: `EMAIL_TEMPLATE`).

---

## Authorization

All endpoints require authentication via `Authorization: Bearer <jwt_token>` header.

Candidate, Employee, and Team Division mutation endpoints require the user to have at least `chief_staff` role or the `hr_staff` role.

Email Template endpoints require the `CAN_MANAGE_EMAIL_TEMPLATE` permission.

---

## API Endpoints

All paths are prefixed with `/workaty` (e.g., `POST /workaty/api/candidate`).

### Candidate CRUD

#### Create Candidate

```
POST /workaty/api/candidate
Content-Type: application/json

{
  "first_name": "Jane",
  "last_name": "Doe",
  "email": "jane@example.com",
  "phone": 628123456789,
  "fitness": "UNKNOWN",
  "note": "Referred by Alice"
}
```

| Field        | Required | Description                                            |
| ------------ | -------- | ------------------------------------------------------ |
| `first_name` | yes      | Candidate's first name (max 128 chars)                 |
| `last_name`  | no       | Candidate's last name (max 128 chars)                  |
| `email`      | no       | Email address — must be unique per organization        |
| `phone`      | no       | Phone number as integer                                |
| `fitness`    | no       | `UNKNOWN` (default), `GOOD_FIT`, or `BAD_FIT`          |
| `note`       | no       | Free-form notes                                        |

**Response (200 OK):**

```json
{
  "id": "abc123slug",
  "first_name": "Jane",
  "last_name": "Doe",
  "fitness": "UNKNOWN",
  "email": "jane@example.com",
  "phone": 628123456789,
  "degrees": []
}
```

#### Get Candidate

```
GET /workaty/api/candidate/<candidate_slug>
```

**Response (200 OK):** Candidate object (same shape as create response, includes nested `degrees` array).

#### Update Candidate

```
PATCH /workaty/api/candidate/<candidate_slug>/update
Content-Type: application/json

{
  "first_name": "Jane",
  "fitness": "GOOD_FIT"
}
```

**Supported Methods:** `PATCH`, `POST`

**Response (200 OK):** Updated candidate object.

#### Delete Candidate (Soft Delete)

```
DELETE /workaty/api/candidate/<candidate_slug>/delete
```

**Response (200 OK):** Deleted candidate object.

---

### Degree CRUD

Degrees are nested under candidates.

#### Create Degree

```
POST /workaty/api/candidate/<candidate_slug>/degrees
Content-Type: application/json

{
  "institution": "University of Example",
  "level": "BACHELOR",
  "major_field": "Computer Science",
  "obtained_at": "2020-06-15"
}
```

| Field         | Required | Description                                                        |
| ------------- | -------- | ------------------------------------------------------------------ |
| `institution` | yes      | Name of the institution (max 255 chars)                            |
| `level`       | yes      | `VOCATIONAL`, `BACHELOR`, `MASTER`, `DOCTORATE`, or `UNKNOWN`      |
| `major_field` | no       | Field of study (max 255 chars, e.g. "Computer Science")            |
| `obtained_at` | no       | Date the degree was obtained — format: `YYYY-MM-DD`                |

**Response (200 OK):**

```json
{
  "id": "hashedDegreeId",
  "institution": "University of Example",
  "level": "BACHELOR",
  "field": {
    "major": "Computer Science"
  },
  "obtained_at": "2020-06-15"
}
```

#### Update Degree

```
PATCH /workaty/api/candidate/<candidate_slug>/degrees/<degree_hashed_id>/update
Content-Type: application/json

{
  "level": "MASTER",
  "obtained_at": "2022-08-01"
}
```

**Supported Methods:** `PATCH`, `POST`

**Response (200 OK):** Updated degree object.

#### Delete Degree (Soft Delete)

```
DELETE /workaty/api/candidate/<candidate_slug>/degrees/<degree_hashed_id>/delete
```

**Response (200 OK):** Deleted degree object.

---

### Team Division CRUD

#### Create Team Division

```
POST /workaty/api/team_division/
Content-Type: application/json

{
  "name": "Engineering"
}
```

| Field  | Required | Description                                       |
| ------ | -------- | ------------------------------------------------- |
| `name` | yes      | Division name — must be unique per organization   |

**Response (200 OK):**

```json
{
  "id": "hashedDivisionId",
  "name": "Engineering",
  "leader_ids": []
}
```

`leader_ids` is an array of employee slugs designated as leaders of this division.

#### Update Team Division

```
PATCH /workaty/api/team_division/<team_division_hashed_id>/update
Content-Type: application/json

{
  "name": "Software Engineering"
}
```

**Supported Methods:** `PATCH`, `POST`

**Response (200 OK):** Updated team division object.

#### Delete Team Division (Soft Delete)

```
DELETE /workaty/api/team_division/<team_division_hashed_id>/delete
```

**Response (200 OK):** Deleted team division object.

---

### Employee CRUD

#### Create Employee

```
POST /workaty/api/employee/
Content-Type: application/json

{
  "first_name": "John",
  "last_name": "Smith",
  "email": "john@example.com",
  "phone": 628987654321,
  "note": "Joined 2024"
}
```

| Field        | Required | Description                                       |
| ------------ | -------- | ------------------------------------------------- |
| `first_name` | yes      | Employee's first name (max 128 chars)             |
| `last_name`  | no       | Employee's last name (max 128 chars)              |
| `email`      | no       | Email address — must be unique per organization   |
| `phone`      | no       | Phone number as integer                           |
| `note`       | no       | Free-form notes                                   |

**Response (200 OK):**

```json
{
  "id": "empSlugAbc",
  "first_name": "John",
  "last_name": "Smith",
  "email": "john@example.com",
  "phone": 628987654321,
  "note": "Joined 2024"
}
```

#### List Employees

Returns all employees and team divisions for the current user's organization.

```
GET /workaty/api/employee/index
```

**Response (200 OK):**

```json
{
  "employees": [
    {
      "id": "empSlugAbc",
      "first_name": "John",
      "last_name": "Smith",
      "email": "john@example.com",
      "phone": 628987654321,
      "note": "Joined 2024"
    }
  ],
  "team_divisions": [
    {
      "id": "hashedDivisionId",
      "name": "Engineering",
      "leader_ids": []
    }
  ]
}
```

#### Update Employee

```
PATCH /workaty/api/employee/<employee_slug>/update
Content-Type: application/json

{
  "first_name": "Jonathan",
  "note": "Promoted to lead"
}
```

**Supported Methods:** `PATCH`, `POST`

**Response (200 OK):** Updated employee object.

#### Delete Employee (Soft Delete)

```
DELETE /workaty/api/employee/<employee_slug>/delete
```

**Response (200 OK):** Deleted employee object.

---

### Email Template CRUD

Email Template endpoints accept native fields (`title`, `content`) alongside any dynamic custom fields defined for the `EMAIL_TEMPLATE` resource type.

#### Create Email Template

```
POST /workaty/api/email/template/
Content-Type: application/json

{
  "title": "Welcome Email",
  "content": "Dear {{name}}, welcome to our company!",
  "<custom_field_name>": "<value>"
}
```

| Field                 | Required | Description                                           |
| --------------------- | -------- | ----------------------------------------------------- |
| `title`               | yes      | Template title                                        |
| `content`             | yes      | Template body content                                 |
| `<custom_field_name>` | no       | Any extra fields defined via the Field Definition API |

**Response (200 OK):**

```json
{
  "records": {
    "EMAIL_TEMPLATE": [
      {
        "id": "hashedTemplateId",
        "title": "Welcome Email",
        "content": "Dear {{name}}, welcome to our company!"
      }
    ]
  },
  "fields": {
    "EMAIL_TEMPLATE": []
  }
}
```

The response includes any defined custom fields alongside the base template fields.

#### List Email Templates

```
GET /workaty/api/email/template/index
```

**Response (200 OK):** Same shape as create response, with `records.EMAIL_TEMPLATE` containing all templates for the organization.

#### Get Email Template

```
GET /workaty/api/email/template/<template_hashed_id>
```

**Response (200 OK):** Same shape as create response, with a single-element `records.EMAIL_TEMPLATE` array.

#### Update Email Template

```
PATCH /workaty/api/email/template/<template_hashed_id>/update
Content-Type: application/json

{
  "title": "Updated Welcome Email",
  "content": "Hi {{name}}, welcome!",
  "<custom_field_name>": "<value>"
}
```

**Supported Methods:** `PATCH`, `POST`

**Response (200 OK):** Updated template object (same shape as create response).

#### Delete Email Template (Soft Delete)

```
DELETE /workaty/api/email/template/<template_hashed_id>/delete
```

**Response (200 OK):** Deleted template object.

---

## Error Responses

| Status | Description                                    |
| ------ | ---------------------------------------------- |
| 400    | Not authenticated or malformed JSON body       |
| 403    | Not authorized (insufficient role)             |
| 404    | Resource not found                             |
| 422    | Validation error                               |

**Validation Error Example:**

```json
{
  "error": {
    "messages": [
      "First name: First name cannot be blank",
      "Email: has already been taken"
    ]
  }
}
```

---

## Running Tests

```bash
# All workaty tests
crystal spec spec/apps/workaty/

# Candidate handlers only
crystal spec spec/apps/workaty/handlers/candidate/

# Employee handlers only
crystal spec spec/apps/workaty/handlers/employee/
```
