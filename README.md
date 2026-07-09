# E-Ticketing Helpdesk

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Supabase](https://img.shields.io/badge/Supabase-PostgreSQL-3ECF8E?logo=supabase)
![Version](https://img.shields.io/badge/version-1.0.0--demo-blue)

Aplikasi mobile helpdesk berbasis tiket untuk pengelolaan permintaan bantuan IT. Dibangun dengan Flutter dan Supabase, mendukung tiga peran pengguna: **User**, **Helpdesk**, dan **Admin**.

---

## ✨ Fitur

| Modul | User | Helpdesk | Admin |
|-------|------|----------|-------|
| Buat tiket + upload file | ✅ | ✅ | ✅ |
| Lihat daftar tiket sendiri | ✅ | ✅ (ditugaskan) | ✅ (semua) |
| Detail tiket + riwayat | ✅ | ✅ | ✅ |
| Komentar / reply | ✅ | ✅ | ✅ |
| Tracking progress (stepper) | ✅ | ✅ | ✅ |
| Update status tiket | ❌ | ✅ `inprogress→closed` | ✅ `open→assign` |
| Assign helpdesk | ❌ | ❌ | ✅ |
| Dashboard statistik | ✅ (milik sendiri) | ✅ (ditugaskan) | ✅ (global) |
| Notifikasi perubahan tiket | ✅ | ✅ | ✅ |
| Reset password (bypass demo) | ✅ | ✅ | ✅ |

## 🧱 Tech Stack

| Layer | Teknologi |
|-------|-----------|
| **Mobile** | Flutter 3.x (Dart) |
| **State Management** | Provider (ChangeNotifier) |
| **Backend & Database** | Supabase (PostgreSQL 17, Auth, Storage, REST API) |
| **Arsitektur** | Clean Architecture (Domain / Data / Presentation) |
| **Auth** | Supabase Auth (JWT) |

## 🔁 Alur Status Tiket

```
open ──→ assign ──→ inprogress ──→ closed
  ↑                        │
  └────── (revisi) ────────┘
```

| Status | Deskripsi |
|--------|-----------|
| **open** | Tiket baru dibuat oleh user/admin, menunggu ditandai |
| **assign** | Admin telah menandai tiket, siap ditugaskan ke helpdesk |
| **inprogress** | Helpdesk sedang mengerjakan tiket |
| **closed** | Helpdesk telah menyelesaikan tiket |

## 🚀 Cara Menjalankan

### Prasyarat

- Flutter SDK 3.x ([install](https://docs.flutter.dev/get-started/install))
- Git

### Langkah

```bash
# 1. Clone repository
git clone https://github.com/vyerru/021_M.-Javier-R.-Abhista_B3_UTS.git
cd 021_M.-Javier-R.-Abhista_B3_UTS

# 2. Setup environment
cp .env.example .env
# .env sudah berisi SUPABASE_URL dan SUPABASE_ANON_KEY

# 3. Install dependencies
flutter pub get

# 4. Generate JSON serialization
dart run build_runner build

# 5. Jalankan
flutter run
```

> **Catatan:** Aplikasi sudah terhubung ke Supabase project yang sudah berisi database, tabel, RLS, dan storage. Tidak perlu setup database terpisah.

## 🔐 Akun Demo

| Role | Email | Password |
|------|-------|----------|
| **Admin** | `admin@e-ticketing.demo` | `admin123` |
| **Helpdesk** | `helpdesk@e-ticketing.demo` | `helpdesk123` |
| **User** | `user@e-ticketing.demo` | `user123456` |

## 📁 Struktur Proyek

```
lib/
├── core/                  # Konfigurasi tema, network
│   ├── network/
│   └── theme/
├── domain/                # Entities, repositories, use cases
│   ├── entities/
│   ├── repositories/
│   └── usecases/
├── data/                  # Data sources, repository impl, models
│   ├── datasources/       # Supabase API calls
│   ├── models/
│   └── repositories/
└── presentation/          # UI screens, providers, widgets
    ├── auth/
    ├── dashboard/
    │   └── widgets/
    ├── tickets/
    │   └── widgets/
    ├── notifications/
    └── profile/

supabase/
├── migrations/            # Database migration files
├── seed.sql               # Data awal (3 akun demo)
└── export_schema.sql      # Full database schema export
```

## 📖 Dokumentasi

| Dokumen | Deskripsi |
|---------|-----------|
| [API_DOCUMENTATION.md](API_DOCUMENTATION.md) | Dokumentasi lengkap REST API, RLS, trigger, dan fungsi database |
| [supabase/export_schema.sql](supabase/export_schema.sql) | Full database schema export |
| [APPLICATION_FLOW.md](APPLICATION_FLOW.md) | Alur aplikasi dan business logic |

## 📦 Download APK

Unduh APK terbaru di halaman [Releases](https://github.com/vyerru/021_M.-Javier-R.-Abhista_B3_UTS/releases).

---

**Dibuat untuk UAS Aplikasi Mobile — DIV Teknik Informatika Universitas Airlangga 2026**
