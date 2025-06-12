<?php
session_start();
require_once '../../config/db.php';

if (!isset($_SESSION['user_id']) || $_SESSION['role'] !== 'artist') {
    header('Location: ../auth/login.php');
    exit();
}

$artist_id = $_SESSION['user_id'];

if ($_SERVER['REQUEST_METHOD'] !== 'POST' || !isset($_POST['add_artwork'])) {
    header("Location: dashboard.php");
    $_SESSION['error'] = "Permintaan tidak valid";
    exit();
}

$title = mysqli_real_escape_string($conn, $_POST['title']);
$description = mysqli_real_escape_string($conn, $_POST['description']);
$starting_price = (float) $_POST['starting_price'];
$image = $_FILES['artwork_image'];
$end_time = mysqli_real_escape_string($conn, $_POST['end_time']);

// Validasi
if (!$title || !$description || $starting_price <= 0 || !$image['tmp_name']) {
    $_SESSION['error'] = "Field wajib diisi semua";
    header("Location: dashboard.php");
    exit();
}

// Buat direktori jika belum ada
$uploadDir = '../../assets/uploads/';
if (!is_dir($uploadDir)) {
    mkdir($uploadDir, 0755, true);
}

$newName = uniqid('art_') . '.' . strtolower(pathinfo($image['name'], PATHINFO_EXTENSION));
$targetPath = $uploadDir . $newName;
$relativePath = 'assets/uploads/' . $newName;

if (!move_uploaded_file($image['tmp_name'], $targetPath)) {
    $_SESSION['error'] = "Gagal mengunggah gambar";
    header("Location: dashboard.php");
    exit();
}

// Simpan ke DB
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

header("Location: dashboard.php");
exit();
