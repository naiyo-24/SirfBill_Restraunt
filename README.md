<div align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/LOGO_DM.png">
    <source media="(prefers-color-scheme: light)" srcset="assets/LOGO.png">
    <img alt="SirfBill Logo" src="assets/LOGO.png" width="300">
  </picture>
  <br/>
  <h1>SirfBill Restaurant POS & Operations Platform</h1>
  <p><strong>Hospitality without friction</strong> • Multi-Floor Table Management, Real-Time KOT Dispatch, Kitchen Display System (KDS), Multi-Tender Billing, Direct Thermal Printing Suite (USB / LAN / Bluetooth), Inventory & GRN, and Executive Analytics</p>

  <p>
    <img src="https://img.shields.io/badge/Flutter-3.22+-02569B?logo=flutter&logoColor=white" alt="Flutter">
    <img src="https://img.shields.io/badge/Dart-3.5+-0175C2?logo=dart&logoColor=white" alt="Dart">
    <img src="https://img.shields.io/badge/FastAPI-0.110+-009688?logo=fastapi&logoColor=white" alt="FastAPI">
    <img src="https://img.shields.io/badge/PostgreSQL-15+-4169E1?logo=postgresql&logoColor=white" alt="PostgreSQL">
    <img src="https://img.shields.io/badge/Platform-Android%20%7C%20Windows%20%7C%20Web%20%7C%20macOS-blue" alt="Platforms">
    <img src="https://img.shields.io/badge/Version-1.0.50%2B50-emerald" alt="Version">
  </p>
</div>

---

## 📋 Table of Contents

- [Project Overview](#-project-overview)
  - [The Problem It Solves](#the-problem-it-solves)
  - [Core Capabilities](#core-capabilities)
- [Thermal Printing Suite (USB, LAN, Bluetooth)](#-thermal-printing-suite)
  - [Direct Android USB OTG Printing](#1-direct-android-usb-otg-printing)
  - [LAN / Wi-Fi Network Printing (Port 9100)](#2-lan--wi-fi-network-printing-port-9100)
  - [Bluetooth (BT) Wireless Printing](#3-bluetooth-bt-wireless-printing)
  - [ESC/POS Rasterizer & Paper Waste Prevention](#4-smart-escpos-rasterizer--blank-paper-waste-prevention)
  - [Paper Roll Compatibility (58mm vs 80mm)](#5-paper-roll-compatibility-58mm-vs-80mm)
- [Tech Stack](#-tech-stack)
- [Prerequisites & Environment](#-prerequisites--environment)
- [Getting Started](#-getting-started)
  - [1. Clone Repository](#1-clone-repository)
  - [2. Environment Configuration](#2-environment-configuration)
  - [3. Install Dependencies](#3-install-dependencies)
  - [4. Run on Web](#4-run-on-web)
  - [5. Run on Android](#5-run-on-android)
  - [6. Run on Desktop (Windows / macOS)](#6-run-on-desktop-windows--macos)
- [Project Architecture & Directory Structure](#-project-architecture--directory-structure)
- [Feature Modules](#-feature-modules)
  - [Interactive POS & Fast Counter Billing](#-interactive-pos--fast-counter-billing)
  - [Floor Plan & Table Management](#-floor-plan--table-management)
  - [Live KOT & Kitchen Display System (KDS)](#-live-kitchen-order-tickets-kot--kitchen-display-system-kds)
  - [Inventory, Purchases & Goods Received Notes (GRN)](#-inventory-purchases--goods-received-notes-grn)
  - [Executive Analytics & Financial Ledgers](#-executive-analytics--financial-ledgers)
- [Backend API Contract](#-backend-api-contract)
- [Troubleshooting & Gotchas](#-troubleshooting--gotchas)
- [License](#-license)

---

## 📖 Project Overview

**SirfBill Restaurant** is an enterprise-grade Point of Sale (POS) and operations management platform engineered with **Flutter** (frontend) and **FastAPI** (backend). Built for high-volume restaurants, cafes, quick-service counters (QSR), cloud kitchens, and fine dining establishments, it unifies front-of-house guest ordering, multi-station kitchen dispatch, table seating states, inventory procurement, and hardware thermal printing.

### The Problem It Solves
Traditional restaurant billing software is frequently locked to proprietary POS terminals, dependent on flaky operating system print queues, or disjointed between counter cashiers and kitchen chefs:
- **Print Spooler Failures on Mobile**: Android's default Print Spooler only detects network printers configured with specialized Android Print Service plugins (Mopria/Epson). Generic POS-58 and POS-80 thermal printers plugged via USB-OTG or connected over Bluetooth fail to show up in system dialogs. SirfBill integrates direct low-level USB OTG, LAN socket, and Bluetooth SPP drivers that bypass the OS spooler completely.
- **Wasted Thermal Paper Rolls**: Fixed-height receipt layouts often spit out 10–30 cm of trailing blank paper. SirfBill incorporates an automatic bottom blank space trimmer that dynamically cuts directly after the receipt footer.
- **Right-Side Clipping on 58mm Rolls**: Standard 80mm templates sent to 58mm mini printers clip the rightmost rate and total columns. SirfBill features a hardware width scaler with side safety margins.
- **Floor Seating & Held Orders**: Tables transition across occupied, empty, and reserved states, allowing continuous appending of course lines to active dining checks.

---

## 🖨️ Thermal Printing Suite

SirfBill features a dedicated hardware communication layer for thermal receipt and KOT printers across three distinct interfaces:

```
┌──────────────────────────────────────────────────────────────────┐
│                   SirfBill Thermal Printing Engine               │
└─────────────────────────────────┬────────────────────────────────┘
                                  │
      ┌───────────────────────────┼───────────────────────────┐
      ▼                           ▼                           ▼
┌──────────────┐          ┌──────────────┐            ┌──────────────┐
│  Direct USB  │          │   LAN / TCP  │            │  Bluetooth   │
│  Android OTG │          │  Port 9100   │            │   Classic    │
│ (UsbManager) │          │  (Ethernet)  │            │ (RFCOMM SPP) │
└──────┬───────┘          └──────┬───────┘            └──────┬───────┘
       │                         │                           │
       └─────────────────────────┼───────────────────────────┘
                                 ▼
           ┌──────────────────────────────────────────┐
           │        EscPosRasterHelper Engine         │
           │  • 1-Bit Monochrome Luminance Dither    │
           │  • Dynamic Bottom Blank Space Trimmer   │
           │  • 6-Dot Side Margin Anti-Clipping      │
           │  • 58mm (384-dot) / 80mm (512-dot) Mode │
           │  • Hardware Auto-Cut & Feed Commands    │
           └──────────────────────────────────────────┘
```

### 1. Direct Android USB OTG Printing
- **Native UsbManager Bridge**: Implemented in Kotlin via MethodChannel (`com.sirfbill.pos/usb_printer`) in [MainActivity.kt](android/app/src/main/kotlin/com/example/manju_medical/MainActivity.kt).
- **Zero OS Spooler Dependency**: Directly enumerates USB devices, claims the printer interface (`interfaceClass == 7`), and streams ESC/POS byte buffers through the bulk OUT endpoint in 4KB chunks off the UI thread.
- **Runtime Permissions**: Fully compliant with Android 12 through Android 15 (`FLAG_MUTABLE` PendingIntents and dynamic broadcast receivers).

### 2. LAN / Wi-Fi Network Printing (Port 9100)
- **Direct TCP Sockets**: Communicates directly with network thermal printers via raw TCP Port 9100 ([lan_thermal_printer_service.dart](lib/utils/lan_thermal_printer_service.dart)).
- **Zero Drivers Needed**: Works natively across Android, Windows, and macOS desktops over local Ethernet or Wi-Fi.
- **One-Click Connectivity Test**: Built-in IP address testing utility to confirm printer reachability before firing jobs.

### 3. Bluetooth (BT) Wireless Printing
- **RFCOMM SPP Bridge**: Connects wirelessly to portable Bluetooth receipt printers using Serial Port Profile UUID `00001101-0000-1000-8000-00805F9B34FB` ([BluetoothPrinterManager.kt](android/app/src/main/kotlin/com/example/manju_medical/BluetoothPrinterManager.kt)).
- **Paired Device Enumeration**: Automatically lists paired devices for one-tap selection.
- **Ideal for Mobile POS**: Enables waiters and counter cashiers to print bills on portable 58mm battery printers.

### 4. Smart ESC/POS Rasterizer & Blank Paper Waste Prevention
- **Automated Bottom Blank Space Trimmer**: `EscPosRasterHelper.trimBottomBlankSpace` scans bitmap rows from the bottom up, finds where content terminates, and crops out trailing empty whitespace. Eliminates 10–30 cm of wasted paper roll.
- **Contrast Enhancer**: [ThermalLogoEnhancer](lib/utils/thermal_logo_enhancer.dart) auto-crops transparent logo margins and applies a steep contrast curve to prevent faint or dithered logos on 1-bit thermal printheads.
- **Sequential Printing with Auto-Cut**: Automatically fires the Kitchen KOT first, performs a mechanical cut (`GS V 66 0`), pauses 350ms, and prints the Customer Bill with a second cut.

### 5. Paper Roll Compatibility (58mm vs 80mm)
| Paper Width | Dots / Printable Width | Bytes per Row | Target Hardware |
|---|---|---|---|
| **58mm (2 Inch)** | 384 dots (48mm) | 48 bytes/row | Handheld battery printers, portable Bluetooth/OTG mini printers |
| **80mm (3 Inch)** | 512 dots (64mm) | 64 bytes/row | Universal standard desktop POS thermal printers (Epson, Xprinter, TVS) |

Cashiers can toggle paper size directly from the receipt footer or the [ThermalPrinterSettingsDialog](lib/screens/counter/widgets/pos/thermal_printer_settings_dialog.dart), remembered persistently via `SharedPreferences`.

---

## 🛠️ Tech Stack

### Frontend Architecture
| Technology | Role | Description |
|---|---|---|
| **Flutter 3.22+** | Core Framework | High-performance reactive UI compiled for Web, Android, and Windows. |
| **Riverpod** | State Management | Compile-time safe state management for orders, cart, tables, KDS, and distributor ledgers. |
| **GoRouter** | Declarative Routing | Stateful routing with deep-link support and keyboard hotkeys (`F1` to `F8`). |
| **Dio & Pretty Logger** | HTTP Client | Central API gateway with JWT authorization, tenant headers, and interceptors. |
| **pdf & printing** | PDF Rendering | PDF vector rendering for receipts, KOTs, A4 tax invoices, and executive reports. |
| **image** | Bitmap Processing | 1-bit monochrome luminance dithering, dynamic cropping, and ESC/POS raster generation. |
| **excel & file_saver** | Spreadsheet Export | Multi-tab `.xlsx` report generator for Sales Summaries, Item-Wise Sales, and Audit Logs. |

### Backend Architecture
| Technology | Role | Description |
|---|---|---|
| **Python & FastAPI** | Core REST API | High-throughput asynchronous endpoints with OpenAPI documentation. |
| **SQLAlchemy 2.0** | Database ORM | Multi-tenant schema filtering across shops, tables, orders, and inventory. |
| **PostgreSQL 15+** | Relational Database | ACID-compliant storage for transactions, stock balances, and audit records. |
| **JWT** | Authentication | Role-based stateless token authentication with branch tenant scoping. |

---

## 📋 Prerequisites & Environment

- **Flutter SDK**: `>=3.22.0` (Dart `>=3.5.0`)
- **Android Studio / SDK**: Android SDK Platform 34+, Build Tools 34.0.0
- **Google Chrome**: Recommended for web execution and debugging
- **Visual Studio 2022**: C++ Desktop workload (required only for Windows native `.exe` build)

---

## 🚀 Getting Started

### 1. Clone Repository
```bash
git clone https://github.com/your-username/sirfbill_restaurant.git
cd sirfbill_restaurant
```

### 2. Environment Configuration
Create a `.env` file in the project root:
```env
API_BASE_URL=http://localhost:8000
```
*(Point to your backend server, e.g. `http://192.168.0.150:8000`)*

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Run on Web
```bash
flutter run -d chrome
```

### 5. Run on Android
```bash
# Connect phone via USB with USB Debugging enabled
flutter devices
flutter run -d <device-id>
```

### 6. Run on Desktop (Windows / macOS)
```bash
# Windows
flutter run -d windows

# macOS
flutter run -d macos
```

---

## 📂 Project Architecture & Directory Structure

```
lib/
├── config/                               # API client, network interceptors & theme constants
├── models/                               # Strong DTO data models
│   ├── restaurant_pos_models.dart        # DiningTable, RestaurantOrder, PosCartItem
│   ├── restaurant_report_models.dart     # SalesReportSummary, TopSellingDish, AuditLogEntry
│   └── counter_models.dart               # Customer, ShopSettings, OutletInfo
├── providers/                            # Riverpod global state providers
│   ├── restaurant_pos_provider.dart      # Active cart, discounts, table binding
│   ├── restaurant_table_provider.dart    # Floor plan status & occupancy timers
│   ├── kitchen_display_provider.dart     # Real-time KDS kitchen order queue
│   ├── restaurant_order_provider.dart    # Order lifecycle & state transitions
│   └── restaurant_report_provider.dart   # Financial metrics & sales aggregations
├── router/                               # GoRouter configuration & route bindings
├── screens/counter/                      # Main operational screens
│   ├── billing_screen.dart               # POS Counter, menu catalogue, cart, hotkeys
│   ├── table_management_screen.dart      # Floor visualizer & table layout
│   ├── kitchen_display_screen.dart       # Live Kitchen Display System (KDS)
│   ├── order_management_screen.dart      # Active & historical order register
│   ├── reports_screen.dart               # Sales summaries, item mix & audit logs
│   ├── menu_management_screen.dart       # Dish catalogues, modifiers, categories
│   ├── inventory/                        # Inventory, Purchases & GRN management
│   └── widgets/                          # Modular UI components
│       ├── pos/                          # Settlement modal, receipt footer, settings
│       │   ├── pos_bill_receipt_modal.dart
│       │   ├── pos_bill_receipt_footer.dart
│       │   ├── thermal_printer_settings_dialog.dart
│       │   └── controllers/
│       │       ├── pos_settlement_service.dart
│       │       └── thermal_print_dispatcher.dart
│       └── ...
└── utils/                                # Core helper utilities
    ├── esc_pos_raster_helper.dart        # High-performance ESC/POS raster generator
    ├── usb_thermal_printer_service.dart  # Android USB OTG UsbManager bridge
    ├── lan_thermal_printer_service.dart  # Raw TCP Port 9100 network printer bridge
    ├── bluetooth_thermal_printer_service.dart # RFCOMM SPP Bluetooth printer bridge
    ├── thermal_logo_enhancer.dart        # Dynamic monochrome contrast & cropping booster
    ├── kot_printer_helper.dart           # Kitchen Order Ticket formatter
    └── restaurant_bill_pdf_generator.dart# Customer thermal bill generator
```

---

## 🎯 Feature Modules

### 🛒 Interactive POS & Fast Counter Billing
- **Keyboard Hotkeys**: Navigate with `F1` (Billing), `F2` (Tables), `F3` (Orders), `F4` (Kitchen), `F5` (Menu), `F6` (Customers), `F7` (Reports), `F8` (Settings).
- **Flexible Order Types**: Supports **Dine-In**, **Takeaway**, and **Delivery**.
- **Dynamic UPI QR Codes**: Displays on-screen and printed payment QR codes with automatic invoice and amount encoding.
- **Hold & Append**: Keep table checks open while diners order additional rounds; automatically appends items to the active bill without losing previous kitchen records.

### 🪑 Floor Plan & Table Management
- **Multi-Floor Layouts**: Group tables across Ground Floor, 1st Floor, Rooftop, Patio, etc.
- **Seating Duration Timers**: Real-time duration indicators showing how long guests have occupied a table.
- **Instant Check Docking**: Tapping an occupied table reloads its active cart and order state onto the counter POS.

### 🍳 Live Kitchen Order Tickets (KOT) & KDS
- **Automatic Multi-Station Routing**: Routes kitchen tickets to designated station printers.
- **Kitchen Display System (KDS)**: Digital board with live elapsed ticket timers, item notes, and one-tap status advancement (`New` ➔ `Preparing` ➔ `Ready` ➔ `Served`).

### 📦 Inventory, Purchases & Goods Received Notes (GRN)
- **Supplier Ledger & PO Tracking**: Manage purchase orders, payment terms, and vendor balances.
- **Record GRN**: Stock inwarding with ingredient batching, tax calculations, and cost-price tracking.
- **Ingredient Categorization**: Real-time tracking of food ingredients and supplies.

### 📊 Executive Analytics & Financial Ledgers
- **Date Filters**: Today, This Week, This Month, This Year, All Time, or Custom Range.
- **KPI Metrics**: Gross Revenue, Net Revenue, Collected GST, Total Bills, and Average Check (AOV).
- **Tender Breakdowns**: Cash, UPI, and Card distribution across Dine-In vs. Takeaway.
- **Top Dishes Ranking**: Identifies best-performing menu items by quantity and revenue.
- **Multi-Sheet Exports**: Generate formatted `.xlsx` spreadsheets and executive PDF reports.

---

## 🔌 Backend API Contract

| Method | Endpoint | Description |
|---|---|---|
| `GET` | `/api/restaurant/tables` | Fetch tables with floor and live occupancy status |
| `PATCH`| `/api/restaurant/tables/{id}/status` | Update table occupancy state |
| `GET` | `/api/restaurant/orders` | Fetch orders list with status and date filters |
| `POST` | `/api/restaurant/orders` | Create a new restaurant order with item lines |
| `PATCH`| `/api/restaurant/orders/{id}/items` | Append additional dishes to an active order |
| `POST` | `/api/restaurant/orders/{id}/settle` | Settle payment with multi-tender support |
| `POST` | `/api/restaurant/orders/{id}/send-to-kitchen` | Dispatch ticket to kitchen KDS / KOT printer |
| `GET` | `/api/restaurant/inventory/ingredients` | Fetch stock ingredients and inventory levels |
| `POST` | `/api/restaurant/inventory/grn` | Record a Goods Received Note (GRN) |
| `GET` | `/api/admin/pos/history` | Historical POS transactions and itemized lines |

---

## ⚠️ Troubleshooting & Gotchas

1. **Android USB OTG Permission Dialog**:
   - When connecting a USB thermal printer via OTG adapter, Android displays an OS confirmation: *"Allow SirfBill to access USB Device?"*. Tap **Always allow** to prevent future prompts.
2. **Bluetooth Thermal Pairing**:
   - Pair the Bluetooth thermal printer in Android OS Settings before launching the app. The app automatically detects bonded devices and displays them in the setup dropdown.
3. **LAN Printer Port 9100**:
   - Ensure the printer and the Android/Windows device are connected to the same Wi-Fi router / subnet. Confirm port 9100 is open on your network firewall.
4. **Environment File (`.env`)**:
   - Ensure a valid `.env` file exists with `API_BASE_URL`. For production builds, pass `--dart-define=API_BASE_URL=...` during build.

---

## 📄 License

This software is proprietary and developed for **SirfBill Restaurant POS**. Unauthorized copying, distribution, or commercial exploitation is strictly prohibited.
