# 🎨 ArtHub - Sistem Lelang Karya Seni

ArtHub adalah platform lelang karya seni online yang memungkinkan seniman untuk menjual karya mereka dan pembeli untuk menawar karya seni yang mereka minati. Sistem ini dibangun menggunakan PHP dan MySQL dengan memanfaatkan stored procedure, trigger, transaction, dan stored function untuk memastikan integritas data dan keamanan transaksi.

![ArtHub](/placeholder.svg?height=400&width=800)

## 📌 Deskripsi Proyek

ArtHub memiliki fitur-fitur utama sebagai berikut:

- **Manajemen Karya Seni**: Seniman dapat mengunggah, mengedit, dan menghapus karya seni mereka
- **Sistem Lelang**: Karya seni dapat dilelang dengan harga awal dan waktu berakhir yang ditentukan
- **Penawaran**: Pembeli dapat menawar karya seni yang sedang dilelang
- **Manajemen Saldo**: Pembeli dapat menambahkan dana ke akun mereka
- **Dashboard**: Dashboard khusus untuk seniman dan pembeli

Sistem ini mengimplementasikan konsep database lanjutan untuk memastikan keamanan dan integritas data.

## 📊 Detail Implementasi

### 🧠 Stored Procedure

Stored procedure digunakan untuk mengenkapsulasi logika bisnis kompleks di sisi database, memastikan konsistensi dan keamanan operasi.

#### 1. `sp_place_bid` - Prosedur untuk memasukkan penawaran

**Implementasi di file**: `place_bid.php`

````php
// Panggil stored procedure
$query = "CALL sp_place_bid($auction_id, $bidder_id, $bid_amount)";
$result = mysqli_query($conn, $query);
Prosedur ini menangani validasi penawaran, memastikan penawaran lebih tinggi dari harga saat ini, dan memperbarui harga lelang.

#### 2. `sp_tambah_karya_seni` - Prosedur untuk menambahkan karya seni baru

**Implementasi di file**: `db.php`

```php
function tambahKaryaSeni($title, $description, $artist_id, $starting_price, $image_path)
{
    global $conn;
    // Escape strings to prevent SQL injection (basic protection)
    $title = mysqli_real_escape_string($conn, $title);
    $description = mysqli_real_escape_string($conn, $description);
    $image_path = mysqli_real_escape_string($conn, $image_path);

    $query = "CALL sp_tambah_karya_seni('$title', '$description', $artist_id, $starting_price, '$image_path')";
    return mysqli_query($conn, $query);
}
````

Prosedur ini menangani proses penambahan karya seni baru ke database dan membuat lelang baru secara otomatis.

#### 3. `sp_tutup_lelang` - Prosedur untuk menutup lelang

**Implementasi di file**: `db.php` dan `close_auction.php`

```php
function tutupLelang($auction_id)
{
    global $conn;
    $query = "CALL sp_tutup_lelang($auction_id)";
    return mysqli_query($conn, $query);
}
```

Prosedur ini menangani proses penutupan lelang, menentukan pemenang, dan memperbarui status lelang.

### 🚨 Trigger

Trigger berfungsi sebagai mekanisme otomatis yang dijalankan ketika terjadi perubahan data, memastikan validasi dan konsistensi data.

#### 1. Trigger validasi penawaran

Meskipun tidak terlihat langsung dalam kode PHP, trigger ini diimplementasikan di database untuk memvalidasi penawaran sebelum dimasukkan ke tabel `bids`. Trigger ini memastikan:

- Penawaran lebih tinggi dari harga saat ini
- Lelang masih aktif
- Pembeli memiliki saldo yang cukup

Trigger ini diaktifkan saat prosedur `sp_place_bid` dijalankan.

#### 2. Trigger update harga lelang

Trigger ini secara otomatis memperbarui harga saat ini (`current_price`) pada tabel `auctions` ketika ada penawaran baru yang valid.

### 🔄 Transaction

Transaction memastikan bahwa serangkaian operasi database berjalan sebagai satu kesatuan yang utuh. Jika satu operasi gagal, semua operasi dibatalkan.

#### 1. Transaction untuk menambah dana

**Implementasi di file**: `add_funds.php`

```php
mysqli_begin_transaction($conn);

// Tambahkan saldo ke akun user
$update = "UPDATE users SET balance = balance + $amount WHERE id = $user_id";
mysqli_query($conn, $update);

// Simpan riwayat transaksi
$description = mysqli_real_escape_string($conn, "Deposit via " . ucfirst(str_replace('_', ' ', $payment_method)));
$log = "INSERT INTO transactions (user_id, type, amount, description, status)
            VALUES ($user_id, 'deposit', $amount, '$description', 'completed')";
mysqli_query($conn, $log);

// Ambil saldo terbaru
$balanceRes = mysqli_query($conn, "SELECT balance FROM users WHERE id = $user_id");
$row = mysqli_fetch_assoc($balanceRes);
$_SESSION['balance'] = $row['balance'];

mysqli_commit($conn);
```

Transaction ini memastikan bahwa penambahan saldo dan pencatatan riwayat transaksi berjalan sebagai satu kesatuan.

#### 2. Transaction untuk mengunggah karya seni

**Implementasi di file**: `upload.php`

```php
mysqli_begin_transaction($conn);

try {
    $artwork_sql = "INSERT INTO artworks (title, description, artist_id, image_path)
                    VALUES ('$title', '$description', $artist_id, '$relativePath')";
    mysqli_query($conn, $artwork_sql);
    $artwork_id = mysqli_insert_id($conn);

    $auction_sql = "INSERT INTO auctions (artwork_id, starting_price, current_price, status, start_time, end_time)
                    VALUES ($artwork_id, $starting_price, $starting_price, 'active', NOW(), '$end_time')";
    mysqli_query($conn, $auction_sql);

    mysqli_commit($conn);
    $_SESSION['success'] = "Karya berhasil ditambahkan";
} catch (Exception $e) {
    mysqli_rollback($conn);
    $_SESSION['error'] = "Error: " . $e->getMessage();

    // Hapus file yang sudah diupload jika terjadi error
    if (file_exists($targetPath)) {
        unlink($targetPath);
    }
}
```

Transaction ini memastikan bahwa penambahan karya seni dan pembuatan lelang baru berjalan sebagai satu kesatuan.

### 📊 Stored Function

Stored function digunakan untuk mengembalikan nilai berdasarkan perhitungan atau query tertentu.

#### 1. `hitung_total_bid` - Fungsi untuk menghitung total penawaran pada lelang

**Implementasi di file**: `db.php`

```php
function hitungTotalBid($auction_id)
{
    global $conn;
    $query = "SELECT hitung_total_bid($auction_id) as total";
    $result = mysqli_query($conn, $query);
    $row = mysqli_fetch_assoc($result);
    return $row['total'];
}
```

Fungsi ini mengembalikan jumlah total penawaran yang telah dilakukan pada suatu lelang.

### 🔄 Backup

Sistem backup otomatis tidak terlihat secara eksplisit dalam kode yang diberikan, namun dapat diimplementasikan dengan:

1. Script backup database yang dijalankan secara berkala menggunakan cron job
2. Backup file gambar karya seni secara berkala
3. Pencatatan log transaksi untuk pemulihan data jika terjadi kesalahan

## 🔧 Teknologi yang Digunakan

- **Backend**: PHP 7.4+
- **Database**: MySQL 8.0+
- **Frontend**: HTML5, CSS3, Bootstrap 5
- **JavaScript**: Vanilla JS

## 🚀 Cara Menjalankan Proyek

1. Clone repositori ini
2. Import skema database dari file `database.sql`
3. Konfigurasi koneksi database di `config/db.php`
4. Jalankan aplikasi menggunakan server web seperti Apache

## 📝 Kesimpulan

ArtHub mendemonstrasikan penggunaan konsep database lanjutan (stored procedure, trigger, transaction, dan stored function) untuk membangun sistem lelang karya seni yang aman dan andal. Dengan memanfaatkan fitur-fitur ini, sistem dapat memastikan integritas data dan konsistensi operasi bisnis.
