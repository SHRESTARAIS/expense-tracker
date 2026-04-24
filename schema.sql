-- ════════════════════════════════════════════════════════════════════════════
-- schema.sql – MySQL Database Schema for Cloud SQL
-- Run once: mysql -u root -p expense_db < schema.sql
-- ════════════════════════════════════════════════════════════════════════════

-- Create and select database
CREATE DATABASE IF NOT EXISTS expense_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE expense_db;

-- ── Users table ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS users (
    id            INT AUTO_INCREMENT PRIMARY KEY,
    username      VARCHAR(80)  NOT NULL UNIQUE,
    email         VARCHAR(120) NOT NULL UNIQUE,
    password_hash VARCHAR(256) NOT NULL,
    created_at    DATETIME     DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_email (email),
    INDEX idx_username (username)
) ENGINE=InnoDB;

-- ── Transactions table ────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS transactions (
    id          INT AUTO_INCREMENT PRIMARY KEY,
    user_id     INT          NOT NULL,
    title       VARCHAR(120) NOT NULL,
    amount      DECIMAL(12,2) NOT NULL,
    type        ENUM('income','expense') NOT NULL,
    category    VARCHAR(60)  NOT NULL,
    date        DATE         NOT NULL,
    description TEXT,
    receipt_url VARCHAR(512),
    created_at  DATETIME     DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    INDEX idx_user_date (user_id, date),
    INDEX idx_user_type (user_id, type),
    INDEX idx_user_category (user_id, category)
) ENGINE=InnoDB;

-- ── Budgets table ─────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS budgets (
    id         INT AUTO_INCREMENT PRIMARY KEY,
    user_id    INT NOT NULL,
    category   VARCHAR(60) NOT NULL,
    month      TINYINT     NOT NULL CHECK (month BETWEEN 1 AND 12),
    year       SMALLINT    NOT NULL,
    limit_amt  DECIMAL(12,2) NOT NULL,
    created_at DATETIME    DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY uq_budget (user_id, category, month, year)
) ENGINE=InnoDB;

-- ════════════════════════════════════════════════════════════════════════════
-- Sample test data (optional – remove in production)
-- ════════════════════════════════════════════════════════════════════════════

-- Password for test user: "password123" (bcrypt hash)
INSERT IGNORE INTO users (username, email, password_hash) VALUES
  ('testuser', 'test@example.com',
   '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/qdM8Ypz.PqS7fJSCK');

-- Sample transactions for testuser (id=1)
INSERT IGNORE INTO transactions (user_id, title, amount, type, category, date, description) VALUES
  (1, 'Monthly Salary',    50000.00, 'income',  'Salary',          CURDATE(), 'Main job salary'),
  (1, 'Grocery Shopping',   3200.00, 'expense', 'Food & Dining',   CURDATE(), 'Weekly groceries'),
  (1, 'Electric Bill',      1500.00, 'expense', 'Housing & Utilities', CURDATE(), 'Monthly electricity'),
  (1, 'Movie Tickets',       800.00, 'expense', 'Entertainment',   CURDATE(), 'Weekend outing'),
  (1, 'Freelance Project', 15000.00, 'income',  'Freelance',       CURDATE(), 'Web design project'),
  (1, 'Metro Card',          500.00, 'expense', 'Transport',       CURDATE(), 'Monthly metro pass'),
  (1, 'Gym Membership',     2000.00, 'expense', 'Health & Medical',CURDATE(), 'Monthly gym fee'),
  (1, 'Online Course',      3999.00, 'expense', 'Education',       CURDATE(), 'Cloud computing course');

-- Sample budgets for testuser
INSERT IGNORE INTO budgets (user_id, category, month, year, limit_amt) VALUES
  (1, 'Food & Dining',    MONTH(CURDATE()), YEAR(CURDATE()), 5000.00),
  (1, 'Entertainment',    MONTH(CURDATE()), YEAR(CURDATE()), 2000.00),
  (1, 'Transport',        MONTH(CURDATE()), YEAR(CURDATE()), 1500.00),
  (1, 'Health & Medical', MONTH(CURDATE()), YEAR(CURDATE()), 3000.00);
