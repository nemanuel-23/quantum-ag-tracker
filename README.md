# Quantum Ag — Inventory & Delivery Tracker

A web-based inventory and delivery management app for tracking BWF product orders, deliveries, and customer accounts.

## Features

- **Dashboard** — KPI summary of inventory levels, order statuses, and customer groups
- **Inventory Management** — Track starting inventory, additions (tagged by date/qty), available inventory, and sold-but-not-delivered quantities per product
- **Customer Orders** — Multiple orders per customer, individual order dates, customer totals, and customer group subtotals
- **Customer Groups** — Group customers together (e.g., "Webster Ag" = Tom + Tate + Jordan Emanuel) with combined totals
- **Order Status Tracking** — Color-coded statuses: Pending, Paid & Delivered, Sorted & Ready, Partially Sorted, Partial Delivery, Shuttle Filled, Waiting on Check
- **Delivery Checkout** — Record deliveries with pump loans (quantity + return date) and tote tracking (with season-end check-in)
- **Delivery Tickets** — Generate printable/PDF delivery tickets with products, quantities, and signature lines
- **Data Persistence** — All data saved in browser localStorage with JSON export/import for backup
- **Responsive Design** — Works on desktop, tablet, and mobile

## Getting Started

### Option 1: Open Directly
Just open `index.html` in any modern web browser. No server or installation needed.

### Option 2: GitHub Pages
1. Push this repo to GitHub
2. Go to **Settings > Pages**
3. Set source to **main branch**, root folder
4. Your app will be live at `https://<username>.github.io/quantum-ag-tracker/`

### Option 3: Any Static Host
Upload `index.html` to any static hosting service (Netlify, Vercel, S3, etc.).

## Data

The app comes pre-loaded with data from the BWF Order Forecast spreadsheet including:
- 24 products with starting inventory levels
- 18 existing customer orders
- 2 customer groups (Webster Ag, Mensik)
- Full customer and product master lists

## Multi-User Access

For multi-user access, consider:
1. **GitHub Pages** for read-only shared access
2. **Adding a backend** (Firebase, Supabase) for real-time multi-user data sync
3. **JSON export/import** for manual data sharing between users

## Tech Stack

- React 18 (via CDN)
- Tailwind-style CSS (embedded)
- No build step required
- No dependencies to install
