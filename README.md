# 💰 WalletScript

> **Smart Personal Finance Manager** — Aplikasi manajemen keuangan pribadi yang cerdas, dibangun dengan Flutter.

---

## 📱 Preview

WalletScript adalah aplikasi wallet Android yang dirancang untuk membantu pengguna mengelola keuangan pribadi secara efisien — mulai dari pencatatan transaksi harian, budgeting, hingga analisis pasar dan pengingat pintar berbasis kalender.

---

## ✨ Fitur Utama

### 🏠 Dashboard / Home
- Ringkasan total saldo dengan tampilan balance trend (grafik 30 hari)
- Kartu Reminder & Insight harian otomatis
- Spending Overview dengan donut chart per kategori
- My Wallets — multi-wallet (Visa, Tabungan, Cash)
- Flow History — riwayat transaksi terbaru

### 📊 History
- Riwayat semua transaksi dengan filter kategori
- Pencarian transaksi real-time
- Pengelompokan per tanggal (Today, Yesterday, dst)
- Swipe-to-delete transaksi

### 🎯 Budget & Financial Goals
- Buat target keuangan (nabung beli mobil, rumah, dll)
- Progress bar visual per goal
- Liquidity sources tracker
- Active Priority goal dengan vision board

### ➕ Add Transaction
- Input pemasukan, pengeluaran, dan transfer
- Pilihan kategori lengkap dengan ikon
- Multi-wallet selector
- Date picker & catatan tambahan
- Attachment receipt (kamera/galeri)

### 📈 Insights
- Live market data (BTC, Saham, Forex, Gold)
- Market Sentiment indicator
- AI-driven Smart Picks & portfolio insight
- Tab filter: Saham / Crypto / Forex

### 📅 Kalender
- Full monthly calendar grid
- Dot indicator transaksi & reminder per hari
- Timeline transaksi per tanggal yang dipilih
- Set Reminder langsung dari kalender

### 📝 Notes
- Tampilan grid seperti Apple Notes
- Pin catatan penting
- **Integrasi kalender** — note bisa dijadikan reminder
- Push notification otomatis saat reminder tiba
- Info lengkap: dibuat, last edited, author

### 👤 Profile
- Halaman profil pengguna
- Statistik: total transaksi, transaksi bulan ini, goals aktif
- Ringkasan wallet
- Navigasi ke Settings untuk edit profil

### ⚙️ Settings
- Edit profil & foto
- Toggle notifikasi
- Theme switcher (Light / Dark / System)
- Accent color picker
- Export data keuangan
- Privacy policy & help center

---

## 🛠️ Tech Stack

| Teknologi | Kegunaan |
|-----------|----------|
| **Flutter** | UI Framework (Android) |
| **Dart** | Bahasa pemrograman |
| **Provider** | State management |
| **SQLite (sqflite)** | Local database |
| **flutter_local_notifications** | Push notification & reminder |
| **timezone** | Scheduling notifikasi |
| **intl** | Format tanggal & mata uang |
| **fl_chart** | Grafik & chart |
| **google_fonts** | Custom typography |

---

## 🚀 Cara Menjalankan

### Prerequisites
- Flutter SDK >= 3.0.0
- Android Studio / VS Code
- Android Emulator atau device fisik (Android 8.0+)

### Instalasi

```bash
# Clone repository
git clone https://github.com/USERNAME/walletscript.git

# Masuk ke folder project
cd walletscript

# Install dependencies
flutter pub get

# Jalankan app
flutter run
```

---

## 📁 Struktur Project

```
lib/
├── main.dart                  # Entry point & navigation shell
├── models/                    # Data models
│   ├── transaction_model.dart
│   ├── budget_model.dart
│   └── note_model.dart
├── providers/                 # State management
│   ├── transaction_provider.dart
│   ├── budget_provider.dart
│   ├── note_provider.dart
│   └── settings_provider.dart
├── screens/                   # UI Screens
│   ├── home_screen.dart
│   ├── history_screen.dart
│   ├── budget_screen.dart
│   ├── insights_screen.dart
│   ├── settings_screen.dart
│   ├── profile_screen.dart
│   ├── notes_screen.dart
│   ├── calendar_screen.dart
│   ├── add_transaction_screen.dart
│   └── app_top_bar.dart
├── services/                  # Business logic
│   ├── database_service.dart
│   └── notification_service.dart
└── theme/
    └── app_theme.dart         # Design system & color palette
```

---

## 🎨 Design System

- **Primary Color:** `#10B981` (Emerald Green)
- **Dark Accent:** `#1E293B` (Slate Dark)
- **Typography:** Clean sans-serif, weight hierarchy
- **UI Style:** Minimal cards, floating navbar, smooth animations

---

## 👨‍💻 Developer

**Dibuat oleh:** [Nama Kamu]  
**Platform:** Android  
**Status:** 🚧 In Development  

---

> *WalletScript — Karena keuangan yang sehat dimulai dari catatan yang rapi.*