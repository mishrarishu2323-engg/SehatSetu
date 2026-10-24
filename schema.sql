-- SehatSetu database schema generated from the user's MySQL dump.
-- Run this file in MySQL Workbench after connecting to your MySQL server.
CREATE DATABASE IF NOT EXISTS sehatsetu_db CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci;
USE sehatsetu_db;

-- Table: users
CREATE TABLE `users` (
  `user_id` int NOT NULL AUTO_INCREMENT,
  `full_name` varchar(100) NOT NULL,
  `email` varchar(150) NOT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `password_hash` varchar(255) NOT NULL,
  `role` enum('patient','provider','admin') NOT NULL DEFAULT 'patient',
  `profile_image` varchar(500) DEFAULT NULL,
  `address` text,
  `city` varchar(100) DEFAULT NULL,
  `state` varchar(100) DEFAULT NULL,
  `pincode` varchar(10) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `email_verified` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`user_id`),
  UNIQUE KEY `email` (`email`),
  UNIQUE KEY `phone` (`phone`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Table: healthcare_facilities
CREATE TABLE `healthcare_facilities` (
  `facility_id` int NOT NULL AUTO_INCREMENT,
  `facility_name` varchar(200) NOT NULL,
  `facility_type` enum('hospital','clinic','phc','diagnostic_center','pharmacy','other') NOT NULL DEFAULT 'clinic',
  `description` text,
  `address` text NOT NULL,
  `city` varchar(100) NOT NULL,
  `state` varchar(100) NOT NULL,
  `pincode` varchar(10) DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `email` varchar(150) DEFAULT NULL,
  `website` varchar(255) DEFAULT NULL,
  `opening_hours` varchar(255) DEFAULT NULL,
  `emergency_services` tinyint(1) NOT NULL DEFAULT '0',
  `image_url` varchar(500) DEFAULT NULL,
  `verification_status` enum('pending','verified','rejected') NOT NULL DEFAULT 'pending',
  `created_by` int DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`facility_id`),
  KEY `fk_facility_creator` (`created_by`),
  KEY `idx_facility_city` (`city`),
  KEY `idx_facility_type` (`facility_type`),
  KEY `idx_facility_verification` (`verification_status`),
  CONSTRAINT `fk_facility_creator` FOREIGN KEY (`created_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Table: camp_organizers
CREATE TABLE `camp_organizers` (
  `organizer_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `organization_name` varchar(200) NOT NULL,
  `contact_person` varchar(100) DEFAULT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `email` varchar(150) DEFAULT NULL,
  `address` text,
  `city` varchar(100) DEFAULT NULL,
  `state` varchar(100) DEFAULT NULL,
  `is_verified` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`organizer_id`),
  KEY `fk_organizer_user` (`user_id`),
  KEY `idx_organizer_name` (`organization_name`),
  CONSTRAINT `fk_organizer_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Table: article_categories
CREATE TABLE `article_categories` (
  `category_id` int NOT NULL AUTO_INCREMENT,
  `category_name` varchar(100) NOT NULL,
  `description` text,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`category_id`),
  UNIQUE KEY `category_name` (`category_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Table: medical_camps
CREATE TABLE `medical_camps` (
  `camp_id` int NOT NULL AUTO_INCREMENT,
  `camp_name` varchar(200) NOT NULL,
  `description` text,
  `camp_type` varchar(100) DEFAULT NULL,
  `organizer_id` int DEFAULT NULL,
  `facility_id` int DEFAULT NULL,
  `camp_date` date NOT NULL,
  `start_time` time DEFAULT NULL,
  `end_time` time DEFAULT NULL,
  `address` text NOT NULL,
  `city` varchar(100) NOT NULL,
  `state` varchar(100) NOT NULL,
  `pincode` varchar(10) DEFAULT NULL,
  `registration_deadline` date DEFAULT NULL,
  `max_participants` int DEFAULT NULL,
  `is_free` tinyint(1) NOT NULL DEFAULT '1',
  `registration_fee` decimal(10,2) NOT NULL DEFAULT '0.00',
  `contact_phone` varchar(20) DEFAULT NULL,
  `image_url` varchar(500) DEFAULT NULL,
  `status` enum('upcoming','ongoing','completed','cancelled') NOT NULL DEFAULT 'upcoming',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`camp_id`),
  KEY `fk_camp_organizer` (`organizer_id`),
  KEY `fk_camp_facility` (`facility_id`),
  KEY `idx_camp_date` (`camp_date`),
  KEY `idx_camp_city` (`city`),
  KEY `idx_camp_status` (`status`),
  CONSTRAINT `fk_camp_facility` FOREIGN KEY (`facility_id`) REFERENCES `healthcare_facilities` (`facility_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_camp_organizer` FOREIGN KEY (`organizer_id`) REFERENCES `camp_organizers` (`organizer_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `chk_camp_capacity` CHECK (((`max_participants` is null) or (`max_participants` > 0)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Table: facility_services
CREATE TABLE `facility_services` (
  `service_id` int NOT NULL AUTO_INCREMENT,
  `facility_id` int NOT NULL,
  `service_name` varchar(150) NOT NULL,
  `description` text,
  `fee` decimal(10,2) NOT NULL DEFAULT '0.00',
  `is_available` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`service_id`),
  UNIQUE KEY `uq_facility_service` (`facility_id`,`service_name`),
  CONSTRAINT `fk_service_facility` FOREIGN KEY (`facility_id`) REFERENCES `healthcare_facilities` (`facility_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Table: health_articles
CREATE TABLE `health_articles` (
  `article_id` int NOT NULL AUTO_INCREMENT,
  `title` varchar(250) NOT NULL,
  `slug` varchar(280) NOT NULL,
  `summary` text,
  `content` longtext NOT NULL,
  `category_id` int DEFAULT NULL,
  `author_id` int DEFAULT NULL,
  `featured_image` varchar(500) DEFAULT NULL,
  `language` varchar(50) NOT NULL DEFAULT 'English',
  `status` enum('draft','published','archived') NOT NULL DEFAULT 'draft',
  `published_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`article_id`),
  UNIQUE KEY `slug` (`slug`),
  KEY `fk_article_category` (`category_id`),
  KEY `fk_article_author` (`author_id`),
  KEY `idx_article_status` (`status`),
  KEY `idx_article_published` (`published_at`),
  CONSTRAINT `fk_article_author` FOREIGN KEY (`author_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_article_category` FOREIGN KEY (`category_id`) REFERENCES `article_categories` (`category_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Table: health_awareness_events
CREATE TABLE `health_awareness_events` (
  `event_id` int NOT NULL AUTO_INCREMENT,
  `event_name` varchar(200) NOT NULL,
  `description` text,
  `topic` varchar(150) DEFAULT NULL,
  `organizer_id` int DEFAULT NULL,
  `facility_id` int DEFAULT NULL,
  `event_date` date NOT NULL,
  `start_time` time DEFAULT NULL,
  `end_time` time DEFAULT NULL,
  `venue` varchar(255) NOT NULL,
  `city` varchar(100) NOT NULL,
  `state` varchar(100) NOT NULL,
  `registration_required` tinyint(1) NOT NULL DEFAULT '0',
  `max_participants` int DEFAULT NULL,
  `contact_phone` varchar(20) DEFAULT NULL,
  `status` enum('upcoming','ongoing','completed','cancelled') NOT NULL DEFAULT 'upcoming',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`event_id`),
  KEY `fk_event_organizer` (`organizer_id`),
  KEY `fk_event_facility` (`facility_id`),
  KEY `idx_event_date` (`event_date`),
  KEY `idx_event_city` (`city`),
  CONSTRAINT `fk_event_facility` FOREIGN KEY (`facility_id`) REFERENCES `healthcare_facilities` (`facility_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_event_organizer` FOREIGN KEY (`organizer_id`) REFERENCES `camp_organizers` (`organizer_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Table: provider_profiles
CREATE TABLE `provider_profiles` (
  `provider_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `facility_id` int DEFAULT NULL,
  `provider_type` enum('doctor','nurse','specialist','health_worker','other') NOT NULL DEFAULT 'doctor',
  `specialization` varchar(150) DEFAULT NULL,
  `qualification` varchar(200) DEFAULT NULL,
  `registration_number` varchar(100) DEFAULT NULL,
  `experience_years` int NOT NULL DEFAULT '0',
  `consultation_fee` decimal(10,2) NOT NULL DEFAULT '0.00',
  `bio` text,
  `verification_status` enum('pending','verified','rejected') NOT NULL DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`provider_id`),
  UNIQUE KEY `user_id` (`user_id`),
  UNIQUE KEY `registration_number` (`registration_number`),
  KEY `fk_provider_facility` (`facility_id`),
  KEY `idx_provider_specialization` (`specialization`),
  CONSTRAINT `fk_provider_facility` FOREIGN KEY (`facility_id`) REFERENCES `healthcare_facilities` (`facility_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_provider_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `chk_provider_experience` CHECK ((`experience_years` >= 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Table: provider_availability
CREATE TABLE `provider_availability` (
  `availability_id` int NOT NULL AUTO_INCREMENT,
  `provider_id` int NOT NULL,
  `day_of_week` enum('Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday') NOT NULL,
  `start_time` time NOT NULL,
  `end_time` time NOT NULL,
  `is_available` tinyint(1) NOT NULL DEFAULT '1',
  `consultation_mode` enum('in_person','online','both') NOT NULL DEFAULT 'in_person',
  PRIMARY KEY (`availability_id`),
  UNIQUE KEY `uq_provider_schedule` (`provider_id`,`day_of_week`,`start_time`,`end_time`),
  CONSTRAINT `fk_availability_provider` FOREIGN KEY (`provider_id`) REFERENCES `provider_profiles` (`provider_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `chk_availability_time` CHECK ((`end_time` > `start_time`))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Table: camp_registrations
CREATE TABLE `camp_registrations` (
  `registration_id` int NOT NULL AUTO_INCREMENT,
  `camp_id` int NOT NULL,
  `user_id` int NOT NULL,
  `registration_date` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `participants_count` int NOT NULL DEFAULT '1',
  `status` enum('registered','confirmed','attended','cancelled','no_show') NOT NULL DEFAULT 'registered',
  `notes` text,
  PRIMARY KEY (`registration_id`),
  UNIQUE KEY `uq_camp_user` (`camp_id`,`user_id`),
  KEY `fk_registration_user` (`user_id`),
  KEY `idx_registration_status` (`status`),
  CONSTRAINT `fk_registration_camp` FOREIGN KEY (`camp_id`) REFERENCES `medical_camps` (`camp_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_registration_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `chk_participants_count` CHECK ((`participants_count` > 0))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Table: contact_messages
CREATE TABLE `contact_messages` (
  `message_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int DEFAULT NULL,
  `name` varchar(100) NOT NULL,
  `email` varchar(150) NOT NULL,
  `phone` varchar(20) DEFAULT NULL,
  `subject` varchar(200) NOT NULL,
  `message` text NOT NULL,
  `status` enum('new','in_progress','resolved','closed') NOT NULL DEFAULT 'new',
  `admin_reply` text,
  `replied_by` int DEFAULT NULL,
  `replied_at` datetime DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`message_id`),
  KEY `fk_contact_user` (`user_id`),
  KEY `fk_contact_admin` (`replied_by`),
  KEY `idx_contact_status` (`status`),
  KEY `idx_contact_created` (`created_at`),
  CONSTRAINT `fk_contact_admin` FOREIGN KEY (`replied_by`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_contact_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Table: facility_reviews
CREATE TABLE `facility_reviews` (
  `review_id` int NOT NULL AUTO_INCREMENT,
  `facility_id` int NOT NULL,
  `user_id` int NOT NULL,
  `rating` tinyint NOT NULL,
  `review_text` text,
  `status` enum('pending','approved','rejected') NOT NULL DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`review_id`),
  UNIQUE KEY `uq_facility_review_user` (`facility_id`,`user_id`),
  KEY `fk_review_user` (`user_id`),
  KEY `idx_review_status` (`status`),
  CONSTRAINT `fk_review_facility` FOREIGN KEY (`facility_id`) REFERENCES `healthcare_facilities` (`facility_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_review_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `chk_review_rating` CHECK ((`rating` between 1 and 5))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Table: notifications
CREATE TABLE `notifications` (
  `notification_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `title` varchar(200) NOT NULL,
  `message` text NOT NULL,
  `notification_type` enum('general','camp','health_article','facility','system') NOT NULL DEFAULT 'general',
  `related_id` int DEFAULT NULL,
  `is_read` tinyint(1) NOT NULL DEFAULT '0',
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`notification_id`),
  KEY `idx_notification_user_read` (`user_id`,`is_read`),
  KEY `idx_notification_created` (`created_at`),
  CONSTRAINT `fk_notification_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Table: user_favorites
CREATE TABLE `user_favorites` (
  `favorite_id` int NOT NULL AUTO_INCREMENT,
  `user_id` int NOT NULL,
  `facility_id` int NOT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`favorite_id`),
  UNIQUE KEY `uq_user_favorite` (`user_id`,`facility_id`),
  KEY `fk_favorite_facility` (`facility_id`),
  CONSTRAINT `fk_favorite_facility` FOREIGN KEY (`facility_id`) REFERENCES `healthcare_facilities` (`facility_id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `fk_favorite_user` FOREIGN KEY (`user_id`) REFERENCES `users` (`user_id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Table: admin_activity_logs
CREATE TABLE `admin_activity_logs` (
  `log_id` bigint NOT NULL AUTO_INCREMENT,
  `admin_id` int DEFAULT NULL,
  `action` varchar(150) NOT NULL,
  `entity_type` varchar(100) DEFAULT NULL,
  `entity_id` int DEFAULT NULL,
  `details` text,
  `ip_address` varchar(45) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`log_id`),
  KEY `idx_activity_admin` (`admin_id`),
  KEY `idx_activity_created` (`created_at`),
  KEY `idx_activity_entity` (`entity_type`,`entity_id`),
  CONSTRAINT `fk_activity_admin` FOREIGN KEY (`admin_id`) REFERENCES `users` (`user_id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
