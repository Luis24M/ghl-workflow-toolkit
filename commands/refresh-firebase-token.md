---
description: Refresh the Firebase token in ~/.ghl-workflow-toolkit/credentials.env when it expires (typically every few weeks). Use this when the MCP starts returning 401 errors.
---

The user's Firebase refresh token has expired or they want to update it.

## Steps

### 1. Explain and give the snippet

Print:

> 🔁 **Refresh del token de Firebase**
>
> El token de Firebase suele durar **semanas**, pero a veces vence (sobre todo si te deslogueaste de GHL hace rato). Si Claude te empezó a tirar errores 401, esto lo arregla en 1 minuto.
>
> **Pasos:**
>
> 1. Andá a **app.gohighlevel.com** logueado.
> 2. Apretá **F12** (Mac: **Cmd + Option + I**) → pestaña **Console**.
> 3. Pegá esto y Enter:
>
> ```javascript
> (() => {
>   const req = indexedDB.open('firebaseLocalStorageDb');
>   req.onsuccess = () => {
>     const all = req.result.transaction('firebaseLocalStorage', 'readonly')
>       .objectStore('firebaseLocalStorage').getAll();
>     all.onsuccess = () => {
>       for (const item of all.result) {
>         const v = item.value ?? item;
>         if (v?.stsTokenManager?.refreshToken) {
>           console.log('FIREBASE_API_KEY=' + v.apiKey);
>           console.log('FIREBASE_REFRESH_TOKEN=' + v.stsTokenManager.refreshToken);
>           return;
>         }
>       }
>     };
>   };
> })();
> ```
>
> 4. Te va a imprimir 2 líneas. **Pegamelas acá** ⬇️.

Wait for the user's reply.

### 2. Parse and update credentials.env

Parse the 2 values from the user's response. They may paste as `KEY=value` lines, or just the 2 raw strings — handle both.

Validate:
- `FIREBASE_API_KEY` starts with `AIzaSy` and is ~39 chars
- `FIREBASE_REFRESH_TOKEN` is >100 chars

If validation fails, ask them to re-run the snippet and paste again.

Use the **Bash** tool to update the credentials file **in place**, preserving the other values:

```bash
if [[ ! -f "$HOME/.ghl-workflow-toolkit/credentials.env" ]]; then
  echo "ERROR: credentials.env not found. Run /ghl-workflow-toolkit:start first." >&2
  exit 1
fi

# Backup
cp "$HOME/.ghl-workflow-toolkit/credentials.env" \
   "$HOME/.ghl-workflow-toolkit/credentials.env.bak"

# Replace the two Firebase lines
sed -i.tmp \
  -e 's|^GHL_FIREBASE_API_KEY=.*|GHL_FIREBASE_API_KEY="<new_api_key>"|' \
  -e 's|^GHL_FIREBASE_REFRESH_TOKEN=.*|GHL_FIREBASE_REFRESH_TOKEN="<new_refresh>"|' \
  "$HOME/.ghl-workflow-toolkit/credentials.env"
rm -f "$HOME/.ghl-workflow-toolkit/credentials.env.tmp"
echo "Firebase tokens updated."
```

Replace `<new_api_key>` and `<new_refresh>` with the captured values (carefully escaped).

### 3. Finish

Print:

> ✅ **Tokens actualizados.**
>
> Ahora **reiniciá Claude Code** (cerrá esta sesión y volvelo a abrir) para que el MCP server lea las credenciales nuevas.
>
> Después del reinicio probá una operación que antes fallaba.
