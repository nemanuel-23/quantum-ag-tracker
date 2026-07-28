# Quantum Ag Tracker — Work Log

Running log of changes, newest first. One entry per working session.
Claude reads the top entry at the start of each session to catch up.

> **How this stays current:** at the end of every session, Claude appends a new
> entry to the top of this file. The deploy/publish scripts commit `docs/` along
> with code, so the log travels with the project on GitHub.

---

## Session 3 — 2026-07-21 · Promote v6.0 to LIVE

**What changed**
- Nick reviewed v6.0 in preview (incl. the rebuilt New Delivery flow) — looked good.
- Live data backed up to JSON beforehand.
- Added `6 - Promote v6.0 to Live.command`: copies `preview/index.html` → root
  `index.html`, protects CNAME, pushes fast-forward. Requires typing `GO` to run.
- Ran the promote → **live site is now v6.0**.

**State at end of session**
- Live site: **v6.0** at `https://orders.quantumag.farm/`.
- Preview: **v6.0** at `/preview/` (now matches live; free to use as the next staging slot).
- Rollback: previous **v5.1** preserved in git history (commit `ac24bb1`) and in
  `_v5.1-local-base.html`.

**Clarified this session**
- Preview must be tested via the **deployed URL** (`/preview/`), never by opening
  the local `preview/index.html` file — a `file://` page can't share the login
  session and its magic link always redirects to live. (Recurring confusion; now
  documented here and in DEPLOYMENT.md.)

**Open items**
- Watch for any issues on live now that real users are on v6.0.
- Photo/video delivery attachments remain local-only (stripped before Supabase sync) —
  unchanged, pre-existing behavior.

---

## Session 2 — 2026-07-21 (later) · Documentation & process

**What changed**
- Added this work-log system (`docs/WORKLOG.md`) and a process guide
  (`docs/DEPLOYMENT.md`).
- Updated the deploy scripts so `docs/` is committed on every push — the log
  can't drift out of sync with the code.

**State at end of session**
- Live site: **v5.1** at `https://orders.quantumag.farm/` (unchanged).
- Preview: **v6.0** at `https://orders.quantumag.farm/preview/` — awaiting Nick's review.
- Local repo synced with GitHub (`origin/main`), histories reconciled.

**Open items**
- Nick to review v6.0 in preview, focusing on the **New Delivery** flow (rebuilt
  wholesale, never executed by Claude).
- Back up live data before heavy preview testing (Settings → Export Data JSON) —
  preview shares the same Supabase database.
- When approved: promote preview → live (a promote script will be provided).

---

## Session 1 — 2026-07-21 · v6.0 build (14 features + 10 defect fixes)

Built `index.html` from v5.1 (1,771 lines) → **v6.0** (2,964 lines). Deployed to
`/preview/` only; live left on v5.1.

### Production defects fixed (root causes)

1. **Delivery quantity hard-clamped.** Inputs had `max={remaining}` + `Math.min`,
   making over-delivery impossible; Inventory further hid it with
   `fmt(Math.max(0, snd))`. Both removed — negative "sold, not delivered" is now
   the weigh-back signal.
2. **Group delivery discarded typed quantities.** `save()`'s group branch
   recomputed each order's remaining and wrote *that*, ignoring the operator's
   entries, then marked the order paid. Every group delivery recorded as full.
   Replaced with one allocation path shared by all delivery modes.
3. **Delivery picker filter inverted** (`status!=='paid' || !fullyDelivered`).
   `||` short-circuited, so fully-delivered orders still appeared. Now purely
   quantity-driven.
4. **Inventory math mixed fiscal years.** Selectors summed *all* orders while the
   UI scoped to one year → last season's orders subtracted from this season's
   stock. Now year-scoped. A single non-numeric qty also NaN-poisoned (or
   string-concatenated) a whole column; every reduce now runs through `num()`.
5. **Supabase sync could drop a local write.** `isRemoteUpdate` was cleared in
   the push effect, but an identical remote payload made React bail out of the
   render, leaving the flag set — so the *next* real edit was swallowed. Flag is
   now cleared by the code that sets it; writes debounced 800 ms.
6. **Frozen first column** wasn't possible with `border-collapse:collapse`
   (borders drop off sticky cells). Switched affected tables to
   `border-collapse:separate` with box-shadow borders + opaque backgrounds.
7. **Matrix row click opened the wrong order.** Rows aggregate a customer's
   orders but `.find()` returned the first. Opens directly when unambiguous,
   else prompts.
8. **Pump returns were boolean** — "5 out, 3 back" was unrepresentable. Promoted
   to quantities, with a migration for existing records.
9. **Stale-closure effects** in the delivery modal intermittently rendered an
   empty product list.
10. **Undated orders vanished** (regression caught by the test harness). Seed row
    o18 (Ross Janak, 265 units) has a blank date → `'Undated'` pseudo-year, which
    year-scoping excluded from every year. Now folded into whichever year is viewed.

### Features (the 14 requested)

| # | Feature |
|---|---------|
| 1 | Frozen column 1 on all pages |
| 2 | Deliver from an order row, and from inside the order modal |
| 3 | Deliver multiple orders for one customer (not just defined groups); over-delivery allowed + flagged |
| 4 | Bulk status / mark-invoiced on Orders (visible-selection only) |
| 5 | Groups moved below All Customers; customer phone via `customerMeta` side-car map |
| 6 | Searchable, A–Z sorted product picker on order creation |
| 7 | Delivery notes, printed on the ticket |
| 8 | Add products to a delivery, written back onto the order |
| 9 | Typed electronic signatures + "Delivered By" user (managed in Settings) |
| 10 | Inventory product click → opens every order containing it |
| 11 | Year-scoped, NaN-hardened totals with footed columns |
| 12 | Bulk inventory search + A–Z sort |
| 13 | Per-customer pump totals + dashboard pump/tote tracker |
| 14 | Return tickets that credit inventory (incl. weigh-back) |

### Data-model changes (all backward-compatible via `migrate()`)
- New arrays: `returns` (return tickets), and `settings.users` (signature dropdown).
- New map: `customerMeta` keyed by customer name → `{phone, email, notes}`.
  Rename logic moves the key with the customer.
- Deliveries gained `pumpsReturnedQty` / `totesReturnedQty` (partial returns),
  `notes`, `deliveredBy`, `driverSig`, `customerSig`, `signedAt`, `overage`.
- Orders gained `hasOverage` flag.
- `migrate()` is the single schema-fix path (was duplicated in 3 places that had
  already drifted); spreads originals first so unknown fields survive.

### Verification
- 54-assertion Node harness over the **real** selector source: fiscal-year
  boundaries, over/under-delivery, returns crediting inventory, multi-order
  allocation, pump-return migration, NaN handling. All pass.
- JSX-aware structural scanner (validated against the known-good v5.1 as an
  oracle) — clean.
- Not executed in a live browser by Claude (no offline transpiler; sandbox can't
  reach the file). Nick confirmed the login screen renders and preview loads.

### Process changes this session
- Established that **local repo was a fresh `git init`**, unrelated to GitHub's
  16-commit history. Reconciled by re-anchoring local `main` to `origin/main`.
- Confirmed GitHub's live `index.html` was byte-identical to the v5.1 base
  (minus one stray leading blank line from web-editor pasting).
- Replaced the old copy-paste-into-GitHub workflow with double-click `.command`
  scripts (see `docs/DEPLOYMENT.md`).
- Adopted a **preview deploy** pattern: v6.0 at `/preview/`, live untouched.
- Documented the **magic-link auth quirk**: `emailRedirectTo` is hardcoded to the
  root domain, so preview login must piggyback on the shared same-origin session
  (sign in on live first, then open `/preview/`).
