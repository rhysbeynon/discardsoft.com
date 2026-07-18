# discardsoft.com

Landing page for **Discardsoft, LLC** — styled after the blue BIOS interface of our game *Twin Rivers*.

The whole site is a single self-contained [`index.html`](index.html) (no build step, no JavaScript). Hosted on GitHub Pages.

## Local preview

No runtimes needed — either open `index.html` directly in a browser, or serve it over HTTP with the bundled PowerShell static server:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File scripts\serve.ps1 -Port 8080
```

then visit <http://localhost:8080>.
