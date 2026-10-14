CREATE DATABASE IF NOT EXISTS room_booking_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE room_booking_db;

CREATE TABLE IF NOT EXISTS users (
 id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 full_name VARCHAR(120) NOT NULL,
 email VARCHAR(190) NULL UNIQUE,
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS rooms (
 id VARCHAR(20) PRIMARY KEY,
 name VARCHAR(120) NOT NULL,
 building VARCHAR(120) NOT NULL,
 floor VARCHAR(60) NOT NULL,
 capacity INT UNSIGNED NOT NULL DEFAULT 1,
 room_type ENUM('Study room','Computer lab','Meeting room') NOT NULL,
 equipment_json JSON NOT NULL,
 color VARCHAR(20) NOT NULL DEFAULT '#DCEAFE',
 is_active TINYINT(1) NOT NULL DEFAULT 1
) ENGINE=InnoDB;

CREATE TABLE IF NOT EXISTS bookings (
 id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
 room_id VARCHAR(20) NOT NULL,
 room_name VARCHAR(120) NOT NULL,
 booking_date DATE NOT NULL,
 start_time TIME NOT NULL,
 end_time TIME NOT NULL,
 purpose VARCHAR(255) NOT NULL,
 booked_by VARCHAR(120) NOT NULL,
 status ENUM('Confirmed','Pending','Cancelled') NOT NULL DEFAULT 'Confirmed',
 created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
 CONSTRAINT fk_bookings_room FOREIGN KEY (room_id) REFERENCES rooms(id),
 INDEX idx_booking_room_date (room_id, booking_date, status)
) ENGINE=InnoDB;

INSERT INTO rooms (id,name,building,floor,capacity,room_type,equipment_json,color) VALUES
('R101','Study Room 101','Learning Commons','1st floor',4,'Study room',JSON_ARRAY('Whiteboard','Display'),'#DCEAFE'),
('R204','Collaboration Room 204','Learning Commons','2nd floor',6,'Meeting room',JSON_ARRAY('Display','Video conferencing'),'#E8E2FF'),
('LAB3','Computer Lab 3','Technology Center','3rd floor',24,'Computer lab',JSON_ARRAY('24 PCs','Projector'),'#D9F4EA'),
('R310','Quiet Study Room 310','Library North','3rd floor',2,'Study room',JSON_ARRAY('Desk','Power outlets'),'#FFE9D7'),
('LAB2','Computer Lab 2','Technology Center','2nd floor',18,'Computer lab',JSON_ARRAY('18 PCs','Projector'),'#DDF3F8')
ON DUPLICATE KEY UPDATE name=VALUES(name), building=VALUES(building), floor=VALUES(floor),
 capacity=VALUES(capacity), room_type=VALUES(room_type), equipment_json=VALUES(equipment_json), color=VALUES(color);
