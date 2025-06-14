-- IMPLEMENTASI MYSQL STORED PROCEDURE
-- Procedure untuk menambah karya seni dan membuat lelang
DELIMITER //

CREATE PROCEDURE sp_tambah_karya_seni(
    IN p_title VARCHAR(200),
    IN p_description TEXT,
    IN p_artist_id INT,
    IN p_starting_price DECIMAL(15,2),
    IN p_image_path VARCHAR(500)
)
BEGIN
    DECLARE artwork_id INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Insert artwork
    INSERT INTO artworks (title, description, artist_id, image_path)
    VALUES (p_title, p_description, p_artist_id, p_image_path);
    
    SET artwork_id = LAST_INSERT_ID();
    
    -- Create auction (7 days from now)
    INSERT INTO auctions (artwork_id, starting_price, current_price, start_time, end_time)
    VALUES (artwork_id, p_starting_price, p_starting_price, NOW(), DATE_ADD(NOW(), INTERVAL 7 DAY));
    
    COMMIT;
END //

DELIMITER ;

-- Procedure untuk menutup lelang
DELIMITER //

CREATE PROCEDURE sp_tutup_lelang(IN p_auction_id INT)
BEGIN
    DECLARE v_winner_id INT DEFAULT NULL;
    DECLARE v_highest_bid DECIMAL(15,2) DEFAULT 0.00;
    DECLARE v_artist_id INT;
    DECLARE v_artwork_id INT;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Get auction details
    SELECT artwork_id INTO v_artwork_id FROM auctions WHERE id = p_auction_id;
    SELECT artist_id INTO v_artist_id FROM artworks WHERE id = v_artwork_id;
    
    -- Find winner (highest bidder)
    SELECT bidder_id, bid_amount INTO v_winner_id, v_highest_bid
    FROM bids 
    WHERE auction_id = p_auction_id 
    ORDER BY bid_amount DESC, bid_time ASC 
    LIMIT 1;
    
    -- Update auction status
    UPDATE auctions 
    SET status = 'closed', winner_id = v_winner_id, current_price = v_highest_bid
    WHERE id = p_auction_id;
    
    -- If there's a winner, process payment
    IF v_winner_id IS NOT NULL THEN
        -- Deduct from winner's balance
        UPDATE users SET balance = balance - v_highest_bid WHERE id = v_winner_id;
        
        -- Add to artist's balance (minus 10% commission)
        UPDATE users SET balance = balance + (v_highest_bid * 0.9) WHERE id = v_artist_id;
        
        -- Record transactions
        INSERT INTO transactions (user_id, auction_id, type, amount, description, status)
        VALUES (v_winner_id, p_auction_id, 'payment', v_highest_bid, 'Payment for artwork purchase', 'completed');
        
        INSERT INTO transactions (user_id, auction_id, type, amount, description, status)
        VALUES (v_artist_id, p_auction_id, 'deposit', v_highest_bid * 0.9, 'Payment received from artwork sale', 'completed');
    END IF;
    
    COMMIT;
END //

DELIMITER ;

-- Procedure untuk place bid dengan validasi
DELIMITER //

CREATE PROCEDURE sp_place_bid(
    IN p_auction_id INT,
    IN p_bidder_id INT,
    IN p_bid_amount DECIMAL(15,2)
)
BEGIN
    DECLARE v_current_price DECIMAL(15,2);
    DECLARE v_user_balance DECIMAL(15,2);
    DECLARE v_auction_status VARCHAR(20);
    DECLARE v_end_time DATETIME;
    
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;
    
    START TRANSACTION;
    
    -- Check auction status and current price
    SELECT current_price, status, end_time INTO v_current_price, v_auction_status, v_end_time
    FROM auctions WHERE id = p_auction_id;
    
    -- Check user balance
    SELECT balance INTO v_user_balance FROM users WHERE id = p_bidder_id;
    
    -- Validations
    IF v_auction_status != 'active' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Auction is not active';
    END IF;
    
    IF NOW() > v_end_time THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Auction has ended';
    END IF;
    
    IF p_bid_amount <= v_current_price THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Bid must be higher than current price';
    END IF;
    
    IF v_user_balance < p_bid_amount THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Insufficient balance';
    END IF;
    
    -- Place bid
    INSERT INTO bids (auction_id, bidder_id, bid_amount) 
    VALUES (p_auction_id, p_bidder_id, p_bid_amount);
    
    -- Update current price
    UPDATE auctions SET current_price = p_bid_amount WHERE id = p_auction_id;
    
    COMMIT;
END //

DELIMITER ;
