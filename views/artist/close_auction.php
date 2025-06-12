<?php
session_start();
require_once '../../config/db.php';

header('Content-Type: application/json');

if (!isset($_SESSION['user_id']) || $_SESSION['role'] !== 'artist') {
    echo json_encode(['success' => false, 'message' => 'Unauthorized']);
    exit();
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['auction_id'])) {
    $auction_id = (int)$_POST['auction_id'];
    if (tutupLelang($conn, $auction_id)) {
        echo json_encode(['success' => true, 'message' => 'Auction closed successfully']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Failed to close auction']);
    }
} else {
    echo json_encode(['success' => false, 'message' => 'Invalid request']);
}
