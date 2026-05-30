# GHL Workflow Toolkit — Claude Code plugin

A Claude Code plugin that turns any Claude session into a fully-equipped operator for **GoHighLevel** — managing contacts, calendars, opportunities, conversations, and especially **workflows** (where the public MCP descriptions are stale and produce broken automations).

Works with **any GHL account**, no vertical assumed.

Bundles:

- **GHL MCP server** ([BusyBee3333 fork](https://github.com/BusyBee3333/Go-High-Level-MCP-2026-Complete), patched for correct workflow chaining) — 834 tools across contacts, workflows, calendars, opportunities, messaging.
- **Canonical workflow schemas** as an auto-loaded skill — the MCP's own tool descriptions are incomplete; this skill has the verified-working JSON for `wait` (time + appointment), `if_else` 3-node branching, `sms`, `email`, `add_tag`.
- **API quirks reference** — `MONETARY → MONETORY`, what's UI-only (forms, pipelines, snapshots, SMS templates), rate limits, the Firebase auth flow.
- **`/refresh-firebase-token` command** — to update Firebase tokens when they expire (every few weeks).

---

## Installation (3 minutes)

### Step 1 — Capture your Firebase tokens

This is the **only manual step**. Claude cannot do this for you because it needs your logged-in GHL browser session.

1. Open `app.gohighlevel.com` in your browser and **log in**.
2. Press **F12** (Mac: **Cmd+Option+I**). Click the **Console** tab.
3. Paste this snippet and press Enter:

```javascript
(() => {
  const req = indexedDB.open('firebaseLocalStorageDb');
  req.onsuccess = () => {
    const all = req.result.transaction('firebaseLocalStorage', 'readonly')
      .objectStore('firebaseLocalStorage').getAll();
    all.onsuccess = () => {
      for (const item of all.result) {
        const v = item.value ?? item;
        if (v?.stsTokenManager?.refreshToken) {
          console.log('FIREBASE_API_KEY=' + v.apiKey);
          console.log('FIREBASE_REFRESH_TOKEN=' + v.stsTokenManager.refreshToken);
          return;
        }
      }
    };
  };
})();
```

4. Copy the two `FIREBASE_…=` lines printed.

### Step 2 — Tell Claude to install the plugin

Open Claude Code and paste this (substituting your actual values):

```
Install the ghl-workflow-toolkit plugin from
https://github.com/Luis24M/ghl-workflow-toolkit
with these credentials:

PIT=pit-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
LOCATION_ID=<your-sub-account-location-id>
FIREBASE_API_KEY=AIzaSy...
FIREBASE_REFRESH_TOKEN=AMf-vBy...
```

Claude will:
1. Run `/plugin marketplace add https://github.com/Luis24M/ghl-workflow-toolkit`
2. Run `/plugin install ghl-workflow-toolkit@ghl-workflow-toolkit`
3. Write the credentials to `~/.claude/settings.json` under the plugin's `userConfig`.
4. Tell you to restart Claude Code.

### Step 3 — Restart Claude Code

Close and reopen. On first start, the MCP server self-bootstraps once (~3 min: clones the upstream MCP, npm installs, applies the workflow-chaining patch, builds). Subsequent startups are instant.

### Step 4 — Test

In Claude Code:

> List the locations under my GHL agency.

If it returns your locations, everything is wired up.

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

## When the Firebase token expires (every few weeks)

You will start seeing 401 errors. Run:

```
/refresh-firebase-token
```

Follow the steps it prints (same as Step 1 above). Paste the new values and Claude updates `~/.claude/settings.json`. Restart and you are back.

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
│   ├── plugin.json           # Manifest + userConfig for credentials
│   └── marketplace.json      # Single-plugin marketplace
├── .mcp.json                 # MCP server config (uses ${user_config.*})
├── bin/
│   └── ghl-mcp-start.sh      # Smart wrapper: self-installs the MCP on first run
├── commands/
│   └── refresh-firebase-token.md
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
