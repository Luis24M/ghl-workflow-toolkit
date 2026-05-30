# GHL Italian Dental — Claude Code plugin

A Claude Code plugin that turns any Claude session into a fully-equipped operator for **GoHighLevel** — focused on Italian dental clinics but reusable for any GHL workflow project.

Bundles:

- **GHL MCP server** (BusyBee3333 fork, patched for correct workflow chaining) — 834 tools across contacts, workflows, calendars, opportunities, messaging, etc.
- **Canonical workflow schemas** as an auto-loaded skill — the MCP's own descriptions are stale, this skill has the verified-working JSON for `wait`, `if_else`, `sms`, `email`, etc.
- **API quirks reference** — `MONETARY → MONETORY`, what's UI-only (forms, pipelines, snapshots), rate limits, Firebase auth.
- **`/refresh-firebase-token` command** — for when the Firebase token expires.

---

## Installation (3 minutes)

### Step 1 — Capture your Firebase tokens

This is the **only manual step**. Claude cannot do this for you because it needs your logged-in browser session.

1. Open `app.gohighlevel.com` in your browser and log in.
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
Install the ghl-italian-dental plugin from
https://github.com/luismorales/ghl-italian-dental
with these credentials:

PIT=pit-xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
LOCATION_ID=Fd1bmlwGuN8ien3uAbIc
FIREBASE_API_KEY=AIzaSy...
FIREBASE_REFRESH_TOKEN=AMf-vBy...
```

Claude will:
1. Run `/plugin marketplace add https://github.com/luismorales/ghl-italian-dental`
2. Run `/plugin install ghl-italian-dental@ghl-italian-dental`
3. Write the credentials to `~/.claude/settings.json` under the plugin's `userConfig`.
4. Tell you to restart Claude Code.

### Step 3 — Restart Claude Code

Close and reopen. The plugin's MCP server runs once to self-bootstrap (~3 min: clones the MCP repo, npm installs, applies patch, builds). Subsequent startups are instant.

### Step 4 — Test

In Claude Code:

> List the locations under my GHL agency.

If it returns your locations, everything is wired up.

---

## How to use

Once installed, any Claude session in any directory can:

- Manage contacts, opportunities, calendars, messaging via 834 MCP tools.
- Create workflows correctly the first time (the schemas skill ensures Claude uses the right JSON shape, not the MCP's stale descriptions).
- Avoid asking GHL for things it doesn't expose (forms creation, pipeline creation, snapshot creation — all UI-only and documented in the quirks skill).

Example prompts:

> Create a new contact named Mario Rossi (mario@studio.it, +39 320 1234567), tag him as `lead-nuovo`, and enroll him in the "Nuovo Lead" workflow.

> Build a workflow that waits 48 hours after appointment booking, sends an SMS reminder, and if no response after 2h sends an email follow-up.

> List all workflows that mention `custom_values.link_calendario` and show me their last 5 executions.

---

## When the Firebase token expires (every few weeks)

You will start seeing 401 errors. Run:

```
/refresh-firebase-token
```

Follow the steps it prints — same as Step 1 above. Paste the new values and Claude updates `~/.claude/settings.json`. Restart and you are back.

---

## What is included vs not

**Included** (works via API + MCP):
- Contacts, custom fields, custom values, tags
- Calendars + appointments
- Opportunities + pipeline stage management
- Workflows (create actions, enroll/remove contacts)
- Email templates
- Conversations + messaging

**Not included** (UI-only — documented in `quirks.md`):
- Forms creation
- Pipeline creation (stages can be updated via API, but new pipelines must be created in the UI)
- Snapshot creation
- Reliable snapshot push (manual UI push is the supported path)
- SMS templates (use `custom_values` instead)

---

## License

MIT
