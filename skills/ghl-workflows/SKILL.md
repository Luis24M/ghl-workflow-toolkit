---
name: ghl-workflows
description: Canonical schemas and API quirks for GoHighLevel workflows, custom fields, pipelines, calendars, and templates. Read this skill BEFORE creating or updating any workflow, custom field, or sub-account configuration via the GHL MCP — the MCP's own tool descriptions are incomplete and produce empty/broken schemas if used as-is. Covers wait actions (time vs appointment), if_else 3-node branching, email/SMS, MONETARY→MONETORY mapping, what is UI-only (forms, pipelines create, snapshot push), Firebase auth and rate limits.
---

# GoHighLevel — canonical schemas & quirks

The BusyBee3333 MCP exposes 834 tools but its descriptions are incomplete or stale for several critical schemas. Before invoking workflow / custom-field / location operations, consult the relevant reference file below.

## Reference files

- **`schemas.md`** — canonical workflow action schemas (wait/time, wait/appointment, if_else 3-node pattern, sms, email, add_tag) with verified-working JSON payloads. Read this BEFORE calling `ghl_create_workflow` or `ghl_update_workflow_actions`.

- **`quirks.md`** — non-obvious API behaviors: MONETARY → MONETORY typo, custom_field options must be flat strings, rate limit ~25 req/min, what's UI-only (forms, pipeline creation, snapshot creation/push, sub-account creation), timezone defaulting to browser locale on sub-account creation, list of read-only fields the `PUT /locations/{id}` endpoint rejects, and Firebase token capture procedure.

## When to read

- User asks to **create a workflow** → read `schemas.md` (decision-node + branch-yes + branch-no triplet, `convertToMultipath: false`, `appointmentStartAfter.distributed`).
- User asks to **create custom fields** → read `quirks.md` MONETORY + options sections.
- User asks to **push a snapshot** or **create a pipeline** → read `quirks.md` UI-only section before promising it works via API.
- MCP returns `401 Authentication Failed` or unexpected `500 NOT_FOUND on triggers/` → read `quirks.md` Firebase auth section.

## Critical patterns

**1. Workflow start triggers cannot be attached via API.** Create the workflow actions with the MCP, then tell the user to add the trigger manually in the UI (one click per workflow). See `quirks.md` for the underlying Firestore bug.

**2. Wait actions need `convertToMultipath: false` and `transitions: []`.** Without those, the UI rejects the workflow with "this action does not support branching."

**3. `if_else` is THREE nodes, not one.** A decision node + branch-yes + branch-no. Each branch needs `next: [childId]` even though the child's `parentKey` already points back. See `schemas.md` for the exact 3-node payload.

**4. Email `attributes.html`, not `body`.** Plain-text bodies are ignored in the UI.

**5. Trust the project's `~/.claude/projects/<this-project>/memory/` directory** if it exists — it holds the user's previous quirks/learnings beyond what this skill bundles.
