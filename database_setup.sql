-- SQL script to set up the bloom_db database schema
-- Prices are assumed to be in Ghana Cedis (GHS)

-- Ensure using the correct database (User should create this first)
-- CREATE DATABASE IF NOT EXISTS bloom_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
-- USE bloom_db;

-- Users Table
CREATE TABLE IF NOT EXISTS `users` (
  `user_id` INT AUTO_INCREMENT PRIMARY KEY,
  `username` VARCHAR(50) NOT NULL UNIQUE,
  `email` VARCHAR(100) NOT NULL UNIQUE,
  `password_hash` VARCHAR(255) NOT NULL,
  `loyalty_points` INT NOT NULL DEFAULT 0 COMMENT 'User loyalty points balance',
  `is_admin` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Flag to indicate admin privileges',
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Venues Table
CREATE TABLE IF NOT EXISTS `venues` (
  `venue_id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(100) NOT NULL,
  `address` VARCHAR(255),
  `city` VARCHAR(100),
  `seating_capacity` INT,
  `layout_info` TEXT COMMENT 'Could store JSON or other format for seating map'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Events Table
CREATE TABLE IF NOT EXISTS `events` (
  `event_id` INT AUTO_INCREMENT PRIMARY KEY,
  `title` VARCHAR(255) NOT NULL,
  `description` TEXT,
  `event_date` DATETIME NOT NULL,
  `venue_id` INT,
  `image_path` VARCHAR(255) COMMENT 'Path to uploaded image file relative to static folder',
  `category` VARCHAR(50), -- e.g., Concert, Theater, Sports
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`venue_id`) REFERENCES `venues`(`venue_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Movies Table
CREATE TABLE IF NOT EXISTS `movies` (
  `movie_id` INT AUTO_INCREMENT PRIMARY KEY,
  `title` VARCHAR(255) NOT NULL,
  `description` TEXT,
  `release_date` DATE,
  `duration_minutes` INT,
  `genre` VARCHAR(100),
  `rating` VARCHAR(10), -- e.g., PG-13, R
  `poster_path` VARCHAR(255) COMMENT 'Path to uploaded poster file relative to static folder',
  `trailer_url` VARCHAR(255),
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Showtimes Table (Links Movies to Venues at specific times)
CREATE TABLE IF NOT EXISTS `showtimes` (
  `showtime_id` INT AUTO_INCREMENT PRIMARY KEY,
  `movie_id` INT NOT NULL,
  `venue_id` INT NOT NULL,
  `show_datetime` DATETIME NOT NULL,
  FOREIGN KEY (`movie_id`) REFERENCES `movies`(`movie_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (`venue_id`) REFERENCES `venues`(`venue_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Ticket Types Table
CREATE TABLE IF NOT EXISTS `ticket_types` (
  `type_id` INT AUTO_INCREMENT PRIMARY KEY,
  `name` VARCHAR(50) NOT NULL UNIQUE COMMENT 'e.g., Standard, VIP, Family, Couple, Single',
  `description` TEXT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Event Ticket Prices Table (Associative table for M:N between Events and Ticket Types)
CREATE TABLE IF NOT EXISTS `event_ticket_prices` (
  `event_id` INT NOT NULL,
  `type_id` INT NOT NULL,
  `price` DECIMAL(10, 2) NOT NULL COMMENT 'Price in GHS',
  PRIMARY KEY (`event_id`, `type_id`),
  FOREIGN KEY (`event_id`) REFERENCES `events`(`event_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (`type_id`) REFERENCES `ticket_types`(`type_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Showtime Ticket Prices Table (Associative table for M:N between Showtimes and Ticket Types)
CREATE TABLE IF NOT EXISTS `showtime_ticket_prices` (
  `showtime_id` INT NOT NULL,
  `type_id` INT NOT NULL,
  `price` DECIMAL(10, 2) NOT NULL COMMENT 'Price in GHS',
  PRIMARY KEY (`showtime_id`, `type_id`),
  FOREIGN KEY (`showtime_id`) REFERENCES `showtimes`(`showtime_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (`type_id`) REFERENCES `ticket_types`(`type_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Seats Table (Represents individual seats in a venue)
CREATE TABLE IF NOT EXISTS `seats` (
  `seat_id` INT AUTO_INCREMENT PRIMARY KEY,
  `venue_id` INT NOT NULL,
  `seat_row` VARCHAR(10), -- e.g., 'A', 'B', 'AA'
  `seat_number` VARCHAR(10), -- e.g., '1', '2', '101'
  `seat_type` VARCHAR(50) DEFAULT 'Standard', -- e.g., Standard, VIP, Wheelchair Accessible
  `is_available` BOOLEAN DEFAULT TRUE COMMENT 'General availability, might be overridden by booking status',
  FOREIGN KEY (`venue_id`) REFERENCES `venues`(`venue_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Promotions Table
CREATE TABLE IF NOT EXISTS `promotions` (
  `promo_id` INT AUTO_INCREMENT PRIMARY KEY,
  `code` VARCHAR(50) UNIQUE NOT NULL COMMENT 'User-facing code to apply',
  `description` TEXT NOT NULL,
  `type` ENUM('PERCENT', 'FIXED', 'VOUCHER') NOT NULL COMMENT 'Type of discount/voucher',
  `value` DECIMAL(10, 2) NOT NULL COMMENT 'Percentage (e.g., 10 for 10%), Fixed amount (GHS), or Voucher value (GHS)',
  `start_date` DATETIME NULL,
  `expiry_date` DATETIME NULL,
  `max_uses` INT NULL COMMENT 'Overall maximum uses for this code',
  `current_uses` INT NOT NULL DEFAULT 0,
  `max_uses_per_user` INT NULL DEFAULT 1 COMMENT 'Max times a single user can use this code',
  `min_spend` DECIMAL(10, 2) NULL COMMENT 'Minimum cart total (GHS) to qualify',
  `required_ticket_type_id` INT NULL COMMENT 'Apply only if cart contains this ticket type',
  `required_item_id` INT NULL COMMENT 'Apply only if cart contains this specific event_id or movie_id',
  `required_quantity` INT NULL COMMENT 'Minimum quantity of an item needed',
  `is_active` BOOLEAN NOT NULL DEFAULT TRUE,
  `created_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`required_ticket_type_id`) REFERENCES `ticket_types`(`type_id`) ON DELETE SET NULL ON UPDATE CASCADE
  -- Note: required_item_id needs application logic to check against event/movie
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Bookings Table
CREATE TABLE IF NOT EXISTS `bookings` (
  `booking_id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `booking_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `sub_total` DECIMAL(10, 2) NOT NULL COMMENT 'Total before discounts (GHS)',
  `discount_amount` DECIMAL(10, 2) NOT NULL DEFAULT 0.00 COMMENT 'Amount discounted (GHS)',
  `total_amount` DECIMAL(10, 2) NOT NULL COMMENT 'Final amount paid (GHS)',
  `applied_promo_id` INT NULL COMMENT 'Which promotion was applied to this booking',
  `status` VARCHAR(50) DEFAULT 'Pending' COMMENT 'e.g., Pending, Confirmed, Cancelled, Completed',
  `points_earned` INT NOT NULL DEFAULT 0,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (`applied_promo_id`) REFERENCES `promotions`(`promo_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Tickets Table (Represents individual tickets sold)
CREATE TABLE IF NOT EXISTS `tickets` (
  `ticket_id` INT AUTO_INCREMENT PRIMARY KEY,
  `booking_id` INT NOT NULL,
  `event_id` INT NULL COMMENT 'Null if it is a movie ticket',
  `showtime_id` INT NULL COMMENT 'Null if it is an event ticket',
  `seat_id` INT NULL COMMENT 'Null for general admission events',
  `type_id` INT NOT NULL COMMENT 'FK to ticket_types',
  `price` DECIMAL(10, 2) NOT NULL COMMENT 'Actual price paid for this ticket (GHS)',
  `ticket_serial` VARCHAR(100) UNIQUE NOT NULL COMMENT 'Unique identifier for this specific ticket',
  `qr_code_data` VARCHAR(255) UNIQUE COMMENT 'Data embedded in the QR code, often the serial',
  `current_owner_user_id` INT NOT NULL COMMENT 'Who currently owns the ticket (for trading)',
  `is_tradeable` BOOLEAN NOT NULL DEFAULT FALSE COMMENT 'Can this ticket be listed for trade?',
  `issued_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`booking_id`) REFERENCES `bookings`(`booking_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (`event_id`) REFERENCES `events`(`event_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY (`showtime_id`) REFERENCES `showtimes`(`showtime_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY (`seat_id`) REFERENCES `seats`(`seat_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY (`type_id`) REFERENCES `ticket_types`(`type_id`) ON DELETE RESTRICT ON UPDATE CASCADE, -- Prevent deleting type if tickets exist
  FOREIGN KEY (`current_owner_user_id`) REFERENCES `users`(`user_id`) ON DELETE RESTRICT ON UPDATE CASCADE -- Prevent deleting user if they own tickets
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- User Promotions Table (Tracks usage of promotions per user)
CREATE TABLE IF NOT EXISTS `user_promotions` (
  `user_promo_id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `promo_id` INT NOT NULL,
  `booking_id` INT NOT NULL COMMENT 'The booking where this promo was used',
  `used_at` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE KEY `user_promo_use` (`user_id`, `promo_id`, `booking_id`), -- Ensure unique usage record
  FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (`promo_id`) REFERENCES `promotions`(`promo_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (`booking_id`) REFERENCES `bookings`(`booking_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Loyalty Transactions Table
CREATE TABLE IF NOT EXISTS `loyalty_transactions` (
  `transaction_id` INT AUTO_INCREMENT PRIMARY KEY,
  `user_id` INT NOT NULL,
  `points_change` INT NOT NULL COMMENT 'Positive for earned, negative for spent',
  `reason` VARCHAR(100) NOT NULL COMMENT 'e.g., Booking Purchase, Point Redemption, Admin Adjustment',
  `related_booking_id` INT NULL,
  `transaction_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (`user_id`) REFERENCES `users`(`user_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (`related_booking_id`) REFERENCES `bookings`(`booking_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Ticket Trades Table
CREATE TABLE IF NOT EXISTS `ticket_trades` (
  `trade_id` INT AUTO_INCREMENT PRIMARY KEY,
  `listing_ticket_id` INT UNIQUE NOT NULL COMMENT 'The ticket being offered for trade',
  `listing_user_id` INT NOT NULL COMMENT 'The user offering the ticket',
  `requested_ticket_id` INT NULL COMMENT 'Optional: Specific ticket the lister wants in return',
  `requesting_user_id` INT NULL COMMENT 'The user who initiated the trade request',
  `offered_ticket_id` INT NULL COMMENT 'The ticket offered by the requesting user (if any)',
  `status` ENUM('LISTED', 'REQUESTED', 'COMPLETED', 'CANCELLED', 'REJECTED') NOT NULL DEFAULT 'LISTED',
  `listing_date` TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  `request_date` TIMESTAMP NULL,
  `trade_fee` DECIMAL(10, 2) NOT NULL DEFAULT 0.00 COMMENT 'Admin-defined fee for completing the trade (GHS)',
  `completion_date` TIMESTAMP NULL,
  FOREIGN KEY (`listing_ticket_id`) REFERENCES `tickets`(`ticket_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (`listing_user_id`) REFERENCES `users`(`user_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (`requested_ticket_id`) REFERENCES `tickets`(`ticket_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY (`requesting_user_id`) REFERENCES `users`(`user_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  FOREIGN KEY (`offered_ticket_id`) REFERENCES `tickets`(`ticket_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- --- INDEXES ---

-- Add indexes for frequently queried columns and foreign keys
ALTER TABLE `users` ADD INDEX `idx_user_email` (`email`);
ALTER TABLE `events` ADD INDEX `idx_event_date` (`event_date`);
ALTER TABLE `events` ADD INDEX `idx_event_venue` (`venue_id`);
ALTER TABLE `movies` ADD INDEX `idx_movie_title` (`title`);
ALTER TABLE `showtimes` ADD INDEX `idx_show_datetime` (`show_datetime`);
ALTER TABLE `showtimes` ADD INDEX `idx_show_movie` (`movie_id`);
ALTER TABLE `showtimes` ADD INDEX `idx_show_venue` (`venue_id`);
ALTER TABLE `seats` ADD INDEX `idx_seat_location` (`venue_id`, `seat_row`, `seat_number`);
ALTER TABLE `bookings` ADD INDEX `idx_booking_user` (`user_id`);
ALTER TABLE `bookings` ADD INDEX `idx_booking_promo` (`applied_promo_id`);
ALTER TABLE `tickets` ADD INDEX `idx_ticket_booking` (`booking_id`);
ALTER TABLE `tickets` ADD INDEX `idx_ticket_event` (`event_id`);
ALTER TABLE `tickets` ADD INDEX `idx_ticket_showtime` (`showtime_id`);
ALTER TABLE `tickets` ADD INDEX `idx_ticket_owner` (`current_owner_user_id`);
ALTER TABLE `tickets` ADD INDEX `idx_ticket_serial` (`ticket_serial`);
ALTER TABLE `promotions` ADD INDEX `idx_promo_code` (`code`);
ALTER TABLE `promotions` ADD INDEX `idx_promo_expiry` (`expiry_date`);
ALTER TABLE `user_promotions` ADD INDEX `idx_userpromo_user` (`user_id`);
ALTER TABLE `user_promotions` ADD INDEX `idx_userpromo_promo` (`promo_id`);
ALTER TABLE `loyalty_transactions` ADD INDEX `idx_loyalty_user` (`user_id`);
ALTER TABLE `ticket_trades` ADD INDEX `idx_trade_listing_user` (`listing_user_id`);
ALTER TABLE `ticket_trades` ADD INDEX `idx_trade_status` (`status`);


-- Note: This schema is more detailed based on the plan.
-- Further normalization (e.g., separate tables for genres, categories) could be considered for larger scale.
-- ON DELETE/UPDATE actions for Foreign Keys should be reviewed based on desired data integrity rules.
