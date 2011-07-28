-- MySQL dump 9.09
--
-- Host: localhost    Database: anagrammi
-- ------------------------------------------------------
-- Server version	4.0.16-standard

--
-- Table structure for table `word`
--

CREATE TABLE words_en (
  word varchar(255) NOT NULL default '',
  left_signature bigint(255) unsigned NOT NULL default '0',
  right_signature bigint(255) unsigned NOT NULL default '0',
  PRIMARY KEY  (word),
  KEY left_signature (left_signature),
  KEY right_signature (right_signature)
) TYPE=MyISAM;

