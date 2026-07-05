# Setup SMTP Brevo + Supabase

## Step 1: Daftar Brevo

1. Buka https://www.brevo.com
2. Klik **Sign up free** — daftar pakai email real kamu
3. Verifikasi email dari Brevo
4. Login ke dashboard Brevo

## Step 2: Dapatkan SMTP Credentials

1. Di dashboard Brevo, klik logo profil di kanan atas
2. Pilih **SMTP & API** (atau **Transactionnel > SMTP**)
3. Di tab **SMTP**, klik **Create a new SMTP key**
4. Namai key: `Supabase E-Ticketing`
5. Copy **SMTP key** yang muncul (akan muncul sekali saja — simpan di notepad)

## Step 3: Verifikasi Email Pengirim

1. Di sidebar Brevo, klik **Sender Identity**
2. Klik **Add a Sender Identity**
3. Pilih **Email address only** — masukkan email real kamu
4. Cek inbox email kamu → klik link verifikasi dari Brevo

## Step 4: Isi SMTP di Supabase Dashboard

1. Buka https://supabase.com/dashboard/project/zlvxinokxlrkgnlwzdsb/auth/settings
2. Scroll ke **SMTP Settings**
3. Isi dengan data berikut:

| Field | Isi |
|-------|-----|
| **Sender name** | `E-Ticketing Helpdesk` |
| **Sender email** | Email yang kamu verifikasi di Brevo (Step 3) |
| **Host** | `smtp-relay.brevo.com` |
| **Port** | `587` |
| **Username** | Email yang kamu verifikasi di Brevo |
| **Password** | SMTP key dari Step 2 |

4. Klik **Save**

## Step 5: Test

1. Buka aplikasi → Login screen → klik **Lupa Password?**
2. Input email akun demo (misal `admin@e-ticketing.demo`)
3. Klik **Kirim Link Reset**
4. Cek inbox email kamu di Brevo sender email → harus ada email reset dari Supabase
5. Klik link di email → reset password → login dengan password baru

> Email ke `admin@e-ticketing.demo` akan dikirim ke Brevo, lalu Brevo meneruskannya ke alamat asli yang kamu verifikasi. Supaya email reset sampai ke penerima real, pastikan alamat yang kamu masukkan di form Forgot Password adalah alamat yang terdaftar sebagai user di aplikasi ini.
