<div align="center">

# 📝 Todo List App

### *Aplikasi Todo List Modern dengan Flutter & Supabase*

![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Supabase](https://img.shields.io/badge/Supabase-3ECF8E?style=for-the-badge&logo=supabase&logoColor=white)
![SQLite](https://img.shields.io/badge/SQLite-07405E?style=for-the-badge&logo=sqlite&logoColor=white)

**Offline-First • Real-time Sync • Material Design 3**

[Demo](#-demo) • [Fitur](#-fitur-utama) • [Instalasi](#-instalasi) • [Dokumentasi](#-dokumentasi)

---

</div>

## 🎯 Tentang Aplikasi

Todo List App adalah aplikasi manajemen tugas yang dibangun dengan Flutter, dilengkapi dengan autentikasi pengguna dan sistem sinkronisasi offline-first. Aplikasi ini menggunakan Supabase sebagai backend dan SQLite untuk penyimpanan lokal, memastikan pengalaman pengguna yang mulus bahkan tanpa koneksi internet.

### 🌟 Mengapa Aplikasi Ini?

- **🔄 Offline-First Architecture** - Bekerja tanpa koneksi internet, sinkronisasi otomatis saat online
- **🔐 Autentikasi Aman** - Login dan registrasi dengan Supabase Authentication
- **⚡ Real-time Sync** - Perubahan tersinkron otomatis ke cloud
- **💾 Data Persistence** - Data tersimpan lokal dengan SQLite
- **🎨 Modern UI/UX** - Material Design 3 dengan animasi smooth
- **📱 Cross-platform** - Berjalan di Android, iOS, Web, Desktop

---

## ✨ Fitur Utama

### 🔑 Autentikasi
- ✅ Login dengan email & password
- ✅ Registrasi pengguna baru
- ✅ Session management otomatis
- ✅ Logout dengan konfirmasi

### 📋 Manajemen Tugas
- ✅ Tambah tugas baru dengan judul & deskripsi
- ✅ Edit tugas yang sudah ada
- ✅ Tandai tugas sebagai selesai/belum selesai
- ✅ Hapus tugas dengan konfirmasi
- ✅ Pull-to-refresh untuk sinkronisasi manual

### 🌐 Offline Support
- ✅ Berfungsi penuh tanpa internet
- ✅ Indikator status koneksi real-time
- ✅ Badge counter untuk perubahan yang belum tersinkron
- ✅ Antrian sinkronisasi otomatis saat online kembali
- ✅ Notifikasi offline mode

---

## 🛠️ Teknologi & Arsitektur

### Tech Stack

| Technology | Purpose |
|------------|---------|
| **Flutter** | Cross-platform UI framework |
| **Dart** | Programming language |
| **Provider** | State management |
| **Supabase** | Backend-as-a-Service (Auth + Database) |
| **SQLite** | Local database (via sqflite) |
| **HTTP** | REST API communication |
| **Shared Preferences** | Token storage |

### 📐 Arsitektur Aplikasi

```
lib/
├── main.dart                    # Entry point & splash screen
├── models/
│   └── task.dart               # Task model (JSON ↔ SQLite)
├── providers/
│   └── task_provider.dart      # State management & business logic
├── screens/
│   ├── login_screen.dart       # Login & registrasi UI
│   ├── task_list_screen.dart   # Daftar tugas & pull-to-refresh
│   └── add_task_screen.dart    # Tambah/edit tugas UI
├── api/
│   └── task_api.dart           # Supabase REST & Auth client
└── local/
    └── task_local_db.dart      # SQLite operations & sync queue
```

### 🔄 Alur Offline-First

```
User Action → Save to SQLite (Immediate) → Update UI → Sync to Supabase (Background)
                    ↓                           ↓
              Success (UI updated)      ✅ Mark as synced / ❌ Keep in queue
```

---

## 🚀 Instalasi

### Prerequisites

Pastikan sudah terinstall:
- Flutter SDK (>= 3.0.0)
- Dart SDK (>= 3.0.0)
- Android Studio / VS Code
- Emulator atau Physical Device

### Langkah Instalasi

1. **Clone repository**
   ```bash
   git clone https://github.com/username/todo_list_app.git
   cd todo_list_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Konfigurasi Supabase** (lihat [Setup Supabase](#-setup-supabase))

4. **Run aplikasi**
   ```bash
   # Debug mode
   flutter run
   
   # Release mode
   flutter run --release
   ```

---

## ⚙️ Setup Supabase

### 1. Buat Project Supabase

1. Kunjungi [supabase.com](https://supabase.com)
2. Buat project baru
3. Salin `Project URL` dan `anon public` key

### 2. Buat Tabel Database

Jalankan SQL berikut di Supabase SQL Editor:

```sql
-- Buat tabel tasks
CREATE TABLE tasks (
  id BIGSERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  completed BOOLEAN DEFAULT FALSE,
  user_id TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Buat index untuk query yang lebih cepat
CREATE INDEX idx_tasks_user_id ON tasks(user_id);
CREATE INDEX idx_tasks_created_at ON tasks(created_at DESC);

-- Enable Row Level Security (RLS)
ALTER TABLE tasks ENABLE ROW LEVEL SECURITY;

-- Policy: User hanya bisa lihat tugasnya sendiri
CREATE POLICY "Users can view their own tasks"
  ON tasks FOR SELECT
  USING (auth.uid()::text = user_id);

-- Policy: User hanya bisa insert tugasnya sendiri
CREATE POLICY "Users can insert their own tasks"
  ON tasks FOR INSERT
  WITH CHECK (auth.uid()::text = user_id);

-- Policy: User hanya bisa update tugasnya sendiri
CREATE POLICY "Users can update their own tasks"
  ON tasks FOR UPDATE
  USING (auth.uid()::text = user_id);

-- Policy: User hanya bisa delete tugasnya sendiri
CREATE POLICY "Users can delete their own tasks"
  ON tasks FOR DELETE
  USING (auth.uid()::text = user_id);
```

### 3. Update Kredensial

Edit file `lib/api/task_api.dart`:

```dart
static const String supabaseUrl = 'YOUR_SUPABASE_URL';
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY';
```

> ⚠️ **PENTING:** Jangan commit kredensial ke repository publik! Gunakan environment variables atau file config terpisah.

---

## 🧪 Testing

### Run Unit Tests
```bash
flutter test
```

### Run Integration Tests
```bash
flutter test integration_test/app_flow_test.dart
```

### Run Tests dengan Coverage
```bash
flutter test --coverage
```

---

## 📸 Demo

### Screenshots

> *Coming soon - tambahkan screenshot aplikasi Anda di sini*

| Login Screen | Task List | Add Task | Offline Mode |
|--------------|-----------|----------|--------------|
| 📱 | 📱 | 📱 | 📱 |

---

## 📚 Dokumentasi

### API Reference

#### TaskProvider Methods

| Method | Description |
|--------|-------------|
| `login(email, password)` | Login user dan load tasks |
| `register(email, password)` | Registrasi user baru |
| `addTask(title, description)` | Tambah task baru (offline-first) |
| `toggleTask(task)` | Toggle status completed task |
| `updateTask(task, title, desc)` | Update task yang ada |
| `deleteTask(task)` | Hapus task |
| `syncWithServer()` | Sinkronisasi manual dengan server |

### State Management

Aplikasi menggunakan Provider dengan `ChangeNotifier`:
- `TaskProvider` - Mengelola auth state dan task list
- Automatic updates ke UI saat data berubah
- Efficient rebuilds dengan `Consumer` widget

---

## 🤝 Contributing

Kontribusi selalu welcome! Berikut cara berkontribusi:

1. Fork repository ini
2. Buat branch baru (`git checkout -b feature/AmazingFeature`)
3. Commit perubahan (`git commit -m 'Add some AmazingFeature'`)
4. Push ke branch (`git push origin feature/AmazingFeature`)
5. Buat Pull Request

### Guidelines
- Ikuti Dart/Flutter style guide
- Tulis test untuk fitur baru
- Update dokumentasi jika diperlukan

---

## 📝 License

Distributed under the MIT License. See `LICENSE` for more information.

---

## 👨‍💻 Author

**Your Name**

- GitHub: [@yourusername](https://github.com/yourusername)
- Email: your.email@example.com

---

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev) - Amazing framework
- [Supabase](https://supabase.com) - Backend-as-a-Service
- [Material Design 3](https://m3.material.io) - Design system
- [Provider Package](https://pub.dev/packages/provider) - State management

---

<div align="center">

**⭐ Star project ini jika bermanfaat! ⭐**

Made with ❤️ using Flutter

[⬆ Back to top](#-todo-list-app)

</div>
