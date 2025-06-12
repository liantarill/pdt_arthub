<?php
session_start();
require_once '../../config/db.php';

// Check jika user belum login atau bukan buyer
if (!isset($_SESSION['user_id']) || $_SESSION['role'] !== 'buyer') {
    header('Location: views/auth/login.php');
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    $auction_id = (int)$_POST['auction_id'];
    $bidder_id = $_SESSION['user_id'];
    $bid_amount = (float)$_POST['bid_amount'];

    // Panggil stored procedure 
    $query = "CALL sp_place_bid($auction_id, $bidder_id, $bid_amount)";
    $result = mysqli_query($conn, $query);

    if ($result) {
        $_SESSION['success'] = "Bid placed successfully!";
    } else {
        $_SESSION['error'] = "Failed to place bid: " . mysqli_error($conn);
    }

    header("Location: ../../auction_details.php?id=" . $auction_id);
    exit();
}

header('Location: index.php');
exit();
