CREATE DATABASE IF NOT EXISTS expense_manager_db
  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE expense_manager_db;

CREATE TABLE IF NOT EXISTS transactions (
  id INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  title VARCHAR(160) NOT NULL,
  amount DECIMAL(14,2) NOT NULL,
  type ENUM('income','expense') NOT NULL,
  category VARCHAR(80) NOT NULL DEFAULT 'Other',
  transaction_date DATE NOT NULL,
  notes TEXT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  INDEX idx_transaction_date (transaction_date),
  INDEX idx_transaction_type (type)
) ENGINE=InnoDB;

INSERT INTO transactions (title, amount, type, category, transaction_date, notes) VALUES
('Monthly allowance', 2500000, 'income', 'Other', CURDATE(), 'Sample record - you can edit or delete it'),
('Lunch', 45000, 'expense', 'Food', CURDATE(), 'Sample record - you can edit or delete it');
