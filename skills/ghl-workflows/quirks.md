# GoHighLevel API quirks reference

Non-obvious behaviors and limitations discovered the hard way. Consult before promising a feature works or debugging a confusing error.

---

## 1. Sub-account timezone defaults to **browser locale**, not country

When you create a sub-account from the agency UI, GHL sets the timezone of the **agency owner's browser** as the default — ignoring the country you selected. A client based in country A created from a browser in country B will end up with country B's timezone. **Always fix after creating.**

Fix via PUT `/locations/{id}` with payload filtered (see #2).

---

## 2. `PUT /locations/{id}` rejects read-only fields

Returns `422` if the payload contains any of: `id`, `firstName`, `lastName`, `business`, `dateAdded`, `snapshotId`, `settings.contactUniqueIdentifiers`. You must strip them from the GET response before re-PUTting.

---

## 3. No `/me` or `/companies/me` endpoints in GHL v2

The only reliable way to discover the `companyId` from an opaque PIT is `GET /locations/search` — each location includes its `companyId`. PITs are opaque tokens (not JWTs), so they cannot be decoded locally.

---

## 4. Custom fields: `MONETARY` → `MONETORY` (sic)

The API rejects `dataType: "MONETARY"` (the correct spelling) and requires `"MONETORY"` (typo in GHL's backend). Apply the mapping when building payloads.

---

## 5. Custom fields: `options` must be flat strings

```json
// WRONG — returns 400 "v.trim is not a function"
"options": [{ "key": "yes", "label": "Sì" }]

// RIGHT
"options": ["Sì", "No", "Altro"]
```

GHL derives keys internally from the labels.

---

## 6. Rate limit ~25 req/min for mutations

Empirically, sustained POSTs hit a 429 around request 25. Honor `Retry-After` headers. For large syncs (50+ entities), throttle to ~20 req/min sustained.

---

## 7. UI-only operations (no API exposure)

These **cannot** be done via the API or the MCP — they are UI-only and will silently fail or return 401/404:

- **Forms creation** — `POST /forms/` returns `401 "not yet supported by IAM"` even with `forms.write`. Forms can be READ via API but only created manually in the UI.
- **Pipeline creation** — `POST /opportunities/pipelines` returns 401 "not authorized for this scope" with every scope combination tried. Confirmed missing from the BusyBee3333 MCP's 834 tools. There is an open entry in the GHL Ideas Portal for this.
- **Snapshot creation** — only possible via the UI (right-click a sub-account → Save as Snapshot).
- **Snapshot push** — `push_snapshot_to_subaccounts` exists in the MCP but is unreliable; the UI flow is the supported path.
- **Sub-account creation** — `create_location` works but with quirks (timezone bug #1, plus some sub-account types only creatable from UI).
- **SMS templates** — `POST /locations/{id}/templates/sms` returns 404. SMS templates must be created manually. Workaround: use `custom_values` + workflow SMS actions with `{{ custom_values.<key> }}`.

---

## 8. Workflow start triggers — unfixable via API

Even with the patched MCP and full Firebase auth, attempting to attach a trigger to a workflow fails with:

```
500 PUT /{locationId}/{workflowId}
"5 NOT_FOUND: No document to update:
projects/highlevel-backend/databases/(default)/documents/triggers/{triggerId}"
```

The backend expects a trigger document to already exist via a separate endpoint that is not exposed publicly. **Pragmatic workaround:** create workflows with their actions via MCP, then guide the user to attach the start trigger manually in the UI (~10 sec each).

---

## 9. Firebase auth — when, why, how

The PIT alone is NOT enough to create workflows. The MCP requires `GHL_FIREBASE_API_KEY` + `GHL_FIREBASE_REFRESH_TOKEN` to authenticate against the private workflow backend (`backend.leadconnectorhq.com`).

**Capture procedure** — paste into DevTools Console while logged into `app.gohighlevel.com`:

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
          console.log('apiKey:', v.apiKey);
          console.log('refreshToken:', v.stsTokenManager.refreshToken);
          return;
        }
      }
    };
  };
})();
```

**Token lifetimes:**
- `firebase_api_key`: public, same for every GHL user worldwide. Constant.
- `firebase_refresh_token`: per-user, lasts **weeks**. The MCP exchanges it for short-lived (1h) access tokens automatically via `securetoken.googleapis.com`.
- **NOT** the same as `localStorage.refreshedToken` (which is a v2 JWT, not a Firebase refresh token, and does not work for this purpose).

When the refresh token expires (typically after logout or extended inactivity), the MCP starts returning 401s. Re-capture and update the plugin config via `/refresh-firebase-token`.

---

## 10. Two PITs in `.env`: agency vs sub-account

Most operations work with the sub-account PIT. Use the agency PIT only for:

- Pushing snapshots to sub-accounts
- Listing all locations under the agency
- Creating new sub-accounts
- Agency-level user/role management

If `GHL_AGENCY_API_KEY` is not set, agency-level tools will return 401. That is expected — the plugin treats agency_pit as optional.

---

## 11. Custom Values for per-client URL config

Instead of hardcoding per-client URLs (calendar links, review forms, public booking pages) in workflow templates, create **Custom Values** at the location level and reference them as `{{ custom_values.<key> }}` in SMS/email actions.

This makes a snapshot reusable across clients: when deploying to a new client, you only fill in the Custom Values per client, and every workflow/template that references them updates automatically.

Use `create_location_custom_value` / `get_location_custom_values` / `update_location_custom_value` tools.
