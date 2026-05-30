# Canonical workflow action schemas

All schemas below have been **verified against the GHL UI** by reverse-engineering. Use these exact shapes when calling `ghl_create_workflow` or `ghl_update_workflow_actions` — the MCP tool descriptions are stale.

---

## 1. SMS / WhatsApp action

```json
{
  "type": "sms",
  "name": "Send SMS",
  "attributes": {
    "body": "Ciao {{contact.first_name}}!",
    "attachments": []
  }
}
```

Merge tags: `{{contact.first_name}}`, `{{contact.last_name}}`, `{{contact.email}}`, `{{contact.phone}}`, `{{location.name}}`, `{{location.address}}`. Per-client config via `{{ custom_values.<key> }}`.

---

## 2. Email action

```json
{
  "type": "email",
  "name": "Send Email",
  "attributes": {
    "subject": "Welcome",
    "html": "<p>Ciao {{contact.first_name}}…</p>",
    "attachments": []
  }
}
```

**Use `html`, not `body`.** Plain text in `body` is ignored.

---

## 3. Wait — Time Delay

```json
{
  "type": "wait",
  "name": "Wait 48 hours",
  "cat": "",
  "attributes": {
    "type": "time",
    "startAfter": { "type": "hours", "value": 48, "when": "after" },
    "name": "Wait 48 hours",
    "cat": "",
    "isHybridAction": true,
    "hybridActionType": "wait",
    "convertToMultipath": false,
    "transitions": []
  }
}
```

**Critical fields:**
- `convertToMultipath: false` — without this the UI rejects the chained next.
- `transitions: []` — must be present.
- `isHybridAction: true` and `hybridActionType: "wait"` — both required.
- `startAfter.type` is **singular** for hours (`"hour"` also accepted) but **plural** for minutes/days (`"minutes"`, `"days"`). The UI is picky.

---

## 4. Wait Until Appointment (X time before/after a booked appointment)

```json
{
  "type": "wait",
  "name": "Wait until 2h before appointment",
  "cat": "",
  "attributes": {
    "type": "appointment",
    "name": "Wait until 2h before appointment",
    "cat": "",
    "appointmentStartAfter": {
      "when": "before",
      "type": "minutes",
      "value": 120,
      "distributed": { "months": 0, "days": 0, "hours": 2, "minutes": 0 }
    },
    "appointmentCondition": "skip",
    "isHybridAction": true,
    "hybridActionType": "wait",
    "convertToMultipath": false,
    "transitions": []
  }
}
```

**Note:** `value` is total **minutes**; `distributed` is the human-readable breakdown the UI displays. Both must be consistent.

---

## 5. Add Contact Tag

```json
{
  "type": "add_contact_tag",
  "name": "Tag as Promotore",
  "attributes": { "tags": ["promotore-nps"] }
}
```

Tag names must be lowercase-kebab and must already exist in the location (create them via `create_location_tag` or sync script first).

---

## 6. `if_else` — three-node branching pattern

A single decision is represented as **three actions**: a `condition-node`, a `branch-yes`, and a `branch-no`. Each action inside a branch references its branch node via `parentKey`.

### Decision node

```json
{
  "id": "<decisionId>",
  "type": "if_else",
  "name": "If NPS >= 9",
  "cat": "conditions",
  "nodeType": "condition-node",
  "parentKey": "<previousActionId>",
  "next": ["<branchYesId>", "<branchNoId>"],
  "attributes": {
    "currentRecipeType": "CUSTOM",
    "branches": [
      {
        "id": "<branchYesId>",
        "name": "Promotore",
        "segments": [
          {
            "__segmentId": "<uuid>",
            "operator": "and",
            "conditions": [
              {
                "conditionType": "contact_detail",
                "conditionSubType": "<customFieldId>",
                "conditionOperator": ">=",
                "conditionValue": "9",
                "__conditionId": "<uuid>",
                "ifElseNodeId": "",
                "__customFieldType__": "standard",
                "isWait": false
              }
            ]
          }
        ],
        "operator": "and",
        "showErrors": false
      }
    ],
    "operator": "and",
    "if": true,
    "conditionName": "If NPS >= 9",
    "version": 2,
    "noneBranchName": "Else"
  }
}
```

### Branch YES

```json
{
  "id": "<branchYesId>",
  "type": "if_else",
  "nodeType": "branch-yes",
  "parent": "<decisionId>",
  "sibling": ["<branchNoId>"],
  "next": ["<firstActionInsideYesBranchId>"],
  "attributes": {
    "if": false,
    "conditionName": "Promotore",
    "operator": "and",
    "branches": []
  }
}
```

### Branch NO

```json
{
  "id": "<branchNoId>",
  "type": "if_else",
  "nodeType": "branch-no",
  "parent": "<decisionId>",
  "sibling": ["<branchYesId>"],
  "next": ["<firstActionInsideNoBranchId>"],
  "attributes": { "else": true }
}
```

### Action inside a branch

```json
{
  "id": "<smsId>",
  "type": "sms",
  "parentKey": "<branchYesId>",
  "attributes": { "body": "…", "attachments": [] }
}
```

**Critical**: each branch node needs `next: [childId]` **in addition** to the child's `parentKey`. Without `next` on the branch, the UI renders an empty branch terminating immediately at FINAL, even though the child actions exist in the DB.

For 3+ branches, nest `if_else` inside another `if_else`.

---

## 7. Sequential chaining (no branching)

For a linear chain `A → B → C`, set `next` as a **string**, not an array:

```json
{ "id": "A", "next": "B", ... }
{ "id": "B", "parentKey": "A", "next": "C", ... }
{ "id": "C", "parentKey": "B", ... }
```

If you set `next: ["B"]` (array of one), the UI treats it as a branching point and rejects subsequent Time Delay waits.

---

## 8. Start trigger — DO NOT attempt via API

Workflow start triggers (`contact_tag`, `contact_created`, `appointment_status`, etc.) **cannot be created via API** — even with full Firebase auth. The backend always responds:

```
500 NOT_FOUND: No document to update: triggers/<triggerId>
```

Pragmatic workflow:

1. Create the workflow with actions via MCP.
2. Tell the user to open the workflow in the UI and add the start trigger (~10 sec).

95% of the build is still automated.
