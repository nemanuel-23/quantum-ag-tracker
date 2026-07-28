# Quantum Ag Tracker — How It's Built & Deployed

Reference for how the app is structured and how updates reach the live site.
Read this before touching the deploy flow.

---

## The app in one paragraph

A single self-contained `index.html` (~3,000 lines): React 18 via CDN, compiled
in the browser by Babel-standalone, no build step. All app state lives in one
`data` object mirrored to browser `localStorage` and synced to a single Supabase
row (`app_data`). Hosted on **GitHub Pages** at the custom domain
**orders.quantumag.farm**.

- **Repo:** `https://github.com/nemanuel-23/quantum-ag-tracker`
- **Live:** `https://orders.quantumag.farm/` (served from repo root `index.html`)
- **Preview:** `https://orders.quantumag.farm/preview/` (served from `preview/index.html`)
- **Custom domain:** set by the `CNAME` file in the repo root — **never delete it.**

---

## Repo layout

```
index.html            ← LIVE app (what the team uses)
preview/index.html    ← PREVIEW app (staging for the next version)
CNAME                 ← custom domain; deleting it breaks orders.quantumag.farm
README.md
supabase-setup.sql    ← one-time DB schema (already applied)
docs/
  WORKLOG.md          ← running change log (newest first)
  DEPLOYMENT.md       ← this file
```

Local-only (gitignored, never pushed): the `*.command` scripts and the `_*.html`
working copies.

---

## The deploy scripts (double-click, no terminal)

Numbered so the order is obvious. Each prints what it's doing and pauses at the end.

| Script | Purpose | Changes GitHub? |
|--------|---------|-----------------|
| `1 - Check GitHub First.command` | Read-only status: history, CNAME, divergence | No |
| `2 - Publish Update.command` | Push root `index.html` straight to live | Yes (live) |
| `3 - Export GitHub Version.command` | Pull GitHub's current files down to compare | No |
| `4 - Deploy Preview.command` | Publish `preview/index.html`, leave live alone | Yes (preview only) |
| `5 - Fix and Deploy Preview.command` | Same as 4 but recovers from a rejected push | Yes (preview only) |

**None of them force-push.** If GitHub has commits the local repo doesn't, the
push is rejected and the script stops rather than overwrite anything.

### Typical flow now
1. Claude edits the app and leaves the new build in `_v6.0-claude-build.html` (or
   directly in `preview/index.html`).
2. You double-click **`4`** (or **`5`** if a push was just rejected) to publish preview.
3. You test at `/preview/`.
4. When approved, promote preview → live (promote script provided at that point).

### The old way (retired)
Previously: copy the whole `index.html` and paste it into the GitHub web editor.
No diff, no undo, easy to truncate. The scripts replace this.

---

## Auth — the magic-link quirk (important)

Login uses Supabase magic links. `emailRedirectTo` is **hardcoded** to
`https://orders.quantumag.farm` (root), so a magic link **always lands on the live
site**, never on `/preview/` or a local `file://`.

**Why preview login still works:** Supabase stores the session in `localStorage`,
which is shared across all paths on the same domain. So:

1. Open the magic-link email **in the same browser** you'll test with.
2. Clicking it signs you in on the live site.
3. Then just change the URL to `/preview/` — you're already signed in.

**Consequences:**
- You cannot log in from a `file://` copy on your desktop. Test via `/preview/`.
- Open the email link on the **same device/browser** as your testing.
- To make preview's magic link return to `/preview/` directly, `emailRedirectTo`
  would need to be dynamic (`window.location.origin + pathname`) **and** the URL
  allowlisted in Supabase → Authentication → URL Configuration. Not done — the
  shared-session trick is simpler for a temporary preview.

---

## Data & safety

- **One shared database.** Live and preview both read/write the same Supabase
  row. Testing in preview is **not** isolated from live data.
- **Back up before serious testing:** live site → Settings → **Export Data (JSON)**.
  Restore via Settings → Import.
- The Supabase URL and anon key are in `index.html`. That's expected — the anon
  key is public by design; row-level security governs access.
- Photo/video attachments on deliveries are stored **locally only**; they're
  stripped before the Supabase push (too large). Notes and signatures do sync.

---

## Git recovery notes

- Local `main` is now a true continuation of `origin/main` — normal `push`/`pull`.
- If a script reports a **stale lock** (`.git/HEAD.lock` etc.), it's from an
  interrupted git run; the scripts clear these automatically when no git process
  is active.
- If a push is ever **rejected (non-fast-forward)**, GitHub has something local
  doesn't. Run `1 - Check GitHub First` and send Claude the output. **Do not
  force-push** — the CNAME and history live only on GitHub.
