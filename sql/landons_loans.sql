-- Landon's Loans Database Schema
-- Run this SQL to create the required tables

CREATE TABLE IF NOT EXISTS `landons_credit_scores` (
    `citizenid` varchar(50) NOT NULL,
    `score` int(11) NOT NULL DEFAULT 650,
    `liquidity_points` int(11) NOT NULL DEFAULT 0,
    `loan_points` int(11) NOT NULL DEFAULT 0,
    `payment_history_points` int(11) NOT NULL DEFAULT 150,
    `utilization_points` int(11) NOT NULL DEFAULT 0,
    `age_points` int(11) NOT NULL DEFAULT 0,
    `account_created` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `last_updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `landons_loans` (
    `loan_id` int(11) NOT NULL AUTO_INCREMENT,
    `citizenid` varchar(50) NOT NULL,
    `amount` int(11) NOT NULL,
    `original_amount` int(11) NOT NULL,
    `interest_rate` decimal(5,2) NOT NULL,
    `balance` int(11) NOT NULL,
    `daily_payment` int(11) NOT NULL,
    `term_days` int(11) NOT NULL,
    `days_remaining` int(11) NOT NULL,
    `loan_type` enum('automated','player') NOT NULL DEFAULT 'automated',
    `officer_citizenid` varchar(50) DEFAULT NULL,
    `officer_name` varchar(100) DEFAULT NULL,
    `status` enum('active','paid','defaulted') NOT NULL DEFAULT 'active',
    `next_payment_due` datetime NOT NULL,
    `missed_payments` int(11) NOT NULL DEFAULT 0,
    `late_fees` int(11) NOT NULL DEFAULT 0,
    `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`loan_id`),
    KEY `citizenid` (`citizenid`),
    KEY `status` (`status`),
    KEY `next_payment_due` (`next_payment_due`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `landons_payments` (
    `payment_id` int(11) NOT NULL AUTO_INCREMENT,
    `loan_id` int(11) NOT NULL,
    `citizenid` varchar(50) NOT NULL,
    `amount` int(11) NOT NULL,
    `payment_type` enum('automatic','manual','early') NOT NULL DEFAULT 'automatic',
    `status` enum('completed','failed','pending') NOT NULL DEFAULT 'completed',
    `date` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `processed_by` varchar(50) DEFAULT NULL,
    PRIMARY KEY (`payment_id`),
    KEY `loan_id` (`loan_id`),
    KEY `citizenid` (`citizenid`),
    KEY `date` (`date`),
    FOREIGN KEY (`loan_id`) REFERENCES `landons_loans` (`loan_id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `landons_company_account` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `total_balance` bigint(20) NOT NULL DEFAULT 0,
    `daily_profit` int(11) NOT NULL DEFAULT 0,
    `total_loans_issued` int(11) NOT NULL DEFAULT 0,
    `total_defaults` int(11) NOT NULL DEFAULT 0,
    `last_updated` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

CREATE TABLE IF NOT EXISTS `landons_company_logs` (
    `log_id` int(11) NOT NULL AUTO_INCREMENT,
    `type` enum('loan_issued','payment_received','default','profit','expense') NOT NULL,
    `amount` int(11) NOT NULL,
    `description` text NOT NULL,
    `citizenid` varchar(50) DEFAULT NULL,
    `officer_citizenid` varchar(50) DEFAULT NULL,
    `loan_id` int(11) DEFAULT NULL,
    `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`log_id`),
    KEY `type` (`type`),
    KEY `citizenid` (`citizenid`),
    KEY `created_at` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Insert initial company account record
INSERT INTO `landons_company_account` (`total_balance`) VALUES (1000000) ON DUPLICATE KEY UPDATE `id` = `id`;

-- Add indexes for performance
ALTER TABLE `landons_loans` ADD INDEX `idx_status_next_payment` (`status`, `next_payment_due`);
ALTER TABLE `landons_credit_scores` ADD INDEX `idx_last_updated` (`last_updated`);
ALTER TABLE `landons_payments` ADD INDEX `idx_loan_date` (`loan_id`, `date`);
