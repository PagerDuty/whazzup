--
-- Create Database: `health_check`
--

CREATE DATABASE IF NOT EXISTS `health_check`;

USE `health_check`;

--
-- Table structure for table `state`
--

CREATE TABLE IF NOT EXISTS `state` (
    `host_name` varchar(128) NOT NULL,
    `available` tinyint(1) NOT NULL DEFAULT '1',
    UNIQUE KEY `host_name` (`host_name`)
)

--
-- Insert current host into 'state' table
--

INSERT INTO `state` VALUES (@@hostname,1);

