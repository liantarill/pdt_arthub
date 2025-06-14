-- IMPLEMENTASI MYSQL FUNCTION
-- Function untuk menghitung total bid dalam suatu lelang
DELIMITER //

CREATE FUNCTION hitung_total_bid(auction_id_param INT) 
RETURNS DECIMAL(15,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE total_amount DECIMAL(15,2) DEFAULT 0.00;
    
    SELECT COALESCE(SUM(bid_amount), 0.00) INTO total_amount
    FROM bids 
    WHERE auction_id = auction_id_param;
    
    RETURN total_amount;
END //

DELIMITER ;

-- Function untuk mendapatkan bid tertinggi
DELIMITER //

CREATE FUNCTION get_highest_bid(auction_id_param INT) 
RETURNS DECIMAL(15,2)
READS SQL DATA
DETERMINISTIC
BEGIN
    DECLARE highest_bid DECIMAL(15,2) DEFAULT 0.00;
    
    SELECT COALESCE(MAX(bid_amount), 0.00) INTO highest_bid
    FROM bids 
    WHERE auction_id = auction_id_param;
    
    RETURN highest_bid;
END //

DELIMITER ;
