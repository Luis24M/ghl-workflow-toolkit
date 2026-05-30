---
description: Print the JS snippet to re-capture the Firebase token when it expires.
---

The user's Firebase refresh token has expired (or they want to refresh it).

Print the following instructions verbatim:

---

**1.** Go to **app.gohighlevel.com** in your browser and make sure you are **logged in**.

**2.** Press **F12** (Mac: **Cmd+Option+I**) to open DevTools. Click the **Console** tab.

**3.** Paste this snippet and press Enter:

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

**4.** Copy the 2 values printed.

**5.** Reply with them and I will update `~/.claude/settings.json` with the new `firebase_refresh_token` (and `firebase_api_key` if it changed) for the `ghl-italian-dental` plugin.

Then restart Claude Code so the MCP server picks up the new credentials.
