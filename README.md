# GHL Workflow Toolkit — Claude Code plugin

A Claude Code plugin that turns any Claude session into a fully-equipped operator for **GoHighLevel** — managing contacts, calendars, opportunities, conversations, and especially **workflows** (where the public MCP descriptions are stale and produce broken automations).

Works with **any GHL account**, no vertical assumed.

Bundles:

- **GHL MCP server** ([BusyBee3333 fork](https://github.com/BusyBee3333/Go-High-Level-MCP-2026-Complete), patched for correct workflow chaining) — 834 tools across contacts, workflows, calendars, opportunities, messaging.
- **Canonical workflow schemas** as an auto-loaded skill — the MCP's own tool descriptions are incomplete; this skill has the verified-working JSON for `wait` (time + appointment), `if_else` 3-node branching, `sms`, `email`, `add_tag`.
- **API quirks reference** — `MONETARY → MONETORY`, what's UI-only (forms, pipelines, snapshots, SMS templates), rate limits, the Firebase auth flow.
- **`/ghl-workflow-toolkit:start`** — interactive setup wizard that captures your credentials step-by-step. **No technical knowledge needed.**
- **`/ghl-workflow-toolkit:refresh-firebase-token`** — to update the Firebase token when it expires (every few weeks).

---

## Installation

### Step 1 — Tell Claude to install the plugin

Open Claude Code (any directory) and paste:

```
Instalá el plugin ghl-workflow-toolkit desde
https://github.com/Luis24M/ghl-workflow-toolkit. Cuando termines de
instalarlo, corré /ghl-workflow-toolkit:start para arrancar el wizard.
```

Claude will run:
1. `/plugin marketplace add https://github.com/Luis24M/ghl-workflow-toolkit`
2. `/plugin install ghl-workflow-toolkit@ghl-workflow-toolkit`
3. `/ghl-workflow-toolkit:start`

The first two complete in seconds and don't require any credentials (the userConfig prompts are all optional — you can hit Enter on all of them).

### Step 2 — Follow the wizard

The `/ghl-workflow-toolkit:start` wizard will walk you through:

1. **PIT** (Private Integration Token) — it tells you exactly where to click in GHL to create one.
2. **Location ID** — it tells you how to read it from the URL.
3. **Firebase API key + refresh token** — it gives you a JS snippet to paste in DevTools and copy 2 lines back.
4. **Agency PIT** (optional) — skip if you don't have one.

At the end, the wizard writes everything to `~/.ghl-workflow-toolkit/credentials.env` (mode 600) and tells you to restart Claude Code.

### Step 3 — Restart Claude Code

Close and reopen.

The **first start** after credentials are set takes ~3 min: the MCP server self-bootstraps once (clones the upstream MCP, npm installs, applies the workflow-chaining patch, builds). Subsequent startups are instant.

### Step 4 — Test

In Claude Code:

> Listame las locations de mi GHL.

If it returns your locations, everything is wired up. 🎉

---

## How to use

Once installed, any Claude session in any directory can:

- Manage **contacts, opportunities, calendars, messaging** via 834 MCP tools.
- Create **workflows** correctly the first time — the schemas skill ensures Claude uses the right JSON shape, not the MCP's stale descriptions.
- Avoid asking GHL for things it doesn't expose (forms creation, pipeline creation, snapshot creation — all UI-only and documented in the quirks skill).

Example prompts:

> Create a contact (mario@example.com, +39 320 1234567), tag as `lead-new`, enroll in workflow `Welcome`.

> Build a workflow that waits 48 hours after appointment booking, sends an SMS reminder, and if no response after 2 hours sends an email follow-up.

> List all workflows referencing `{{ custom_values.link_calendar }}` and their last 5 executions.

---

## Re-configuring or recovering credentials

| When | Command |
|------|---------|
| Initial setup | `/ghl-workflow-toolkit:start` |
| Firebase token expired (401 errors) | `/ghl-workflow-toolkit:refresh-firebase-token` |
| Want to change PIT, Location, or anything else | Re-run `/ghl-workflow-toolkit:start` (overwrites the credentials file) |

Both wizards write to the same file: `~/.ghl-workflow-toolkit/credentials.env`. You can also edit it manually if you prefer.

---

## What works via API vs UI-only

**Works via MCP** (documented in `skills/ghl-workflows/schemas.md`):
- Contacts, custom fields, custom values, tags
- Calendars + appointments
- Opportunities + stage management
- Workflows: create + edit actions, enroll/remove contacts
- Email templates
- Conversations + messaging
- SMS / email / WhatsApp sending

**UI-only** (documented in `skills/ghl-workflows/quirks.md`):
- Forms creation (read works, write does not)
- Pipeline creation (stages can be edited, but new pipelines must be created in the UI)
- Snapshot creation
- Reliable snapshot push (the UI path is the supported one)
- SMS templates (use Custom Values + workflow actions instead)
- Workflow start triggers (create the actions via API, attach the trigger in the UI — ~10 seconds per workflow)

---

## What's in the plugin

```
ghl-workflow-toolkit/
├── .claude-plugin/
│   ├── plugin.json           # Manifest; userConfig is all optional
│   └── marketplace.json      # Single-plugin marketplace
├── .mcp.json                 # MCP server config (uses ${user_config.*} as fallback)
├── bin/
│   └── ghl-mcp-start.sh      # Smart wrapper: sources credentials, self-installs MCP
├── commands/
│   ├── start.md              # Setup wizard (THE main UX)
│   └── refresh-firebase-token.md  # Token rotation helper
├── patches/
│   └── workflow-builder-client.diff  # Fix for sequential next chaining
├── skills/
│   └── ghl-workflows/
│       ├── SKILL.md          # Skill manifest (auto-loaded)
│       ├── schemas.md        # Canonical workflow action schemas
│       └── quirks.md         # API quirks reference
├── LICENSE
└── README.md
```

---

## License

MIT
