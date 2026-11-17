/*M!999999\- enable the sandbox mode */ 
-- MariaDB dump 10.19  Distrib 10.11.19-MariaDB, for debian-linux-gnu (x86_64)
--
-- Host: localhost    Database: radius
-- ------------------------------------------------------
-- Server version	10.11.19-MariaDB-ubu2204

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Current Database: `radius`
--

CREATE DATABASE /*!32312 IF NOT EXISTS*/ `radius` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci */;

USE `radius`;

--
-- Table structure for table `audit_logs`
--

DROP TABLE IF EXISTS `audit_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `audit_logs` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `actor_username` varchar(64) NOT NULL COMMENT 'Admin thực hiện hành động',
  `action` varchar(64) NOT NULL COMMENT 'Tên hành động (CREATE_USER, CHANGE_VLAN, UNLOCK, etc.)',
  `target` varchar(128) NOT NULL COMMENT 'Đối tượng bị tác động (username hoặc group)',
  `old_value` text DEFAULT NULL COMMENT 'Giá trị cũ trước khi sửa',
  `new_value` text DEFAULT NULL COMMENT 'Giá trị mới sau khi sửa',
  `ip_address` varchar(45) NOT NULL COMMENT 'IP của người thực hiện',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `prev_hash` varchar(64) NOT NULL DEFAULT '0000000000000000000000000000000000000000000000000000000000000000',
  `record_hash` varchar(64) NOT NULL DEFAULT '0000000000000000000000000000000000000000000000000000000000000000',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=541 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `audit_logs`
--

LOCK TABLES `audit_logs` WRITE;
/*!40000 ALTER TABLE `audit_logs` DISABLE KEYS */;
INSERT INTO `audit_logs` VALUES
(1,'SYSTEM_INIT','INIT_DATABASE','SCHEMA_AND_POLICIES',NULL,'Khoi tao thanh cong 4 nhom VLAN mac dinh','127.0.0.1','2026-11-14 12:22:48','0000000000000000000000000000000000000000000000000000000000000000','80b95717c1720fad187d77600e27dadd9b352fbeabb64f39b1360a15daf6c3e8'),
(2,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.28.41.1','2026-11-14 12:23:23','80b95717c1720fad187d77600e27dadd9b352fbeabb64f39b1360a15daf6c3e8','8fa835d8d8fcea243a98b15e060ef19fbd8fad8cd813346114e4bd600c3d1fa4'),
(3,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.28.41.1','2026-11-14 12:31:13','8fa835d8d8fcea243a98b15e060ef19fbd8fad8cd813346114e4bd600c3d1fa4','2f2024a58d6ab102e763e23c2c08e1b71653b23b689e5c6d8384fb89ec3c1b95'),
(4,'admin_tester','TEST_ACTION_CHAIN_1','SYSTEM','','Test payload 1','192.168.1.100','2026-11-14 19:02:10','2f2024a58d6ab102e763e23c2c08e1b71653b23b689e5c6d8384fb89ec3c1b95','a0fc314b12e6e75c5f7c75081afcb210da319112405b43b020599789464c2f1b'),
(5,'admin_tester','TEST_ACTION_CHAIN_2','SYSTEM','','Test payload 2','192.168.1.100','2026-11-14 19:02:10','a0fc314b12e6e75c5f7c75081afcb210da319112405b43b020599789464c2f1b','ed1a64556b9a5fd4b61cc92d4081a5be3dd4feffb712869f7580f30a2241fe8b'),
(6,'SYSTEM_ACTIVE_DEFENSE','AUTO_QUARANTINE_BRUTEFORCE','student02','Group: sinhvien','Group: quarantine (VLAN 99)','127.0.0.1','2026-11-14 19:02:10','ed1a64556b9a5fd4b61cc92d4081a5be3dd4feffb712869f7580f30a2241fe8b','677efb240ba062ce197b9e4d12996ed75e06a2eaf3b89d01a3f216579244eedd'),
(7,'admin_test','UNLOCK_USER','student02','Group: quarantine','Group: sinhvien','127.0.0.1','2026-11-14 19:02:10','677efb240ba062ce197b9e4d12996ed75e06a2eaf3b89d01a3f216579244eedd','259f10b78d79593377b39ab7e959f79554af9bb345eed58150df5751d327abb7'),
(8,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','127.0.0.1','2026-11-14 19:04:18','259f10b78d79593377b39ab7e959f79554af9bb345eed58150df5751d327abb7','4ee2b391aa5a88b1ddb4e4aacaf1bfa9c8d20338a1d3d56059fa041bf152aae4'),
(9,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','127.0.0.1','2026-11-14 19:04:25','4ee2b391aa5a88b1ddb4e4aacaf1bfa9c8d20338a1d3d56059fa041bf152aae4','e8fba059c9bc48f802d6e6fefb67e5f7cf981ce8ff360fdaacfefe1ca5efe652'),
(10,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','127.0.0.1','2026-11-14 19:04:34','e8fba059c9bc48f802d6e6fefb67e5f7cf981ce8ff360fdaacfefe1ca5efe652','2f70d0fa2767ae213d16c536eac8df55819b5485c222fcd6f9c982d3673953d8'),
(11,'admin_tester','TEST_ACTION_CHAIN_1','SYSTEM','','Test payload 1','192.168.1.100','2026-11-15 02:30:31','2f70d0fa2767ae213d16c536eac8df55819b5485c222fcd6f9c982d3673953d8','c0f027ff67aaf1dcab4f2cc6e1f875ee9a05a03e5ef6b949fe5d6038be1f93ce'),
(12,'admin_tester','TEST_ACTION_CHAIN_2','SYSTEM','','Test payload 2','192.168.1.100','2026-11-15 02:30:31','c0f027ff67aaf1dcab4f2cc6e1f875ee9a05a03e5ef6b949fe5d6038be1f93ce','93bd1c20e4a67b7b771518868f8f600da2e2d9592ab42214528db7a9c4afd1c5'),
(13,'SYSTEM_ACTIVE_DEFENSE','AUTO_QUARANTINE_BRUTEFORCE','student02','Group: sinhvien','Group: quarantine (VLAN 99)','127.0.0.1','2026-11-15 02:30:31','93bd1c20e4a67b7b771518868f8f600da2e2d9592ab42214528db7a9c4afd1c5','51bd4a5afb684f6fe99478ce5b69fcff0197c7bbbbdcc7120667c45f6f5369f3'),
(14,'admin_test','UNLOCK_USER','student02','Group: quarantine','Group: sinhvien','127.0.0.1','2026-11-15 02:30:31','51bd4a5afb684f6fe99478ce5b69fcff0197c7bbbbdcc7120667c45f6f5369f3','0936bb5069edf0ea8156eedf6e8419a45e01eb3a28215b4244cebb7a3ab989ee'),
(15,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 02:31:01','0936bb5069edf0ea8156eedf6e8419a45e01eb3a28215b4244cebb7a3ab989ee','eb4887a92c773634742d17cee9e7cc8a2888472e75af51520912b1f281f5d6f3'),
(16,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 02:45:09','eb4887a92c773634742d17cee9e7cc8a2888472e75af51520912b1f281f5d6f3','d879f08176e9c0b0c1eaefc2300384d09da19251aa2eb6503b461baf0c38fdf2'),
(17,'UNKNOWN','DASHBOARD_LOGIN_FAILED','DASHBOARD','Username không tồn tại: ghost_admin_fake','IP 127.0.0.1 thử sai 1/5','127.0.0.1','2026-11-15 02:45:25','d879f08176e9c0b0c1eaefc2300384d09da19251aa2eb6503b461baf0c38fdf2','0daa4e8423f34f991bb5fa10375d18970f588c5f7a6f7b68ca9ae2e003cfeda0'),
(18,'admin','DASHBOARD_LOGIN_FAILED','DASHBOARD','Lần sai thứ 2/5','Còn 3 lần thử trước khi bị khóa','127.0.0.1','2026-11-15 02:45:25','0daa4e8423f34f991bb5fa10375d18970f588c5f7a6f7b68ca9ae2e003cfeda0','a50fbbe4f7084667eb211021f258b5fc4b28b2280da47322a723728668a34534'),
(19,'admin_tester','TEST_ACTION_CHAIN_1','SYSTEM','','Test payload 1','192.168.1.100','2026-11-15 02:45:30','a50fbbe4f7084667eb211021f258b5fc4b28b2280da47322a723728668a34534','9e98e6850a248db3af40ab3e33e120a17bac9bfe3f27e81c43d59bd12dd24283'),
(20,'admin_tester','TEST_ACTION_CHAIN_2','SYSTEM','','Test payload 2','192.168.1.100','2026-11-15 02:45:30','9e98e6850a248db3af40ab3e33e120a17bac9bfe3f27e81c43d59bd12dd24283','e293ca61ac511152dab74552f7dcb8e0424fac3011c9aee18ff76a0d1556c654'),
(21,'admin_tester','TEST_ACTION_CHAIN_1','SYSTEM','','Test payload 1','192.168.1.100','2026-11-15 02:45:49','e293ca61ac511152dab74552f7dcb8e0424fac3011c9aee18ff76a0d1556c654','283e8dcf104064c5a318cef2e253836b151f9dddaaec4f20e42604b2e68305f2'),
(22,'admin_tester','TEST_ACTION_CHAIN_2','SYSTEM','','Test payload 2','192.168.1.100','2026-11-15 02:45:49','283e8dcf104064c5a318cef2e253836b151f9dddaaec4f20e42604b2e68305f2','f6bbf736a4229bc2f3e374ed9f97b0aff033bf5462323a183b92db01368c3018'),
(23,'SYSTEM_ACTIVE_DEFENSE','AUTO_QUARANTINE_BRUTEFORCE','sv_test','Group: sinhvien','Group: quarantine (VLAN 99)','127.0.0.1','2026-11-15 02:45:49','f6bbf736a4229bc2f3e374ed9f97b0aff033bf5462323a183b92db01368c3018','e285697c9ed6e3fbb7cfa532c0623820422fb5facb1bb73247169c28aece417c'),
(24,'admin_test','UNLOCK_USER','sv_test','Group: quarantine','Group: sinhvien','127.0.0.1','2026-11-15 02:45:49','e285697c9ed6e3fbb7cfa532c0623820422fb5facb1bb73247169c28aece417c','5e4aee6ccfe8448a514a98ad6bb0c30c04b86493909f542f8421fca26a8a8366'),
(25,'admin','CREATE_USER','sv_vinh','','Group: sinhvien, Name: Nguyễn Văn B','172.19.0.1','2026-11-15 02:48:16','5e4aee6ccfe8448a514a98ad6bb0c30c04b86493909f542f8421fca26a8a8366','760990c4ba000c6f33fa67d1d8c96b2c7ac874a6cbfebe8f76e2f2ad8cbb89dd'),
(26,'SYSTEM_ACTIVE_DEFENSE','AUTO_QUARANTINE_BRUTEFORCE','sv_vinh','Group: sinhvien','Group: quarantine (VLAN 99)','127.0.0.1','2026-11-15 02:48:25','760990c4ba000c6f33fa67d1d8c96b2c7ac874a6cbfebe8f76e2f2ad8cbb89dd','426b8b74164d4a6d202c3a18ff2191c8c741d15992d6e34c1bcf99e614cd5737'),
(27,'auditor','DASHBOARD_LOGIN','SYSTEM','','Login success as auditor','172.19.0.1','2026-11-15 02:53:41','426b8b74164d4a6d202c3a18ff2191c8c741d15992d6e34c1bcf99e614cd5737','3f077aed8a7eb376ccfbc04c73c6275d8ac42ddc899e48c102aa8e1919fb553c'),
(28,'UNKNOWN','DASHBOARD_LOGIN_FAILED','DASHBOARD','Username không tồn tại: sv_vinh','IP 172.19.0.1 thử sai 1/5','172.19.0.1','2026-11-15 03:07:15','3f077aed8a7eb376ccfbc04c73c6275d8ac42ddc899e48c102aa8e1919fb553c','45b75905fcb841aaa021245d9f4be837a8c4d840aaf4bc7a971b18076b95b56b'),
(29,'UNKNOWN','DASHBOARD_LOGIN_FAILED','DASHBOARD','Username không tồn tại: sv_vinh','IP 172.19.0.1 thử sai 2/5','172.19.0.1','2026-11-15 03:07:40','45b75905fcb841aaa021245d9f4be837a8c4d840aaf4bc7a971b18076b95b56b','823ba475a900b1e2b6c735cebe4bfc855052a2dfe532c6a6aebc86b9c297d3f3'),
(30,'auditor','DASHBOARD_LOGIN','SYSTEM','','Login success as auditor','172.19.0.1','2026-11-15 03:08:12','823ba475a900b1e2b6c735cebe4bfc855052a2dfe532c6a6aebc86b9c297d3f3','787508cdc52d14ba6998c1f360645bba537b6aa015316980ab5e318a8814b869'),
(31,'admin','MANUAL_QUARANTINE','sv_an','Group: sinhvien','Group: quarantine (VLAN 99)','172.19.0.1','2026-11-15 03:16:58','787508cdc52d14ba6998c1f360645bba537b6aa015316980ab5e318a8814b869','cedc800c43e93a691c2297dfa9ed5427822f0c4691bd2788395427330bc1abaa'),
(32,'admin','UNLOCK_USER','sv_an','Group: quarantine','Group: sinhvien','172.19.0.1','2026-11-15 03:22:45','cedc800c43e93a691c2297dfa9ed5427822f0c4691bd2788395427330bc1abaa','8d880f95c208525b8cf35b0212aff79e3e71e3a1f2d3376966a61be44df8130b'),
(33,'admin','UNLOCK_USER','sv_vinh','Group: quarantine','Group: sinhvien','172.19.0.1','2026-11-15 03:22:50','8d880f95c208525b8cf35b0212aff79e3e71e3a1f2d3376966a61be44df8130b','4c139197f04cd1f50e6895f79ce1dc6ef2b2f152a54051dbd276d5cf9204d942'),
(34,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:35:54','4c139197f04cd1f50e6895f79ce1dc6ef2b2f152a54051dbd276d5cf9204d942','4b5071278f6187d40429158fa117464bc6f2bfd7d105fe196eae287a284827ea'),
(35,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:41:44','4b5071278f6187d40429158fa117464bc6f2bfd7d105fe196eae287a284827ea','c30924daa837e6e6738ab9bb1cf2379a2bf36e90ea08797e46ab7c2fcc28adfa'),
(36,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:41:44','c30924daa837e6e6738ab9bb1cf2379a2bf36e90ea08797e46ab7c2fcc28adfa','80f5f55419156fd5565c49a2f0de0b38818feecafea6b4ba619559d6b45c946e'),
(37,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:41:44','80f5f55419156fd5565c49a2f0de0b38818feecafea6b4ba619559d6b45c946e','e8ae8247c86a0786efee8be966e7ec8e12eb199f9680f8a7e776eadc7ab2b58d'),
(38,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:41:44','e8ae8247c86a0786efee8be966e7ec8e12eb199f9680f8a7e776eadc7ab2b58d','c58a5709bfeebff8781e23c461b2191f8375c69e2469e07bd313cf86b22914f9'),
(39,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:41:44','c58a5709bfeebff8781e23c461b2191f8375c69e2469e07bd313cf86b22914f9','257c4114fa7ce7459891da8e5d06a9016d72caa771ac8fc2dcf10de1f8506510'),
(40,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:41:44','257c4114fa7ce7459891da8e5d06a9016d72caa771ac8fc2dcf10de1f8506510','fdd7dbc7aafc5f6c084e238be23a6600f6184e17b87c04c25fa593737b278a33'),
(41,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:41:44','fdd7dbc7aafc5f6c084e238be23a6600f6184e17b87c04c25fa593737b278a33','429ac50489c2d9a46496d3d4f1a823c70ed76c281838e5443e411527668b7284'),
(42,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:42:19','429ac50489c2d9a46496d3d4f1a823c70ed76c281838e5443e411527668b7284','4fa76963b04ed6d054c5ec3624746a88c0a77d149eab1ed39077d57a4962433a'),
(43,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:42:19','4fa76963b04ed6d054c5ec3624746a88c0a77d149eab1ed39077d57a4962433a','aa758932cca3b6a6b255f46397711aff45fd0efa28c3fb4e01ba275a48c6294b'),
(44,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:42:19','aa758932cca3b6a6b255f46397711aff45fd0efa28c3fb4e01ba275a48c6294b','bee9a18de91b9a7998f7d73d359a2d31817b4a7adffdedc4ce8c588e6bf74343'),
(45,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:42:19','bee9a18de91b9a7998f7d73d359a2d31817b4a7adffdedc4ce8c588e6bf74343','9bb5ea26ff03c3e9735f133680d822b5ac767d480bb657a040c25a245676c082'),
(46,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:42:19','9bb5ea26ff03c3e9735f133680d822b5ac767d480bb657a040c25a245676c082','b6d0c9d3036fa780b88af62b32a2db5035608a1b9e40c5115758e3979c1c7914'),
(47,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:42:19','b6d0c9d3036fa780b88af62b32a2db5035608a1b9e40c5115758e3979c1c7914','5210592a4bc88f20492229a0dda318ec660132db19427e4bf79201465bc3c78e'),
(48,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:42:19','5210592a4bc88f20492229a0dda318ec660132db19427e4bf79201465bc3c78e','d0d7a2c512ce843f45d814ee127406f5ea39b4497fb572f41f97f3781435f101'),
(49,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 03:42:19','d0d7a2c512ce843f45d814ee127406f5ea39b4497fb572f41f97f3781435f101','a45f1d5abee6ca36ec6a366d2fda393b002a9ed29d5f260254c3b316366ca075'),
(50,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:42:47','a45f1d5abee6ca36ec6a366d2fda393b002a9ed29d5f260254c3b316366ca075','1ae4a408b2055cfa4c8f0e6ea4e63632b9631c2d5702b1f0195e82c03b315ebe'),
(51,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:42:48','1ae4a408b2055cfa4c8f0e6ea4e63632b9631c2d5702b1f0195e82c03b315ebe','1dad943d33251b71601597fdc5aa92a79f5f309067dcd10c221a1feb8e8d08bc'),
(52,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:42:48','1dad943d33251b71601597fdc5aa92a79f5f309067dcd10c221a1feb8e8d08bc','df067e0fed699c1ab948fff41c1a51256f1be8c16900dbe6db2176bf6b662fef'),
(53,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:42:48','df067e0fed699c1ab948fff41c1a51256f1be8c16900dbe6db2176bf6b662fef','71657c1f7976e0375afc0b5c87a3ac7db22637113d83762f5f4541a6859ccda0'),
(54,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:42:48','71657c1f7976e0375afc0b5c87a3ac7db22637113d83762f5f4541a6859ccda0','9f852dd36add71ee96b467b2bdb64f2a157677cd3d418f24d3c9fb13c2947461'),
(55,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:42:48','9f852dd36add71ee96b467b2bdb64f2a157677cd3d418f24d3c9fb13c2947461','eb6dc0fc3b26a7041d4f0e690b0ad3e198f643299a854652f58b1840baa7a88c'),
(56,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:42:48','eb6dc0fc3b26a7041d4f0e690b0ad3e198f643299a854652f58b1840baa7a88c','2a2eea4242586c3a5f1619728bf1aab0da706c3d40e98fd519fa2c3eae631824'),
(57,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 03:42:48','2a2eea4242586c3a5f1619728bf1aab0da706c3d40e98fd519fa2c3eae631824','28399fdd9ec9438ee12c62a4d0d67b167ec453d3c247a2a143f5da966c52ff4b'),
(58,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 03:42:48','28399fdd9ec9438ee12c62a4d0d67b167ec453d3c247a2a143f5da966c52ff4b','d608ed2d34f0440ac6a7630cb384e154f5342f80002d980f5ca0310025da2c2a'),
(59,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 03:42:48','d608ed2d34f0440ac6a7630cb384e154f5342f80002d980f5ca0310025da2c2a','169fa5fa211a69d9d1f58c16b78dc13d9a727c2010f95c217474d25c9e88a551'),
(60,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 03:42:48','169fa5fa211a69d9d1f58c16b78dc13d9a727c2010f95c217474d25c9e88a551','5041a847d7b057b3cf9edef7ef48520096cde00e2b178dab57b8081a86146786'),
(61,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 03:42:48','5041a847d7b057b3cf9edef7ef48520096cde00e2b178dab57b8081a86146786','f8d06100d10a186e1d5eeb4f6cf303201ed4fae02fdbddd88112aa162d030f66'),
(62,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:43:01','f8d06100d10a186e1d5eeb4f6cf303201ed4fae02fdbddd88112aa162d030f66','f78d1cab12ebf884bf5bcbb0a14cdfd35d43389a698d3cdaac98427b222ccfac'),
(63,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:43:01','f78d1cab12ebf884bf5bcbb0a14cdfd35d43389a698d3cdaac98427b222ccfac','c7ad11addc9b5c0c8947a5cfbf388e2b531d6f1e58c75277bd4814e8e3115838'),
(64,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:43:01','c7ad11addc9b5c0c8947a5cfbf388e2b531d6f1e58c75277bd4814e8e3115838','35c01350cfac07584e2e45c5578dabf6b230710f29644975bcd0eeef50fae5c6'),
(65,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:43:01','35c01350cfac07584e2e45c5578dabf6b230710f29644975bcd0eeef50fae5c6','3f98b8b5396f0e926165d11852bd1c0a9ff4fe82031a94ee0df31e1b6da961d4'),
(66,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:43:01','3f98b8b5396f0e926165d11852bd1c0a9ff4fe82031a94ee0df31e1b6da961d4','4dfffe01467c79babcabd202889441d16a8b5c64d8e003ee174610f208452e99'),
(67,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:43:01','4dfffe01467c79babcabd202889441d16a8b5c64d8e003ee174610f208452e99','5b6376fa8e32072c004afc4930c98baad798a02b51e80387f6f7cd067bb8ec3e'),
(68,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:43:02','5b6376fa8e32072c004afc4930c98baad798a02b51e80387f6f7cd067bb8ec3e','a706c553b4e5f99e6818c46ea3ccc0bd5edd5ea603a7000dc1e331eb84c914fc'),
(69,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 03:43:02','a706c553b4e5f99e6818c46ea3ccc0bd5edd5ea603a7000dc1e331eb84c914fc','32740733c8a14fd0687479a61d9dabf953e9a940a3e134bbde1a13a392f5a545'),
(70,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 03:43:02','32740733c8a14fd0687479a61d9dabf953e9a940a3e134bbde1a13a392f5a545','f16a61b89c8de3680ec3fd2cb1e062630a29c82d468e0e3c769ace8ce71775b7'),
(71,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 03:43:02','f16a61b89c8de3680ec3fd2cb1e062630a29c82d468e0e3c769ace8ce71775b7','9b563b2e1b8e737023a9a2227076c2a8447e0818c36eef591a360eefa0fd2b4a'),
(72,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 03:43:02','9b563b2e1b8e737023a9a2227076c2a8447e0818c36eef591a360eefa0fd2b4a','6c2048fb352921b69f5e0938cd04cca6671509b4133ce5c50977f257da858639'),
(73,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 03:43:02','6c2048fb352921b69f5e0938cd04cca6671509b4133ce5c50977f257da858639','4e10984bf92a72ef002bd96a0c042d456008a41df7e7e2c73bec2cfdb4663b97'),
(74,'admin','DASHBOARD_LOGIN_FAILED','DASHBOARD','Lần sai thứ 1/5','Còn 4 lần thử trước khi bị khóa','172.19.0.1','2026-11-15 03:43:36','4e10984bf92a72ef002bd96a0c042d456008a41df7e7e2c73bec2cfdb4663b97','84f76c7b2da03bc6a14eaed87fcdc7a396902ec1f4d64f765427811e3465baae'),
(75,'admin','DASHBOARD_LOGIN_FAILED','DASHBOARD','Lần sai thứ 2/5','Còn 3 lần thử trước khi bị khóa','172.19.0.1','2026-11-15 03:43:36','84f76c7b2da03bc6a14eaed87fcdc7a396902ec1f4d64f765427811e3465baae','e94839ca4960feb3127400426d55965e30e2c157ec4b024cd2799fadb3e6f7b4'),
(76,'admin','DASHBOARD_LOGIN_FAILED','DASHBOARD','Lần sai thứ 3/5','Còn 2 lần thử trước khi bị khóa','172.19.0.1','2026-11-15 03:43:36','e94839ca4960feb3127400426d55965e30e2c157ec4b024cd2799fadb3e6f7b4','1ae9068773b093eb1a35ddd83df78c9ad7ac4c020991588e6f1c4a27e240a95e'),
(77,'admin','DASHBOARD_LOGIN_FAILED','DASHBOARD','Lần sai thứ 4/5','Còn 1 lần thử trước khi bị khóa','172.19.0.1','2026-11-15 03:43:36','1ae9068773b093eb1a35ddd83df78c9ad7ac4c020991588e6f1c4a27e240a95e','6f60b40801553b24fcec97f118a972a1dd1e4eca24d0f37e7bbf173acc320bab'),
(78,'admin','DASHBOARD_ACCOUNT_LOCKED','DASHBOARD','Nhập sai 5 lần liên tiếp từ IP 172.19.0.1','Khóa tài khoản admin trong 60 phút','172.19.0.1','2026-11-15 03:43:36','6f60b40801553b24fcec97f118a972a1dd1e4eca24d0f37e7bbf173acc320bab','69be40bb8d4d8719628ffef9228f49cfb4710099e7ad6fdec99a3394afd9ea69'),
(79,'172.19.0.1','DASHBOARD_IP_BLOCKED','DASHBOARD','Thử dò tài khoản: admin','Chặn địa chỉ IP 172.19.0.1 trong 60 phút','172.19.0.1','2026-11-15 03:43:36','69be40bb8d4d8719628ffef9228f49cfb4710099e7ad6fdec99a3394afd9ea69','30a8d45b3cdb11a8cce4fadd3bfdf7abb45536accd7ddb1647d2c3021fd7b935'),
(80,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:43:37','30a8d45b3cdb11a8cce4fadd3bfdf7abb45536accd7ddb1647d2c3021fd7b935','5fc8a1a16f0c02b5adebcd1f08980da8c1b16df368022d0b2263444c5625f3ac'),
(81,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:43:41','5fc8a1a16f0c02b5adebcd1f08980da8c1b16df368022d0b2263444c5625f3ac','65db6274a3981b904b787c333f1114d072cbaf58ea3268145f4b0298ce233115'),
(82,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:43:41','65db6274a3981b904b787c333f1114d072cbaf58ea3268145f4b0298ce233115','842feaa382ae7a298479af1ca5218bd1e442e170bed19eef81ee296426fabdaa'),
(83,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:43:41','842feaa382ae7a298479af1ca5218bd1e442e170bed19eef81ee296426fabdaa','4858a7cf0bf83cd282253ff668428020bb07e4bc5b54b9b4e8dddadecb3f885d'),
(84,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:43:42','4858a7cf0bf83cd282253ff668428020bb07e4bc5b54b9b4e8dddadecb3f885d','1f0f82af4d059d448c1e22fda47137aaf193bc930db427056f34c6e5c80d20ab'),
(85,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:43:42','1f0f82af4d059d448c1e22fda47137aaf193bc930db427056f34c6e5c80d20ab','9d25f23c19fa447772c000e5fcdeb9763c376d4c98d921399d06298e1aedcf37'),
(86,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:43:42','9d25f23c19fa447772c000e5fcdeb9763c376d4c98d921399d06298e1aedcf37','77ab64f07d1ad4a9e8391fa9c249a688fb386e33a0a50aa59a59c900e3d1f3fb'),
(87,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:43:42','77ab64f07d1ad4a9e8391fa9c249a688fb386e33a0a50aa59a59c900e3d1f3fb','516dea3ac7dd0eb08ef998100208e4597282492f532943d6dd4f9b743cf43b18'),
(88,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 03:43:42','516dea3ac7dd0eb08ef998100208e4597282492f532943d6dd4f9b743cf43b18','8075307a155d20433a4b4dc040ed3b350d578c2c85a10dab928625cb2dcf26ed'),
(89,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 03:43:42','8075307a155d20433a4b4dc040ed3b350d578c2c85a10dab928625cb2dcf26ed','61dcbf7b7df65d884d2f4d7231dac22180294f0ea1dd8f4e0885fbb6539e0b2c'),
(90,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 03:43:42','61dcbf7b7df65d884d2f4d7231dac22180294f0ea1dd8f4e0885fbb6539e0b2c','6c32f67852aefdb42f3962f28cf1a39fa1569436d0c9e3330f6f7b847f8134cb'),
(91,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 03:43:42','6c32f67852aefdb42f3962f28cf1a39fa1569436d0c9e3330f6f7b847f8134cb','79a854dccf9d9e96c0edf606e1e799ff04d90c857de65b24f14aff5817e29a0d'),
(92,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 03:43:42','79a854dccf9d9e96c0edf606e1e799ff04d90c857de65b24f14aff5817e29a0d','abff14ad44d00ee6a53b0a768c209aa2138b52520eb3ec47097a5791bb1c4e64'),
(93,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:50:15','abff14ad44d00ee6a53b0a768c209aa2138b52520eb3ec47097a5791bb1c4e64','14f4e258d691be494847b52fe75487b9552c760519f4a48b8af8bde2a54be67c'),
(94,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:55:27','14f4e258d691be494847b52fe75487b9552c760519f4a48b8af8bde2a54be67c','cf2208efbb4ed7268836ab269cbe2c6412e0e835400d8ff5c9d04f34a2e2746e'),
(95,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:55:27','cf2208efbb4ed7268836ab269cbe2c6412e0e835400d8ff5c9d04f34a2e2746e','ef85840f6501d4445dad532d3c006b2c24430d0d376d7c37bedf799165487a43'),
(96,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:55:27','ef85840f6501d4445dad532d3c006b2c24430d0d376d7c37bedf799165487a43','744b25ff97e7e47413b3b54a1b1d32d002580a0b757ee710810417938c63f0f7'),
(97,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:55:27','744b25ff97e7e47413b3b54a1b1d32d002580a0b757ee710810417938c63f0f7','55ad6268187744778ad89707b35eb4d34a02fa35c910a0087920733f48ef24d8'),
(98,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:55:27','55ad6268187744778ad89707b35eb4d34a02fa35c910a0087920733f48ef24d8','d03b88594aae639c783eaff4d1d3640da302cf662cd27acd1a996ff7c309b5e4'),
(99,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:55:27','d03b88594aae639c783eaff4d1d3640da302cf662cd27acd1a996ff7c309b5e4','3e8ce7d4007c77d9a3d529c58cedf91747d61a5aafa6befcd5343ecfd9c495dd'),
(100,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 03:55:27','3e8ce7d4007c77d9a3d529c58cedf91747d61a5aafa6befcd5343ecfd9c495dd','7c5a8e73fd278318794c5c113e29de79bf4594ca127a61cdb12020ae10258f6a'),
(101,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 03:55:27','7c5a8e73fd278318794c5c113e29de79bf4594ca127a61cdb12020ae10258f6a','6f1517100867ff6b8166a1e4449141c5244b9b17061eedb27bfd9f3864055090'),
(102,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 03:55:27','6f1517100867ff6b8166a1e4449141c5244b9b17061eedb27bfd9f3864055090','fa3545248df427cdbe3d446e7ac0f7938293f255e621e8d7349e117359c81c96'),
(103,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 03:55:27','fa3545248df427cdbe3d446e7ac0f7938293f255e621e8d7349e117359c81c96','2c04814f6c7c9c918375208ea8dd2a6e500c1ae26f2294fe9e6dce2bf84f22fc'),
(104,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 03:55:28','2c04814f6c7c9c918375208ea8dd2a6e500c1ae26f2294fe9e6dce2bf84f22fc','7ad4e35d5901360e8c95e0f7d73afd0be37f482fe782e49c4ea2194d1b0bc162'),
(105,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 03:55:28','7ad4e35d5901360e8c95e0f7d73afd0be37f482fe782e49c4ea2194d1b0bc162','32e9735a61829aafc9dbf93c244cff4b4f19b983739085961c4387cf2027f8f3'),
(106,'SYSTEM_ACTIVE_DEFENSE','AUTO_QUARANTINE_BRUTEFORCE','sv_vinh','Group: sinhvien','Group: quarantine (VLAN 99)','127.0.0.1','2026-11-15 04:07:40','32e9735a61829aafc9dbf93c244cff4b4f19b983739085961c4387cf2027f8f3','e3341ff42980370ba3bf52038058182499cf94e52f7d17554c63453d6a83340a'),
(107,'admin','UNLOCK_USER','sv_vinh','Group: quarantine','Group: sinhvien','172.19.0.1','2026-11-15 04:08:55','e3341ff42980370ba3bf52038058182499cf94e52f7d17554c63453d6a83340a','59834f72baf61f65c51f22c4da8d06f3090bc903741c6d8a2df6100de1b17c50'),
(108,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 06:08:52','59834f72baf61f65c51f22c4da8d06f3090bc903741c6d8a2df6100de1b17c50','c25c6e66a449b8e9f75794917f6b9ba54a22ed1bd1d0d2ea9be8602d99da7c42'),
(109,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 06:09:24','c25c6e66a449b8e9f75794917f6b9ba54a22ed1bd1d0d2ea9be8602d99da7c42','e05b10015caf55803269ae94af24f3da833385a08d2688621902b3b8e1b378d4'),
(110,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 06:09:44','e05b10015caf55803269ae94af24f3da833385a08d2688621902b3b8e1b378d4','8575a6e65675b5f3105f5a97e6c59f196fbfafc49673fab445a5d10894a060bf'),
(111,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 06:10:45','8575a6e65675b5f3105f5a97e6c59f196fbfafc49673fab445a5d10894a060bf','6db209e7f0eb77da4d21082c3fd88cac4d85ca9e65167692a7bf15c306900561'),
(112,'admin','SSO_SINGLE_LOGOUT','ALL_CONNECTED_APPS','','Kích hoạt Single Logout (SLO). Thu hồi thành công 5 phiên ứng dụng vệ tinh.','172.19.0.1','2026-11-15 06:10:46','6db209e7f0eb77da4d21082c3fd88cac4d85ca9e65167692a7bf15c306900561','3c5a1a8580f91c12c46529b5b86ba71e175b3cf1a7b516c947204a72c998126e'),
(113,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 06:11:05','3c5a1a8580f91c12c46529b5b86ba71e175b3cf1a7b516c947204a72c998126e','335f604899d2e4b8652dabc558a5a242eda16e1d7824ed477f14adc27b5e8ca2'),
(114,'admin','SSO_SINGLE_LOGOUT','ALL_CONNECTED_APPS','','Kích hoạt Single Logout (SLO). Thu hồi thành công 5 phiên ứng dụng vệ tinh.','172.19.0.1','2026-11-15 06:11:05','335f604899d2e4b8652dabc558a5a242eda16e1d7824ed477f14adc27b5e8ca2','18cd6f4fbddc6f514e7d22bd7049d436ee8cc140dcd57b838b8e6e4ec427ef31'),
(115,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 06:11:14','18cd6f4fbddc6f514e7d22bd7049d436ee8cc140dcd57b838b8e6e4ec427ef31','54b7d826cdb8cb1296e44ac01dd6896f0553d30c55605b31d2d64e78c215bc29'),
(116,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 06:11:14','54b7d826cdb8cb1296e44ac01dd6896f0553d30c55605b31d2d64e78c215bc29','5a60d9732fe34130476db8304fc6c72e651572b38a2a7404fb306e3374b049a3'),
(117,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 06:11:14','5a60d9732fe34130476db8304fc6c72e651572b38a2a7404fb306e3374b049a3','81cd7988d30125cf63e8611921c48f18f3e58bf4c33232033162f8781495cea2'),
(118,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 06:11:14','81cd7988d30125cf63e8611921c48f18f3e58bf4c33232033162f8781495cea2','2229d7fb6aed5716982d3c03d423c82823364baaedadc3fa34fa3806d8f95af9'),
(119,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 06:11:14','2229d7fb6aed5716982d3c03d423c82823364baaedadc3fa34fa3806d8f95af9','e6068a2bac7d0fd78676c9af999f1861db9e55b74ddff02a553cff5c8e0e6181'),
(120,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 06:11:14','e6068a2bac7d0fd78676c9af999f1861db9e55b74ddff02a553cff5c8e0e6181','d03ba6b33c5d4acf92d7346dc7cf97dfdd83e33851c99a9b419bdc9a0207f9ef'),
(121,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 06:11:15','d03ba6b33c5d4acf92d7346dc7cf97dfdd83e33851c99a9b419bdc9a0207f9ef','d90ee867389d4202255a26cfdfd41cf6a00d1d3c50e30e742b4c3bec28eed8c5'),
(122,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 06:11:15','d90ee867389d4202255a26cfdfd41cf6a00d1d3c50e30e742b4c3bec28eed8c5','eb709d35d9071a7e7c191b2b02d3dde468f5a90db7f030b9a98901da445dc0bb'),
(123,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 06:11:15','eb709d35d9071a7e7c191b2b02d3dde468f5a90db7f030b9a98901da445dc0bb','5739333453f4777812715bbaab75e065ee15a101e5e6a8d398c5c09257d511a6'),
(124,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 06:11:15','5739333453f4777812715bbaab75e065ee15a101e5e6a8d398c5c09257d511a6','c311e59d1c78e5aa14a174a1588fb3dba30eea394b4f3d020c7aae5ec2c9fc0b'),
(125,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 06:11:15','c311e59d1c78e5aa14a174a1588fb3dba30eea394b4f3d020c7aae5ec2c9fc0b','9afe95dcc90f1c60070c7afc6f724b24d40f2c89f58db1bccc8c76608411665b'),
(126,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 06:11:15','9afe95dcc90f1c60070c7afc6f724b24d40f2c89f58db1bccc8c76608411665b','7002b35161a2105284e460b8e132980ed6e582b58db27aca933838c58e7a1ed6'),
(127,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin','172.19.0.1','2026-11-15 08:47:00','7002b35161a2105284e460b8e132980ed6e582b58db27aca933838c58e7a1ed6','b724293eba83fc1dec35702c93365819baf0d686c9f179f949e49d0878c8ef81'),
(128,'admin','DASHBOARD_LOGOUT','SYSTEM','','Đăng xuất và kích hoạt SLO. Thu hồi 1 phiên ứng dụng.','172.19.0.1','2026-11-15 08:47:47','b724293eba83fc1dec35702c93365819baf0d686c9f179f949e49d0878c8ef81','0f560b7dae4bc2fbe8b615671fd10440cfb67183d9ec06ab7a20c50992ac1daa'),
(129,'UNKNOWN','DASHBOARD_LOGIN_FAILED','DASHBOARD','Username không tồn tại: sv_vinh','IP 172.19.0.1 thử sai 1/5','172.19.0.1','2026-11-15 08:47:53','0f560b7dae4bc2fbe8b615671fd10440cfb67183d9ec06ab7a20c50992ac1daa','ae0caf4062d6c86aac80c7e951239747d6b4e8b223f67a18b35819a1eb716ffd'),
(130,'UNKNOWN','DASHBOARD_LOGIN_FAILED','DASHBOARD','Username không tồn tại: sv_vinh','IP 172.19.0.1 thử sai 2/5','172.19.0.1','2026-11-15 08:49:13','ae0caf4062d6c86aac80c7e951239747d6b4e8b223f67a18b35819a1eb716ffd','bb376f9814e5a7fd14343cbb2280b1e92a51f64fb16c44c7f20b7d1a53922cc2'),
(131,'sv_vinh','DASHBOARD_LOGIN_FAILED','DASHBOARD','Lần sai thứ 3/5','Còn 2 lần thử trước khi bị khóa','172.19.0.1','2026-11-15 09:07:08','bb376f9814e5a7fd14343cbb2280b1e92a51f64fb16c44c7f20b7d1a53922cc2','22e2bd70a163d235418dc4f72753aa49e53a7a3266cde705faa88e9452f55f40'),
(132,'sv_vinh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 09:08:20','22e2bd70a163d235418dc4f72753aa49e53a7a3266cde705faa88e9452f55f40','ffbc092bf1ad4fba489c15a7de45b6648aef4a366c85bd5804d9e90d86620c0d'),
(133,'sv_vinh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 09:09:15','ffbc092bf1ad4fba489c15a7de45b6648aef4a366c85bd5804d9e90d86620c0d','5942b3fe51accd3e512d6ac6884224a6a19d08c8e7246adb719cc0f3e778e3af'),
(134,'gv_nguyen','DASHBOARD_LOGIN','SYSTEM','','Login success as user (giangvien)','172.19.0.1','2026-11-15 09:09:15','5942b3fe51accd3e512d6ac6884224a6a19d08c8e7246adb719cc0f3e778e3af','c03f01284841b0f383ed18170f194198fbff83df4ab61e6188b8583412757d0e'),
(135,'sv_vinh','SSO_SINGLE_LOGOUT','ALL_CONNECTED_APPS','','Kích hoạt Single Logout (SLO). Thu hồi thành công 4 phiên ứng dụng vệ tinh.','172.19.0.1','2026-11-15 09:09:15','c03f01284841b0f383ed18170f194198fbff83df4ab61e6188b8583412757d0e','51f6c7fcceb3d75a43206930d4b27df37b53a2d5f473c56f94c834c24e4395ae'),
(136,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 09:09:15','51f6c7fcceb3d75a43206930d4b27df37b53a2d5f473c56f94c834c24e4395ae','0571322cd16f7416d7ceb4f80271452b9648c98dd07adf809ac7bf5708a1b51f'),
(137,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 09:09:22','0571322cd16f7416d7ceb4f80271452b9648c98dd07adf809ac7bf5708a1b51f','44166b53ad29e2deb5d1ec094b204bc50c36c098e9ff574878d641e78e2edcb4'),
(138,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 09:09:22','44166b53ad29e2deb5d1ec094b204bc50c36c098e9ff574878d641e78e2edcb4','5bd667185745a7aec44beacd3f6351cc287f530f53efa2ae8183840fd52837fe'),
(139,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 09:09:22','5bd667185745a7aec44beacd3f6351cc287f530f53efa2ae8183840fd52837fe','b7dd08d68ddc153bc9ad4d478b8355add0741f9cd7f94ecadce5fff102719ac3'),
(140,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 09:09:22','b7dd08d68ddc153bc9ad4d478b8355add0741f9cd7f94ecadce5fff102719ac3','cfa6a2419cc752f54b27fe1a537321bf1767116d87d56024cc3a4889a134b8f2'),
(141,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 09:09:22','cfa6a2419cc752f54b27fe1a537321bf1767116d87d56024cc3a4889a134b8f2','749332c9357b50f65dedd748a2620485054dfefbb245349803e4e4541daa3b29'),
(142,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 09:09:22','749332c9357b50f65dedd748a2620485054dfefbb245349803e4e4541daa3b29','fba8d1ba6efddb05b47f117d982e32c4bb3697c15f150f640674dba071994065'),
(143,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 09:09:22','fba8d1ba6efddb05b47f117d982e32c4bb3697c15f150f640674dba071994065','9f8c73dc7ed0420e122cb5989a37dff663dfbb4f37a03a76e119c63a610bf339'),
(144,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 09:09:22','9f8c73dc7ed0420e122cb5989a37dff663dfbb4f37a03a76e119c63a610bf339','ff08dc80dfd2966fd840d285e0f09e966926330bcbfc74a17586dbcd552787d6'),
(145,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 09:09:22','ff08dc80dfd2966fd840d285e0f09e966926330bcbfc74a17586dbcd552787d6','2f597bd1c0487a06084fdb38df7bb854fbdb1cb7071f731aebbbed69045f27d1'),
(146,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 09:09:22','2f597bd1c0487a06084fdb38df7bb854fbdb1cb7071f731aebbbed69045f27d1','8ad339df1ef626aae9461616491da2983ad3594abe95523de735a36366b31481'),
(147,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 09:09:23','8ad339df1ef626aae9461616491da2983ad3594abe95523de735a36366b31481','83b4204d5f8e36a7bd11995fb8078fbf80012fd672b698f40b9a09e6074d54e2'),
(148,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 09:09:23','83b4204d5f8e36a7bd11995fb8078fbf80012fd672b698f40b9a09e6074d54e2','d2376589c97d87ef59c63b407ff882c2c859df4a99f166e79afede53ce131e06'),
(149,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 09:09:31','d2376589c97d87ef59c63b407ff882c2c859df4a99f166e79afede53ce131e06','cf24280344511a568bb9704a87d9dda78ca52acf993a71ee88caccee66fec387'),
(150,'admin','SSO_SINGLE_LOGOUT','ALL_CONNECTED_APPS','','Kích hoạt Single Logout (SLO). Thu hồi thành công 5 phiên ứng dụng vệ tinh.','172.19.0.1','2026-11-15 09:09:31','cf24280344511a568bb9704a87d9dda78ca52acf993a71ee88caccee66fec387','268971543e47bf2b1c044ac69f81d80787afe78015fddb2b5eda45c75fc26afb'),
(151,'sv_vinh','DASHBOARD_LOGIN_FAILED','DASHBOARD','Lần sai thứ 1/5','Còn 4 lần thử trước khi bị khóa','172.19.0.1','2026-11-15 09:12:18','268971543e47bf2b1c044ac69f81d80787afe78015fddb2b5eda45c75fc26afb','60b2dc40a7d808363510ee2437bcd5639de916e910f5cb500293a0ad5b5ba56a'),
(152,'sv_vinh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 09:12:35','60b2dc40a7d808363510ee2437bcd5639de916e910f5cb500293a0ad5b5ba56a','72e8410b447fae90716659b92fbf64b6697476e26b40ae6ff8bd82c6eb557e23'),
(153,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 09:13:11','72e8410b447fae90716659b92fbf64b6697476e26b40ae6ff8bd82c6eb557e23','bdc8ff81081dbf72c0028870512dc515353631382ca603627db15d702c5f586d'),
(154,'sv_an','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 09:14:29','bdc8ff81081dbf72c0028870512dc515353631382ca603627db15d702c5f586d','93c73621a8d1a56a2fe58a252f055b3fe1f79c7fac4dd29c7f5267dc63e825d4'),
(155,'sv_vinh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 09:14:52','93c73621a8d1a56a2fe58a252f055b3fe1f79c7fac4dd29c7f5267dc63e825d4','67ca2489e718c9fc83e71bf774be9251dbd5388b146f2c376b6f8e65affab486'),
(156,'sv_vinh','SSO_SINGLE_LOGOUT','ALL_CONNECTED_APPS','','Kích hoạt Single Logout (SLO). Thu hồi thành công 2 phiên ứng dụng vệ tinh.','172.19.0.1','2026-11-15 09:15:26','67ca2489e718c9fc83e71bf774be9251dbd5388b146f2c376b6f8e65affab486','ac1237592a0583d08ddb4c541d5097f6602fe9b686e2c266a30caf97d8773bcb'),
(157,'admin','MANUAL_QUARANTINE','sv_vinh','Group: sinhvien','Group: quarantine (VLAN 99)','172.19.0.1','2026-11-15 09:17:17','ac1237592a0583d08ddb4c541d5097f6602fe9b686e2c266a30caf97d8773bcb','6fe0086caee1be003ce2d545965e5415e48623ac2c5e4b0487dc335c15ea33f1'),
(158,'admin','UNLOCK_USER','sv_vinh','Group: quarantine','Group: sinhvien','172.19.0.1','2026-11-15 09:18:07','6fe0086caee1be003ce2d545965e5415e48623ac2c5e4b0487dc335c15ea33f1','f1c232a89d6b625b7e851f9a16ee66a0fa8a5b66c41d441ba9bec2b27580b27c'),
(159,'sv_an','DASHBOARD_LOGOUT','SYSTEM','','Đăng xuất và kích hoạt SLO. Thu hồi 0 phiên ứng dụng.','172.19.0.1','2026-11-15 09:18:17','f1c232a89d6b625b7e851f9a16ee66a0fa8a5b66c41d441ba9bec2b27580b27c','4d0eba2def2e5e8a12ec21c93e61713469ee0d097f89d4d2303dc7fb021b8f72'),
(160,'sv_vinh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 09:18:24','4d0eba2def2e5e8a12ec21c93e61713469ee0d097f89d4d2303dc7fb021b8f72','1dee0d8372f4cbacc30281b8553acf02621816bf4be99ee6dd010cac70506f75'),
(161,'admin','MANUAL_QUARANTINE','sv_vinh','Group: sinhvien','Group: quarantine (VLAN 99)','172.19.0.1','2026-11-15 09:18:31','1dee0d8372f4cbacc30281b8553acf02621816bf4be99ee6dd010cac70506f75','132c306640e33c145ee4e8384c88b30081bfbe3019253d0d999ed0a05e9b641a'),
(162,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 10:07:08','132c306640e33c145ee4e8384c88b30081bfbe3019253d0d999ed0a05e9b641a','9d629c2e462a52c8bc1f2728ddcad11b7f6d5eb34b28e472cfac69c1a42a79d3'),
(163,'admin','UNLOCK_USER','sv_binh','Group: quarantine','Group: sinhvien | Unblocked IPs: Không có','172.19.0.1','2026-11-15 10:07:08','9d629c2e462a52c8bc1f2728ddcad11b7f6d5eb34b28e472cfac69c1a42a79d3','d39a8a1ebd7104915ab967efece99f6ca98a9ac24ac1b97cff3f359d6a71a68b'),
(164,'sv_binh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 10:07:09','d39a8a1ebd7104915ab967efece99f6ca98a9ac24ac1b97cff3f359d6a71a68b','d3b379c2ad0eb7321a4f005615d2d0651ebf7091000b29a81861b1cbd335eeef'),
(165,'admin','MANUAL_QUARANTINE','sv_binh','Group: sinhvien','Group: quarantine (VLAN 99) | Blocked IPs: 172.19.0.1 | Revoked SSO: 1','172.19.0.1','2026-11-15 10:07:09','d3b379c2ad0eb7321a4f005615d2d0651ebf7091000b29a81861b1cbd335eeef','443456a363e77d2a558a779e750668d5f609ae78c96037dea194baa7f466d812'),
(166,'admin','UNLOCK_USER','sv_binh','Group: quarantine','Group: sinhvien | Unblocked IPs: 172.19.0.1','172.19.0.1','2026-11-15 10:07:09','443456a363e77d2a558a779e750668d5f609ae78c96037dea194baa7f466d812','7c28d6b3786abf77f5d180683704c818c56fc6e4bff570855df9c2d0ef987558'),
(167,'sv_binh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 10:07:09','7c28d6b3786abf77f5d180683704c818c56fc6e4bff570855df9c2d0ef987558','de6c1235d4dd719524b3cd00302b016d55fa0a13cc656302d7cc5b54baa4590e'),
(168,'sv_vinh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (quarantine)','172.19.0.1','2026-11-15 10:07:39','de6c1235d4dd719524b3cd00302b016d55fa0a13cc656302d7cc5b54baa4590e','6a52707e0faffe9e7344d818cd3a5d512d8e42a4ae1228233daa5d73e3f0b1e8'),
(169,'sv_vinh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 10:07:54','6a52707e0faffe9e7344d818cd3a5d512d8e42a4ae1228233daa5d73e3f0b1e8','23c5bd1b1d1c888f18902949ebf53953a9c8fb153644925262f7d7e14df78f81'),
(170,'gv_nguyen','DASHBOARD_LOGIN','SYSTEM','','Login success as user (giangvien)','172.19.0.1','2026-11-15 10:07:55','23c5bd1b1d1c888f18902949ebf53953a9c8fb153644925262f7d7e14df78f81','b3709ad00728f1f918c94f3b41108cd6959b717ee71a47cc9b0a95190ffd81e5'),
(171,'sv_vinh','SSO_SINGLE_LOGOUT','ALL_CONNECTED_APPS','','Kích hoạt Single Logout (SLO). Thu hồi thành công 4 phiên ứng dụng vệ tinh.','172.19.0.1','2026-11-15 10:07:55','b3709ad00728f1f918c94f3b41108cd6959b717ee71a47cc9b0a95190ffd81e5','bfaa46e621527b6c3177e60c8ada905f13f81b8f52577e7b45c7ed71da6cfbac'),
(172,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 10:07:55','bfaa46e621527b6c3177e60c8ada905f13f81b8f52577e7b45c7ed71da6cfbac','f58bd0e1d7462971f6380fe9cc641829e1d6628df9d84d6d0603421e5dd586a1'),
(173,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 10:08:00','f58bd0e1d7462971f6380fe9cc641829e1d6628df9d84d6d0603421e5dd586a1','b88f970587f28831b3a81fb080962e822774591ed948fa9dad10ea120566b649'),
(174,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 10:08:00','b88f970587f28831b3a81fb080962e822774591ed948fa9dad10ea120566b649','3a2e09f899e704d595fcbec1a8180eec855a72e1d57166760840cb91f8471e4b'),
(175,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 10:08:01','3a2e09f899e704d595fcbec1a8180eec855a72e1d57166760840cb91f8471e4b','3b4f92c61b62b367934afbab2166e2f505ea887c28f991101c7a02315924e983'),
(176,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 10:08:01','3b4f92c61b62b367934afbab2166e2f505ea887c28f991101c7a02315924e983','a0fedc20a3524f3a072204b0a742127e7e2d627b750e161f09319326584926fc'),
(177,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 10:08:01','a0fedc20a3524f3a072204b0a742127e7e2d627b750e161f09319326584926fc','26a4bb21108f9656a5f02f008ecbcb91064c084841e95e9b9ebf14f00f8a93e5'),
(178,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 10:08:01','26a4bb21108f9656a5f02f008ecbcb91064c084841e95e9b9ebf14f00f8a93e5','7fb151d31d1ad0c76538cef74f6fc5f9841589bde86054c2469596df99b3f0b4'),
(179,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 10:08:01','7fb151d31d1ad0c76538cef74f6fc5f9841589bde86054c2469596df99b3f0b4','855ef58b8cd58f82d39d73401bb1dcb6d9a492b8dc3de29fb64226a4be8ede9e'),
(180,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 10:08:01','855ef58b8cd58f82d39d73401bb1dcb6d9a492b8dc3de29fb64226a4be8ede9e','e66ddd6003cebcf6c9fbf67f72d24806ac8e3a1656ecc5ca624c8853ffdbcab9'),
(181,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 10:08:01','e66ddd6003cebcf6c9fbf67f72d24806ac8e3a1656ecc5ca624c8853ffdbcab9','6a9d64bfbd42d06c14fa100045a493b05a2aa72dcd2624aa8c4ec47cb0f81735'),
(182,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 10:08:01','6a9d64bfbd42d06c14fa100045a493b05a2aa72dcd2624aa8c4ec47cb0f81735','6b482e87ead209672a39e98a9093c185477715521b5ccdb3773c7d58abdecb4b'),
(183,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 10:08:02','6b482e87ead209672a39e98a9093c185477715521b5ccdb3773c7d58abdecb4b','4182b322b11e684cff0d327c775ffcacd4b945314de0dd8436a9c76e75f930de'),
(184,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 10:08:02','4182b322b11e684cff0d327c775ffcacd4b945314de0dd8436a9c76e75f930de','81691cd2b32cd10ab17ac26a9b6e84b2e9bcfd8d2f8c35c6cce82a9f6a506560'),
(185,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 10:08:07','81691cd2b32cd10ab17ac26a9b6e84b2e9bcfd8d2f8c35c6cce82a9f6a506560','6574f8f064ada6f7b293b92db14da58b97d85251bf5981411e957b9872123cab'),
(186,'admin','SSO_SINGLE_LOGOUT','ALL_CONNECTED_APPS','','Kích hoạt Single Logout (SLO). Thu hồi thành công 5 phiên ứng dụng vệ tinh.','172.19.0.1','2026-11-15 10:08:08','6574f8f064ada6f7b293b92db14da58b97d85251bf5981411e957b9872123cab','4b5f1736448a37edb97cb2eb9523ca1951236f5517e28d319ccc6a77ed3164e3'),
(187,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 10:08:15','4b5f1736448a37edb97cb2eb9523ca1951236f5517e28d319ccc6a77ed3164e3','35a12b36122f72f92c6a3f6c2f33ee8a16b34d0f9aafed5acf9e6fad65a20f0d'),
(188,'admin','UNLOCK_USER','sv_binh','Group: quarantine','Group: sinhvien | Unblocked IPs: Không có','172.19.0.1','2026-11-15 10:08:15','35a12b36122f72f92c6a3f6c2f33ee8a16b34d0f9aafed5acf9e6fad65a20f0d','77ebee9c02e05d673f32f81a14a705798c7701f71f329ab13888300e0a1e7086'),
(189,'sv_binh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 10:08:15','77ebee9c02e05d673f32f81a14a705798c7701f71f329ab13888300e0a1e7086','4dff9904c6e6a3ca8497354f3810c6c51437d00f8e57b647755d8f9d8c7a0847'),
(190,'admin','MANUAL_QUARANTINE','sv_binh','Group: sinhvien','Group: quarantine (VLAN 99) | Blocked IPs: 172.19.0.1 | Revoked SSO: 2','172.19.0.1','2026-11-15 10:08:15','4dff9904c6e6a3ca8497354f3810c6c51437d00f8e57b647755d8f9d8c7a0847','9db3093479ff75cc232a0b59ec5e328302c699aa6af5b308819bd9c930f633d1'),
(191,'admin','UNLOCK_USER','sv_binh','Group: quarantine','Group: sinhvien | Unblocked IPs: 172.19.0.1','172.19.0.1','2026-11-15 10:08:16','9db3093479ff75cc232a0b59ec5e328302c699aa6af5b308819bd9c930f633d1','e4a203a168716f476d9a3df08b01a21a2f59e82e1f5c0b16025bd1db5e0d60f4'),
(192,'sv_binh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 10:08:16','e4a203a168716f476d9a3df08b01a21a2f59e82e1f5c0b16025bd1db5e0d60f4','978f62ee8233bcc21f9794e73a432e209b9e38826c5a4485db12ac96df80ec6d'),
(193,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 10:09:50','978f62ee8233bcc21f9794e73a432e209b9e38826c5a4485db12ac96df80ec6d','2df54450b32f85c68db497099eb7755579292b57418e7d63612ce509e41c521a'),
(194,'admin','MANUAL_QUARANTINE','sv_vinh','Group: sinhvien','Group: quarantine (VLAN 99) | Blocked IPs: 172.19.0.1 | Revoked SSO: 0','172.19.0.1','2026-11-15 10:09:58','2df54450b32f85c68db497099eb7755579292b57418e7d63612ce509e41c521a','c749f961b52b3c48ff05a0199de826fd7f8313e86e207758d7e6e5ed4ed2b27a'),
(195,'172.19.0.1','DASHBOARD_IP_BLOCKED','DASHBOARD','Attempted username: sv_vinh','IP đang bị chặn liên quan đến tài khoản vi phạm. Còn 1440 phút.','172.19.0.1','2026-11-15 10:10:32','c749f961b52b3c48ff05a0199de826fd7f8313e86e207758d7e6e5ed4ed2b27a','7a3f099f81541a25b53e584d7d0f3b7d4d98eb42edb2a8b4976f475a53dacae5'),
(196,'172.19.0.1','DASHBOARD_IP_BLOCKED','DASHBOARD','Attempted username: sv_vinh','IP đang bị chặn liên quan đến tài khoản vi phạm. Còn 1440 phút.','172.19.0.1','2026-11-15 10:10:51','7a3f099f81541a25b53e584d7d0f3b7d4d98eb42edb2a8b4976f475a53dacae5','2c4e58051e8319b4f1e74774c7ef0dcfa9b0675a9e50a8e34845ef3c78b63152'),
(197,'admin','UNLOCK_USER','sv_vinh','Group: quarantine','Group: sinhvien | Unblocked IPs: 172.19.0.1','172.19.0.1','2026-11-15 10:10:58','2c4e58051e8319b4f1e74774c7ef0dcfa9b0675a9e50a8e34845ef3c78b63152','62cac103515c623ccdc47d44ae7542ebc09438575389a24fb9f705c55e56c5b8'),
(198,'sv_vinh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 10:11:08','62cac103515c623ccdc47d44ae7542ebc09438575389a24fb9f705c55e56c5b8','4271e4da0e7b0de681c318a6fc2bc8fa4d629c04dcd96a6b18b82874cb1fae19'),
(199,'sv_vinh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 10:11:26','4271e4da0e7b0de681c318a6fc2bc8fa4d629c04dcd96a6b18b82874cb1fae19','14f889aff5ee62f5e1221b137020d012ca0a6676b23446e43cd9704cc8bd2637'),
(200,'sv_vinh','DASHBOARD_LOGOUT','SYSTEM','','Đăng xuất và kích hoạt SLO. Thu hồi 0 phiên ứng dụng.','172.19.0.1','2026-11-15 10:12:06','14f889aff5ee62f5e1221b137020d012ca0a6676b23446e43cd9704cc8bd2637','17e6e173521e638480e19e085fd0c1241d1b6117540cc139072cd68da910aa5b'),
(201,'sv_vinh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 10:13:00','17e6e173521e638480e19e085fd0c1241d1b6117540cc139072cd68da910aa5b','75cbd00e3102f97d0c3a6c37f285f58f427fe6c27f6cf18a7f72f163f91df3d1'),
(202,'sv_vinh','SSO_SINGLE_LOGOUT','ALL_CONNECTED_APPS','','Kích hoạt Single Logout (SLO). Thu hồi thành công 1 phiên ứng dụng vệ tinh.','172.19.0.1','2026-11-15 10:13:08','75cbd00e3102f97d0c3a6c37f285f58f427fe6c27f6cf18a7f72f163f91df3d1','8e07d652058fca6c2bf67323530120aca900e4887a2fd1a0fc0dfbc29cf5cfa9'),
(203,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 10:15:55','8e07d652058fca6c2bf67323530120aca900e4887a2fd1a0fc0dfbc29cf5cfa9','56408e566122f7b5c45ee0b036b602aa3cb7569b4d49ff2e793ecb78203901e9'),
(204,'admin','UNLOCK_USER','sv_binh','Group: quarantine','Group: sinhvien | Unblocked IPs: Không có','172.19.0.1','2026-11-15 10:15:55','56408e566122f7b5c45ee0b036b602aa3cb7569b4d49ff2e793ecb78203901e9','2cf3fa203e71b0c93264677647418e5807d9724e83045da938a29766e6884ce8'),
(205,'sv_binh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 10:15:55','2cf3fa203e71b0c93264677647418e5807d9724e83045da938a29766e6884ce8','436d77077925a743edac8e85b497a4cbba9197b1c2b4d158ba8f8ffd5ae2b6b5'),
(206,'admin','MANUAL_QUARANTINE','sv_binh','Group: sinhvien','Group: quarantine (VLAN 99) | Blocked IPs: 172.19.0.1 | Revoked SSO: 2','172.19.0.1','2026-11-15 10:15:55','436d77077925a743edac8e85b497a4cbba9197b1c2b4d158ba8f8ffd5ae2b6b5','3712dbf6d28665889ba70a809782a7d408945c5cbc5558b42460f25aed852ec2'),
(207,'admin','UNLOCK_USER','sv_binh','Group: quarantine','Group: sinhvien | Unblocked IPs: 172.19.0.1','172.19.0.1','2026-11-15 10:15:55','3712dbf6d28665889ba70a809782a7d408945c5cbc5558b42460f25aed852ec2','922c2b7b84bfc955d47aa92ef2dbb6cab539701d9c0ae0b6d2ce362272299ef5'),
(208,'sv_binh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 10:15:56','922c2b7b84bfc955d47aa92ef2dbb6cab539701d9c0ae0b6d2ce362272299ef5','9dab4e148ccf97ead537b510a20044054833fa056b555d6c9a20c3e30fe9c0b8'),
(209,'sv_vinh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 10:17:00','9dab4e148ccf97ead537b510a20044054833fa056b555d6c9a20c3e30fe9c0b8','8a3f53c06fcc86c4e34eed1b7525367988eaaf049fb67f46bd86848799da606a'),
(210,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 10:17:57','8a3f53c06fcc86c4e34eed1b7525367988eaaf049fb67f46bd86848799da606a','ff800743004cbbed6cf1a77b1b3f32f71aeb3e68bfcfe8a5157d94ffff2fb406'),
(211,'admin','MANUAL_QUARANTINE','sv_vinh','Group: sinhvien','Group: quarantine (VLAN 99) | Blocked IPs: 172.19.0.1 | Revoked SSO: 1','172.19.0.1','2026-11-15 10:18:05','ff800743004cbbed6cf1a77b1b3f32f71aeb3e68bfcfe8a5157d94ffff2fb406','11be3c19dcde92f9c2fb7f32519cdb2b902d9715904c4415d418de70ec35d9e1'),
(212,'sv_vinh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (quarantine)','172.19.0.1','2026-11-15 10:18:13','11be3c19dcde92f9c2fb7f32519cdb2b902d9715904c4415d418de70ec35d9e1','ff603b61f5acdd7981229bc6fbc4981daf581dfcf5077bacdade6c8d7e10360f'),
(213,'admin','UNLOCK_USER','sv_vinh','Group: quarantine','Group: sinhvien | Unblocked IPs: 172.19.0.1','172.19.0.1','2026-11-15 10:18:23','ff603b61f5acdd7981229bc6fbc4981daf581dfcf5077bacdade6c8d7e10360f','aa5e62088c9808479494b55ac49c44604cebc3ed4c30647134b2abd4f9ae50a8'),
(214,'sv_vinh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 10:18:41','aa5e62088c9808479494b55ac49c44604cebc3ed4c30647134b2abd4f9ae50a8','289837bc9dc0e726df1b7473cdb4c6a200f3c9742ca32d156dfbcc05a83bbe47'),
(215,'SYSTEM_ACTIVE_DEFENSE','AUTO_QUARANTINE_BRUTEFORCE','sv_vinh','Group: sinhvien','Group: quarantine (VLAN 99) | Blocked IPs: 172.19.0.1','127.0.0.1','2026-11-15 10:19:51','289837bc9dc0e726df1b7473cdb4c6a200f3c9742ca32d156dfbcc05a83bbe47','10403008ad31d5b63aec060644e782744ba678df81c0cb24013a7311287f5d91'),
(216,'admin','UNLOCK_USER','sv_vinh','Group: quarantine','Group: sinhvien | Unblocked IPs: 172.19.0.1','172.19.0.1','2026-11-15 10:20:32','10403008ad31d5b63aec060644e782744ba678df81c0cb24013a7311287f5d91','5a9d7bdeafb650bb37a11e33e8d2a34cc8caa48b00d8ae6a093489026763f775'),
(217,'sv_vinh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 10:20:47','5a9d7bdeafb650bb37a11e33e8d2a34cc8caa48b00d8ae6a093489026763f775','cae1fffa50fe335a109d0ed35e1658c2f894334a8724a1e271ef8bc43176972d'),
(218,'sv_tuananh','SELF_REGISTER','OPENLDAP','NEW_USER_REGISTRATION','Group: sinhvien (VLAN 20), Name: Lê Tuấn Anh, Email: tuananh.le@ptit.edu.vn','172.19.0.1','2026-11-15 11:33:06','cae1fffa50fe335a109d0ed35e1658c2f894334a8724a1e271ef8bc43176972d','ced85758b59bfc9ad2f7fec86d7c7aa0d5843f204d15525898395068ce1682f0'),
(219,'sv_tuananh','SELF_REGISTER','OPENLDAP','NEW_USER_REGISTRATION','Group: sinhvien (VLAN 20), Name: Lê Tuấn Anh, Email: tuananh.le@ptit.edu.vn','172.19.0.1','2026-11-15 11:37:14','ced85758b59bfc9ad2f7fec86d7c7aa0d5843f204d15525898395068ce1682f0','fa8a51fec667837887698f906c0af616c5843b341b506bf48511f72ec1dd6c63'),
(220,'sv_tuananh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 11:37:14','fa8a51fec667837887698f906c0af616c5843b341b506bf48511f72ec1dd6c63','8bae37bbe27a946814e5d51803f5ed39985945476eb235c21046e2fb25244158'),
(221,'sv_tuananh','SELF_REGISTER','OPENLDAP','NEW_USER_REGISTRATION','Group: sinhvien (VLAN 20), Name: Lê Tuấn Anh, Email: tuananh.le@ptit.edu.vn','172.19.0.1','2026-11-15 11:37:48','8bae37bbe27a946814e5d51803f5ed39985945476eb235c21046e2fb25244158','2cd979c00d7cd363941bab0074cbda6e19f54b7c6099431606160424b18c312e'),
(222,'sv_tuananh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 11:37:48','2cd979c00d7cd363941bab0074cbda6e19f54b7c6099431606160424b18c312e','65d69b4a8f4e21712f0eac988590dc6aa69b1f1bc49972b636a040e3e696c8e1'),
(223,'sv_tuananh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 11:37:55','65d69b4a8f4e21712f0eac988590dc6aa69b1f1bc49972b636a040e3e696c8e1','153c02f2318234c99a86c8bbd41689f5b69154d10b054f81820d8586abb43c87'),
(224,'sv_tuananh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 11:38:25','153c02f2318234c99a86c8bbd41689f5b69154d10b054f81820d8586abb43c87','a28e6747ed0b2599bb9870691b300ee1ef08d0c16fc031d4d4c2fc136cfa116b'),
(225,'sv_tuananh','SELF_REGISTER','OPENLDAP','NEW_USER_REGISTRATION','Group: sinhvien (VLAN 20), Name: Lê Tuấn Anh, Email: tuananh.le@ptit.edu.vn','172.19.0.1','2026-11-15 11:40:44','a28e6747ed0b2599bb9870691b300ee1ef08d0c16fc031d4d4c2fc136cfa116b','d5d69dc77f939f7d015194eb42c20d9b7f48aeeebfd9a2a6c73382bb8fce7fbb'),
(226,'sv_tuananh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 11:40:44','d5d69dc77f939f7d015194eb42c20d9b7f48aeeebfd9a2a6c73382bb8fce7fbb','ca08f8ca6e5502391aa7f7b9287b2f146122090030088e9fbcbaa06ba121995f'),
(227,'gv_huong','SELF_REGISTER','OPENLDAP','NEW_USER_REGISTRATION','Group: giangvien (VLAN 30), Name: Trần Thu Hương, Email: huong.tt@ptit.edu.vn','172.19.0.1','2026-11-15 11:40:44','ca08f8ca6e5502391aa7f7b9287b2f146122090030088e9fbcbaa06ba121995f','3df6eafcd26d546e8291d2565c73e3972432513761b1e6c963f0103923f6ce83'),
(228,'gv_huong','DASHBOARD_LOGIN','SYSTEM','','Login success as user (giangvien)','172.19.0.1','2026-11-15 11:40:44','3df6eafcd26d546e8291d2565c73e3972432513761b1e6c963f0103923f6ce83','19ed285ebe66e6d846271b626ea096e51774a42364872bfc948576b65646d090'),
(229,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 11:41:07','19ed285ebe66e6d846271b626ea096e51774a42364872bfc948576b65646d090','9b682c81d11b715e220d5dd371b7877c855f0ba6903b63c316feaaf1ed67d9b2'),
(230,'admin','UNLOCK_USER','sv_binh','Group: quarantine','Group: sinhvien | Unblocked IPs: Không có','172.19.0.1','2026-11-15 11:41:07','9b682c81d11b715e220d5dd371b7877c855f0ba6903b63c316feaaf1ed67d9b2','1dd8bb5860674faf168e829f950421e00e4e3a8bca6f14dc90e9b51eef198b30'),
(231,'sv_binh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 11:41:07','1dd8bb5860674faf168e829f950421e00e4e3a8bca6f14dc90e9b51eef198b30','ebb6384d6176a21c4d4e32788331068176d7cc71cc4a9750c12f12cfee800566'),
(232,'admin','MANUAL_QUARANTINE','sv_binh','Group: sinhvien','Group: quarantine (VLAN 99) | Blocked IPs: 172.19.0.1 | Revoked SSO: 2','172.19.0.1','2026-11-15 11:41:08','ebb6384d6176a21c4d4e32788331068176d7cc71cc4a9750c12f12cfee800566','6b65b13ca314f0383bae7b9d025e8d1621cf0c767ee18fd00007cd1a81e38732'),
(233,'admin','UNLOCK_USER','sv_binh','Group: quarantine','Group: sinhvien | Unblocked IPs: 172.19.0.1','172.19.0.1','2026-11-15 11:41:08','6b65b13ca314f0383bae7b9d025e8d1621cf0c767ee18fd00007cd1a81e38732','7487f85c08854e9b7a641bfe21cd2943d79d3b9557edb98b41a791bd830ab92c'),
(234,'sv_binh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 11:41:08','7487f85c08854e9b7a641bfe21cd2943d79d3b9557edb98b41a791bd830ab92c','5417780e61edea37c65c5c47d1507d090b9e0456734d258c3eb70d33bf1144ef'),
(235,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 11:41:14','5417780e61edea37c65c5c47d1507d090b9e0456734d258c3eb70d33bf1144ef','74232cec091db620d32489d34b357fce41d8c96e7cfd8a0f57484e364eefaf8f'),
(236,'admin','SSO_SINGLE_LOGOUT','ALL_CONNECTED_APPS','','Kích hoạt Single Logout (SLO). Thu hồi thành công 5 phiên ứng dụng vệ tinh.','172.19.0.1','2026-11-15 11:41:15','74232cec091db620d32489d34b357fce41d8c96e7cfd8a0f57484e364eefaf8f','ad5899b7f4792f576fad51f87ba843f42a6a114f13deff23078ffb7ebe085c31'),
(237,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 11:41:20','ad5899b7f4792f576fad51f87ba843f42a6a114f13deff23078ffb7ebe085c31','2bd107efe42073cdfe7bae23ebd4df7d87479284ddeb82f2ad506e95d5939814'),
(238,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 11:41:20','2bd107efe42073cdfe7bae23ebd4df7d87479284ddeb82f2ad506e95d5939814','9a5f04cafee642965a2d36bb99fd7e2bd77c89652fca75a2a140f0afadfdd4fd'),
(239,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 11:41:20','9a5f04cafee642965a2d36bb99fd7e2bd77c89652fca75a2a140f0afadfdd4fd','56d6f91f04d222ffcbd7e5c66e49a3403efd40bb7401a87eee7a5c3911b5eac6'),
(240,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 11:41:20','56d6f91f04d222ffcbd7e5c66e49a3403efd40bb7401a87eee7a5c3911b5eac6','2c3d8b61b028ceea89d76f7f651d46243da1e1e88315cfa1364ce9685d18c9ad'),
(241,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 11:41:20','2c3d8b61b028ceea89d76f7f651d46243da1e1e88315cfa1364ce9685d18c9ad','be6ef0ae27c67b6f8a0d1bca2c7b3df197659c5fe58178291bdec799106a8889'),
(242,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 11:41:20','be6ef0ae27c67b6f8a0d1bca2c7b3df197659c5fe58178291bdec799106a8889','3025584f293a3d3aaddae402f080d27f929eca3af7ca70579839929a89cf9a29'),
(243,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 11:41:20','3025584f293a3d3aaddae402f080d27f929eca3af7ca70579839929a89cf9a29','befa342dc8ec1b3d886835ad3c776df0f98612bcf6bcfc34ea41b6559106c230'),
(244,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 11:41:20','befa342dc8ec1b3d886835ad3c776df0f98612bcf6bcfc34ea41b6559106c230','84e49747ef782d1a81c9f82edb331fe47e7f09ea079f170cc31ead90d8073623'),
(245,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 11:41:20','84e49747ef782d1a81c9f82edb331fe47e7f09ea079f170cc31ead90d8073623','d65401bc50a07c4ec52f0bc09d26aab58b7e6bc50cbb3050b2a0dec49fa8e00f'),
(246,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 11:41:20','d65401bc50a07c4ec52f0bc09d26aab58b7e6bc50cbb3050b2a0dec49fa8e00f','afd1b55488519e2e086cf5b593180931ff4f5ec38fe989039653ef446cc3051d'),
(247,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 11:41:20','afd1b55488519e2e086cf5b593180931ff4f5ec38fe989039653ef446cc3051d','a5f51e8e30aa586d56abac0afc34c72a90139fda5ee9484f6e2e48fe565e71ac'),
(248,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 11:41:20','a5f51e8e30aa586d56abac0afc34c72a90139fda5ee9484f6e2e48fe565e71ac','46f2914d2de61125a3007edf390985647c8cd3e831d5250e5e68a3a58bb48cd5'),
(249,'sv_vinh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 11:43:23','46f2914d2de61125a3007edf390985647c8cd3e831d5250e5e68a3a58bb48cd5','c3245b82ba505f3f726f17f681900cddfc45501eadd6c0d9c3dab8c2b1f1d01e'),
(250,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 12:11:26','c3245b82ba505f3f726f17f681900cddfc45501eadd6c0d9c3dab8c2b1f1d01e','5dba6e20425e594b35bb9fd5ddf19f1ebea1c54692cba7cbd4c6778c13beafb7'),
(251,'sv_tuananh','SELF_REGISTER','OPENLDAP','NEW_USER_REGISTRATION','Group: sinhvien (VLAN 20), Name: Lê Tuấn Anh, Email: tuananh.le@ptit.edu.vn','172.19.0.1','2026-11-15 12:15:52','5dba6e20425e594b35bb9fd5ddf19f1ebea1c54692cba7cbd4c6778c13beafb7','d627bc019c39303f8b4c09acc34940f60b8f3fd387c9125bbb47efe205cbe866'),
(252,'sv_tuananh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 12:15:53','d627bc019c39303f8b4c09acc34940f60b8f3fd387c9125bbb47efe205cbe866','6f961c7cddb75d86dd12da5c458c926088d7da630e4a3efe845527da2a42e23f'),
(253,'gv_huong','SELF_REGISTER','OPENLDAP','NEW_USER_REGISTRATION','Group: giangvien (VLAN 30), Name: Trần Thu Hương, Email: huong.tt@ptit.edu.vn','172.19.0.1','2026-11-15 12:15:53','6f961c7cddb75d86dd12da5c458c926088d7da630e4a3efe845527da2a42e23f','9310a76452fcbd83eedcf3bfefb92b4f8602773405a95b164de62febdbd8cffa'),
(254,'gv_huong','DASHBOARD_LOGIN','SYSTEM','','Login success as user (giangvien)','172.19.0.1','2026-11-15 12:15:53','9310a76452fcbd83eedcf3bfefb92b4f8602773405a95b164de62febdbd8cffa','d0c4a6c7620af3f2dc629a0cb4681ff847ec329f657b805708236f91e49550f3'),
(255,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 12:16:08','d0c4a6c7620af3f2dc629a0cb4681ff847ec329f657b805708236f91e49550f3','2ad1d40df2406c94ec8b569aedf57d047dd1b4291af333c741e978a5ba73efaf'),
(256,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 12:21:48','2ad1d40df2406c94ec8b569aedf57d047dd1b4291af333c741e978a5ba73efaf','a368b2262b7e2856a2399b8280a74213edbfb624a0fe2423163e0ba18fba8b14'),
(257,'sv_tuananh','SELF_REGISTER','OPENLDAP','NEW_USER_REGISTRATION','Group: sinhvien (VLAN 20), Name: Lê Tuấn Anh, Email: tuananh.le@ptit.edu.vn','172.19.0.1','2026-11-15 12:21:53','a368b2262b7e2856a2399b8280a74213edbfb624a0fe2423163e0ba18fba8b14','0b5bbe9f2bf007415f521ee9324b527806e51d437a2b0053e58d51c48ae088ba'),
(258,'sv_tuananh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 12:21:53','0b5bbe9f2bf007415f521ee9324b527806e51d437a2b0053e58d51c48ae088ba','6baa7ccb8bce611bfa2f65a682fb78af50c4c8c9f20d830e62a68694c37ff444'),
(259,'gv_huong','SELF_REGISTER','OPENLDAP','NEW_USER_REGISTRATION','Group: giangvien (VLAN 30), Name: Trần Thu Hương, Email: huong.tt@ptit.edu.vn','172.19.0.1','2026-11-15 12:21:53','6baa7ccb8bce611bfa2f65a682fb78af50c4c8c9f20d830e62a68694c37ff444','e3a65bf5595b62788b9ca2dd0e68d03fb06eaefe26d9d45b04667f9bba47bb1e'),
(260,'gv_huong','DASHBOARD_LOGIN','SYSTEM','','Login success as user (giangvien)','172.19.0.1','2026-11-15 12:21:54','e3a65bf5595b62788b9ca2dd0e68d03fb06eaefe26d9d45b04667f9bba47bb1e','1b97efd30a1ba40f578b3d6247f50e6e5fd827455546856616faeb8aa09c5379'),
(261,'admin','DASHBOARD_LOGOUT','SYSTEM','','Đăng xuất và kích hoạt SLO. Thu hồi 1 phiên ứng dụng.','172.19.0.1','2026-11-15 12:21:56','1b97efd30a1ba40f578b3d6247f50e6e5fd827455546856616faeb8aa09c5379','dda6a61eaf133df6b8519936f9d2938b4384e0b2c50ec54f0a0a2a7063f8cf6e'),
(262,'SYSTEM_ACTIVE_DEFENSE','AUTO_QUARANTINE_BRUTEFORCE','sv_vinh','Group: sinhvien','Group: quarantine (VLAN 99) | Blocked IPs: 172.19.0.1','127.0.0.1','2026-11-15 12:33:45','dda6a61eaf133df6b8519936f9d2938b4384e0b2c50ec54f0a0a2a7063f8cf6e','2f9a19358f94ee082acebd2148aee42434b84e87b24aef1f16f22659f49f1c5b'),
(263,'sv_vinh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (quarantine)','172.19.0.1','2026-11-15 12:34:27','2f9a19358f94ee082acebd2148aee42434b84e87b24aef1f16f22659f49f1c5b','2b8f758002ce0727fd96bea54ee414939e32f359cddd80aa0f59c8a05184ba3c'),
(264,'sv_tuananh','SELF_REGISTER','OPENLDAP','NEW_USER_REGISTRATION','Group: sinhvien (VLAN 20), Name: Lê Tuấn Anh, Email: tuananh.le@ptit.edu.vn','172.19.0.1','2026-11-15 12:34:33','2b8f758002ce0727fd96bea54ee414939e32f359cddd80aa0f59c8a05184ba3c','5062492a304aea33c8d4d52a100da0a974909a1fc2177fb3df925f34b3552018'),
(265,'sv_tuananh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 12:34:34','5062492a304aea33c8d4d52a100da0a974909a1fc2177fb3df925f34b3552018','78c63eb7654d4f7d7caffbabd16dbc4a0d7242002a9c4c3976178740ab035519'),
(266,'gv_huong','SELF_REGISTER','OPENLDAP','NEW_USER_REGISTRATION','Group: giangvien (VLAN 30), Name: Trần Thu Hương, Email: huong.tt@ptit.edu.vn','172.19.0.1','2026-11-15 12:34:34','78c63eb7654d4f7d7caffbabd16dbc4a0d7242002a9c4c3976178740ab035519','679ec793bed5be264f0e8b5b6d55c6578848856d85dee1354f59f43495ce172a'),
(267,'gv_huong','DASHBOARD_LOGIN','SYSTEM','','Login success as user (giangvien)','172.19.0.1','2026-11-15 12:34:34','679ec793bed5be264f0e8b5b6d55c6578848856d85dee1354f59f43495ce172a','0c9239c8f2ee17a778303c674c97cf48187ff02253e55483d7aaeb1f9ff78e78'),
(268,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 12:34:40','0c9239c8f2ee17a778303c674c97cf48187ff02253e55483d7aaeb1f9ff78e78','1ab125d7548fb6f2a5897560a97037e1496d8b44545697d9a781beb5179b8f32'),
(269,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 12:34:40','1ab125d7548fb6f2a5897560a97037e1496d8b44545697d9a781beb5179b8f32','a15ecb22955ee850a4a61aaf0463c09b011099b3bb44e493efc7d7382defe263'),
(270,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 12:34:40','a15ecb22955ee850a4a61aaf0463c09b011099b3bb44e493efc7d7382defe263','9a01c6fc0cf7eee52dba415053eccc8a5ec71d335c220c42694c2738fc10c707'),
(271,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 12:34:40','9a01c6fc0cf7eee52dba415053eccc8a5ec71d335c220c42694c2738fc10c707','9a1ff57bde66cafa2e9cf24fcb1fdf47c58fa94299bece7a392e8ae29bdeae76'),
(272,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 12:34:41','9a1ff57bde66cafa2e9cf24fcb1fdf47c58fa94299bece7a392e8ae29bdeae76','562d02a937b9653173b6498581fffe9d5dc2471a6422201cd0dd962d04970cdc'),
(273,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 12:34:41','562d02a937b9653173b6498581fffe9d5dc2471a6422201cd0dd962d04970cdc','d949637e8cee73dffc648e6f3a196167ed08c9f5238d666462d49d15a60b6819'),
(274,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 12:34:41','d949637e8cee73dffc648e6f3a196167ed08c9f5238d666462d49d15a60b6819','97277717c5f5cc769b8b3743161fb9fc69d8fb3c94f82231c1f5817562158712'),
(275,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 12:34:41','97277717c5f5cc769b8b3743161fb9fc69d8fb3c94f82231c1f5817562158712','36d5b668103c39e9ada7c12d388762d5639f5ecf6b3324ba5969d4838a90ef79'),
(276,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 12:34:41','36d5b668103c39e9ada7c12d388762d5639f5ecf6b3324ba5969d4838a90ef79','2d715fed070aa3ad9c22c042145a8223f394137cdb3a181c2ce0ae6dc0aded8a'),
(277,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 12:34:41','2d715fed070aa3ad9c22c042145a8223f394137cdb3a181c2ce0ae6dc0aded8a','a8e9fe957be72eec5a0746087db3098ed02eb3ab6ee941a2b3cd885722086eda'),
(278,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 12:34:41','a8e9fe957be72eec5a0746087db3098ed02eb3ab6ee941a2b3cd885722086eda','87a7d2569c11f42b7cef56312599fff73e267061d26247c6d37540cf9e5fff8d'),
(279,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 12:34:41','87a7d2569c11f42b7cef56312599fff73e267061d26247c6d37540cf9e5fff8d','2d9bcc9d24d7f31161b8eb11dcdce70795fd28433c0cb929b5f6ba2a2cfa5049'),
(280,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 12:34:51','2d9bcc9d24d7f31161b8eb11dcdce70795fd28433c0cb929b5f6ba2a2cfa5049','9fc8c2cb7b14bab20a74df8677867fdd525a3a01704eff60c0f85b9dd13c49f3'),
(281,'admin','UNLOCK_USER','sv_binh','Group: quarantine','Group: sinhvien | Unblocked IPs: Không có','172.19.0.1','2026-11-15 12:34:51','9fc8c2cb7b14bab20a74df8677867fdd525a3a01704eff60c0f85b9dd13c49f3','8b349a24c5dfad4d852fffcba438ffb9fc6522972100ad95184c246ad49d54e9'),
(282,'sv_binh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 12:34:51','8b349a24c5dfad4d852fffcba438ffb9fc6522972100ad95184c246ad49d54e9','d8e74b9e26c53ba07dcc3cfb46a5e56e03defaa053374bea6d70bca92434144a'),
(283,'admin','MANUAL_QUARANTINE','sv_binh','Group: sinhvien','Group: quarantine (VLAN 99) | Blocked IPs: 172.19.0.1 | Revoked SSO: 2','172.19.0.1','2026-11-15 12:34:51','d8e74b9e26c53ba07dcc3cfb46a5e56e03defaa053374bea6d70bca92434144a','9a031511ed5483e6d434c15e300cca08faf51deb5d296fe1c4b1383c84adddc4'),
(284,'admin','UNLOCK_USER','sv_binh','Group: quarantine','Group: sinhvien | Unblocked IPs: 172.19.0.1','172.19.0.1','2026-11-15 12:34:52','9a031511ed5483e6d434c15e300cca08faf51deb5d296fe1c4b1383c84adddc4','33f418c1128de2ec0b6213f8ae79943a2c0da838ddd80fd4fd8384c3522afb24'),
(285,'sv_binh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 12:34:52','33f418c1128de2ec0b6213f8ae79943a2c0da838ddd80fd4fd8384c3522afb24','4891442fe6b8c149f74939ac061d1350b36c8629f4da206e7f2c9917a0029715'),
(286,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 12:35:23','4891442fe6b8c149f74939ac061d1350b36c8629f4da206e7f2c9917a0029715','d8cd20a117fef2af5dcd57b571b6b9be31d11c0f0763fddca0e0bd65ba6e29ba'),
(287,'SYSTEM_ACTIVE_DEFENSE','AUTO_QUARANTINE_BRUTEFORCE','sv_vinh','Group: sinhvien','Group: quarantine (VLAN 99) | Blocked IPs: 172.19.0.1','127.0.0.1','2026-11-15 12:35:48','d8cd20a117fef2af5dcd57b571b6b9be31d11c0f0763fddca0e0bd65ba6e29ba','ae664ca689b4e3bce19085e1210ec4cccc64efd748e4013c684ed06864b5a1e7'),
(288,'sv_vinh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (quarantine)','172.19.0.1','2026-11-15 12:35:53','ae664ca689b4e3bce19085e1210ec4cccc64efd748e4013c684ed06864b5a1e7','047819356fd84cb2d98e5dc80f08c968ab5353fa85d767c93210480a3f89bb58'),
(289,'SYSTEM_ACTIVE_DEFENSE','AUTO_QUARANTINE_BRUTEFORCE','sv_vinh','Group: sinhvien','Group: quarantine (VLAN 99) | Blocked IPs: 172.19.0.1','127.0.0.1','2026-11-15 12:36:23','047819356fd84cb2d98e5dc80f08c968ab5353fa85d767c93210480a3f89bb58','501dee6258f603541a78faa4265b95b8f35d0184a2591d43755f4e3f406558af'),
(290,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 12:36:37','501dee6258f603541a78faa4265b95b8f35d0184a2591d43755f4e3f406558af','78a86edb2c5216ef3600633b435b7c1b13abc87511dc85152691a978e2f02414'),
(291,'admin','SSO_SINGLE_LOGOUT','ALL_CONNECTED_APPS','','Kích hoạt Single Logout (SLO). Thu hồi thành công 5 phiên ứng dụng vệ tinh.','172.19.0.1','2026-11-15 12:36:37','78a86edb2c5216ef3600633b435b7c1b13abc87511dc85152691a978e2f02414','f5f74d059cc07224f0e0431eba97cde6f36a2bb5242e8aa8b3356984a7886876'),
(292,'admin','DASHBOARD_LOGIN_FAILED','DASHBOARD','Lần sai thứ 1/5','Còn 4 lần thử trước khi bị khóa','172.19.0.1','2026-11-15 12:36:56','f5f74d059cc07224f0e0431eba97cde6f36a2bb5242e8aa8b3356984a7886876','b735e29d8b63a910666b8da192ec297e4fc2468dbe598ceaa1a0a7ecd7290e2a'),
(293,'admin','DASHBOARD_LOGIN_FAILED','DASHBOARD','Lần sai thứ 2/5','Còn 3 lần thử trước khi bị khóa','172.19.0.1','2026-11-15 12:36:56','b735e29d8b63a910666b8da192ec297e4fc2468dbe598ceaa1a0a7ecd7290e2a','43fe8e433b8ee924345fdb2c8853e4c285ddca72d5f2ba39c7d3e003306a15f0'),
(294,'admin','DASHBOARD_LOGIN_FAILED','DASHBOARD','Lần sai thứ 3/5','Còn 2 lần thử trước khi bị khóa','172.19.0.1','2026-11-15 12:36:56','43fe8e433b8ee924345fdb2c8853e4c285ddca72d5f2ba39c7d3e003306a15f0','b7f303eef4571a6567d709e4a82e9ca0558801d985c3101bc98f061510ff1064'),
(295,'admin','DASHBOARD_LOGIN_FAILED','DASHBOARD','Lần sai thứ 4/5','Còn 1 lần thử trước khi bị khóa','172.19.0.1','2026-11-15 12:36:56','b7f303eef4571a6567d709e4a82e9ca0558801d985c3101bc98f061510ff1064','f6cafb727e16f31977e55e0c43d5228c3ed75a0402e9c575f184b079bc09f82d'),
(296,'admin','DASHBOARD_ACCOUNT_LOCKED','DASHBOARD','Nhập sai 5 lần liên tiếp từ IP 172.19.0.1','Khóa tài khoản admin trong 60 phút','172.19.0.1','2026-11-15 12:36:56','f6cafb727e16f31977e55e0c43d5228c3ed75a0402e9c575f184b079bc09f82d','4c6906a79814ef60a3c05ae3c4df36c9b0b785a173ca9cac03d9ff96a7d17af4'),
(297,'172.19.0.1','DASHBOARD_IP_BLOCKED','DASHBOARD','Thử dò tài khoản: admin','Chặn địa chỉ IP 172.19.0.1 trong 60 phút','172.19.0.1','2026-11-15 12:36:56','4c6906a79814ef60a3c05ae3c4df36c9b0b785a173ca9cac03d9ff96a7d17af4','770c7706c2ef9daefb6255c6aab4d5592f81f7933821b6698d94c97523f6f201'),
(298,'admin','MFA_LOGIN_SUCCESS','SYSTEM','','Xác thực MFA thành công qua mã TOTP 6 số cho admin (TimeStep: 59824877)','172.19.0.1','2026-11-15 12:38:34','770c7706c2ef9daefb6255c6aab4d5592f81f7933821b6698d94c97523f6f201','9a24492db0c074430c7f90fd6ec5052f1f8873d11e3680810490ea0a32fe752a'),
(299,'admin','MFA_REPLAY_ATTEMPT','SYSTEM','Replayed OTP code: 142374','','172.19.0.1','2026-11-15 12:38:34','9a24492db0c074430c7f90fd6ec5052f1f8873d11e3680810490ea0a32fe752a','beebf08754193bac79ed10b079eaf2827d357c420bebd342d1c2819e430cc6bd'),
(300,'admin','MFA_LOGIN_FAILED','SYSTEM','Invalid TOTP','Lần sai thứ 1/3. Còn 2 lần thử.','172.19.0.1','2026-11-15 12:38:34','beebf08754193bac79ed10b079eaf2827d357c420bebd342d1c2819e430cc6bd','fc0535fd90e8ac691c5a07c26b0ac0e0d66aa8efb87d12e669b01ad6c6e7e684'),
(301,'admin','MFA_LOGIN_FAILED','SYSTEM','Invalid TOTP','Lần sai thứ 2/3. Còn 1 lần thử.','172.19.0.1','2026-11-15 12:38:34','fc0535fd90e8ac691c5a07c26b0ac0e0d66aa8efb87d12e669b01ad6c6e7e684','fdedf6680d3774ad2526faceaf2c8948be5f096712c6e7734dc14be3b9e5d0c6'),
(302,'admin','MFA_LOCKED','SYSTEM','Nhập sai 3 lần liên tiếp','Khóa MFA trong 10 phút','172.19.0.1','2026-11-15 12:38:35','fdedf6680d3774ad2526faceaf2c8948be5f096712c6e7734dc14be3b9e5d0c6','900002fc660eead08993ba15033d9904e162b894c1e36ee23bb37d2e9c01ac1b'),
(303,'admin','DASHBOARD_LOGIN_FAILED','DASHBOARD','Lần sai thứ 1/5','Còn 4 lần thử trước khi bị khóa','172.19.0.1','2026-11-15 12:39:02','900002fc660eead08993ba15033d9904e162b894c1e36ee23bb37d2e9c01ac1b','540da086ec9db48e6820ee3d3c005414858809a2202e808fd03a67331af60690'),
(304,'admin','DASHBOARD_LOGIN_FAILED','DASHBOARD','Lần sai thứ 2/5','Còn 3 lần thử trước khi bị khóa','172.19.0.1','2026-11-15 12:39:02','540da086ec9db48e6820ee3d3c005414858809a2202e808fd03a67331af60690','33b0fb5c317dfa1d175f6a40e5267a992e99c4b2d9ae2852a898f9c2e58ffe96'),
(305,'admin','DASHBOARD_LOGIN_FAILED','DASHBOARD','Lần sai thứ 3/5','Còn 2 lần thử trước khi bị khóa','172.19.0.1','2026-11-15 12:39:02','33b0fb5c317dfa1d175f6a40e5267a992e99c4b2d9ae2852a898f9c2e58ffe96','a7686430a21058bfecbff7f02809c6fdcaddfa9ad60454880567cb6e21ba9559'),
(306,'admin','DASHBOARD_LOGIN_FAILED','DASHBOARD','Lần sai thứ 4/5','Còn 1 lần thử trước khi bị khóa','172.19.0.1','2026-11-15 12:39:02','a7686430a21058bfecbff7f02809c6fdcaddfa9ad60454880567cb6e21ba9559','dc9857a9136eb5d4ba5b853e321808d8cb480ffecf592634cb5e95c8ccb69e0c'),
(307,'admin','DASHBOARD_ACCOUNT_LOCKED','DASHBOARD','Nhập sai 5 lần liên tiếp từ IP 172.19.0.1','Khóa tài khoản admin trong 60 phút','172.19.0.1','2026-11-15 12:39:02','dc9857a9136eb5d4ba5b853e321808d8cb480ffecf592634cb5e95c8ccb69e0c','1234ef859dacb91a5805b5cc26efebdef160bad57bb1552801dd3848b6f08051'),
(308,'172.19.0.1','DASHBOARD_IP_BLOCKED','DASHBOARD','Thử dò tài khoản: admin','Chặn địa chỉ IP 172.19.0.1 trong 60 phút','172.19.0.1','2026-11-15 12:39:02','1234ef859dacb91a5805b5cc26efebdef160bad57bb1552801dd3848b6f08051','394a593d07e2ab58bea22fa037312d3d4d66efc85bceb6a28ec7731c5ef3e476'),
(309,'sv_vinh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 12:40:54','394a593d07e2ab58bea22fa037312d3d4d66efc85bceb6a28ec7731c5ef3e476','af67dddb345ca2913aa21fd5fdfa7cacb938dfc333cebfec5bb5799bf0cc509d'),
(310,'gv_nguyen','DASHBOARD_LOGIN','SYSTEM','','Login success as user (giangvien)','172.19.0.1','2026-11-15 12:40:55','af67dddb345ca2913aa21fd5fdfa7cacb938dfc333cebfec5bb5799bf0cc509d','ae8796682e55173c586235414d14cd60a24c1d1d71e0ab269c9bc7a431fd0138'),
(311,'sv_vinh','SSO_SINGLE_LOGOUT','ALL_CONNECTED_APPS','','Kích hoạt Single Logout (SLO). Thu hồi thành công 4 phiên ứng dụng vệ tinh.','172.19.0.1','2026-11-15 12:40:55','ae8796682e55173c586235414d14cd60a24c1d1d71e0ab269c9bc7a431fd0138','61c95481737ab6b57720ef1cd0254dcdca1ac569c09e2b20e346934e2f1e6066'),
(312,'admin','DASHBOARD_ACCOUNT_BLOCKED','DASHBOARD','IP: 172.19.0.1','Tài khoản đang bị khóa. Còn 59 phút.','172.19.0.1','2026-11-15 12:40:55','61c95481737ab6b57720ef1cd0254dcdca1ac569c09e2b20e346934e2f1e6066','d6b5200fc8900a5bcd7f96607299ab60033e55f04218164f7b7a941f08484038'),
(313,'admin','DASHBOARD_ACCOUNT_BLOCKED','DASHBOARD','IP: 172.19.0.1','Tài khoản đang bị khóa. Còn 58 phút.','172.19.0.1','2026-11-15 12:41:04','d6b5200fc8900a5bcd7f96607299ab60033e55f04218164f7b7a941f08484038','31baa3154d36e65010255a65abf1268b07f86777c5a5bf1f11b4ba05fad5fbf0'),
(314,'admin','DASHBOARD_ACCOUNT_BLOCKED','DASHBOARD','IP: 172.19.0.1','Tài khoản đang bị khóa. Còn 58 phút.','172.19.0.1','2026-11-15 12:41:10','31baa3154d36e65010255a65abf1268b07f86777c5a5bf1f11b4ba05fad5fbf0','bff84a1ae4906b8a00d1896cd1ce2d19a23851e84a8f48d07b5b24bd531ee6a0'),
(315,'sv_vinh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 12:41:22','bff84a1ae4906b8a00d1896cd1ce2d19a23851e84a8f48d07b5b24bd531ee6a0','4d6faf6d68dd80984f39c6b179817d79e1f008fe255120d508aa499dbc92d562'),
(316,'gv_nguyen','DASHBOARD_LOGIN','SYSTEM','','Login success as user (giangvien)','172.19.0.1','2026-11-15 12:41:22','4d6faf6d68dd80984f39c6b179817d79e1f008fe255120d508aa499dbc92d562','f0b5b7a208406fc7fdab35597967efb9af74ffe06340c71629ea9d08b9857a67'),
(317,'sv_vinh','SSO_SINGLE_LOGOUT','ALL_CONNECTED_APPS','','Kích hoạt Single Logout (SLO). Thu hồi thành công 4 phiên ứng dụng vệ tinh.','172.19.0.1','2026-11-15 12:41:22','f0b5b7a208406fc7fdab35597967efb9af74ffe06340c71629ea9d08b9857a67','70e0185684cc66237c51d789cdb30f7972612f0cddea51f9aab75ac4a978c833'),
(318,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 12:41:22','70e0185684cc66237c51d789cdb30f7972612f0cddea51f9aab75ac4a978c833','6d4dc7b6be1476c59fa14701f28bd5fa18dc2e5bdb40204280afeb9c758cc575'),
(319,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 12:41:27','6d4dc7b6be1476c59fa14701f28bd5fa18dc2e5bdb40204280afeb9c758cc575','0751f856169ca5a52c1dab1b044f9f17039673d310d37a3a07ca60f059ddfe7e'),
(320,'admin','DASHBOARD_LOGIN_FAILED','DASHBOARD','Lần sai thứ 1/5','Còn 4 lần thử trước khi bị khóa','172.19.0.1','2026-11-15 12:42:13','0751f856169ca5a52c1dab1b044f9f17039673d310d37a3a07ca60f059ddfe7e','b6be7a51ffb8f56942568eb6abfd755bed33c6ca933f871f546f63622e356651'),
(321,'admin','DASHBOARD_LOGIN_FAILED','DASHBOARD','Lần sai thứ 2/5','Còn 3 lần thử trước khi bị khóa','172.19.0.1','2026-11-15 12:42:13','b6be7a51ffb8f56942568eb6abfd755bed33c6ca933f871f546f63622e356651','a0c436f09c907823ce56acde01cf5995255e8ade85cf136b681320b3e755cf33'),
(322,'admin','DASHBOARD_LOGIN_FAILED','DASHBOARD','Lần sai thứ 3/5','Còn 2 lần thử trước khi bị khóa','172.19.0.1','2026-11-15 12:42:13','a0c436f09c907823ce56acde01cf5995255e8ade85cf136b681320b3e755cf33','12d27e31d980347dc4fa31f004bf8a359e4ff9b47646f5f98f54b47b7b7f4667'),
(323,'admin','DASHBOARD_LOGIN_FAILED','DASHBOARD','Lần sai thứ 4/5','Còn 1 lần thử trước khi bị khóa','172.19.0.1','2026-11-15 12:42:13','12d27e31d980347dc4fa31f004bf8a359e4ff9b47646f5f98f54b47b7b7f4667','1652a7389819730a860074def8f319c67163a4ee33881269eed72ebe1b950ee7'),
(324,'admin','DASHBOARD_ACCOUNT_LOCKED','DASHBOARD','Nhập sai 5 lần liên tiếp từ IP 172.19.0.1','Khóa tài khoản admin trong 60 phút','172.19.0.1','2026-11-15 12:42:13','1652a7389819730a860074def8f319c67163a4ee33881269eed72ebe1b950ee7','e139cab51ed9645e19c3b52f105e49114634c8fde3efb5d256b0ffe770cbb4f3'),
(325,'172.19.0.1','DASHBOARD_IP_BLOCKED','DASHBOARD','Thử dò tài khoản: admin','Chặn địa chỉ IP 172.19.0.1 trong 60 phút','172.19.0.1','2026-11-15 12:42:13','e139cab51ed9645e19c3b52f105e49114634c8fde3efb5d256b0ffe770cbb4f3','9b2e27f2d32668acdfa779057801cc9c240f1265a4bd586c9e4eccfe4f330495'),
(326,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 12:42:13','9b2e27f2d32668acdfa779057801cc9c240f1265a4bd586c9e4eccfe4f330495','325a7d944d3d8d9bb9f2bd2ac68c57e717e4cc24fe44f3518b0b664658dad7e4'),
(327,'admin','MFA_LOGIN_SUCCESS','SYSTEM','','Xác thực MFA thành công qua mã TOTP 6 số cho admin (TimeStep: 59824884)','172.19.0.1','2026-11-15 12:42:18','325a7d944d3d8d9bb9f2bd2ac68c57e717e4cc24fe44f3518b0b664658dad7e4','2302c2fe6c71e343e9c882ccbc1c5ec70ed893f2b28a8d9d34c4f3cfdaa62211'),
(328,'admin','MFA_REPLAY_ATTEMPT','SYSTEM','Replayed OTP code: 815974','','172.19.0.1','2026-11-15 12:42:19','2302c2fe6c71e343e9c882ccbc1c5ec70ed893f2b28a8d9d34c4f3cfdaa62211','65ec5b5f5f2a2d44590c503bc2d08b7e33e79def38d14f2000ad445fe984ed69'),
(329,'admin','MFA_LOGIN_FAILED','SYSTEM','Invalid TOTP','Lần sai thứ 1/3. Còn 2 lần thử.','172.19.0.1','2026-11-15 12:42:19','65ec5b5f5f2a2d44590c503bc2d08b7e33e79def38d14f2000ad445fe984ed69','12c6c4dec8cce4a310852e9c041e8145de97e3630f6616402fae29558fb0d27e'),
(330,'admin','MFA_LOGIN_FAILED','SYSTEM','Invalid TOTP','Lần sai thứ 2/3. Còn 1 lần thử.','172.19.0.1','2026-11-15 12:42:19','12c6c4dec8cce4a310852e9c041e8145de97e3630f6616402fae29558fb0d27e','68518e1d4f4cb2f9914a4135f58c420d63edc3512ab5f6853725c8a8e6833f36'),
(331,'admin','MFA_LOCKED','SYSTEM','Nhập sai 3 lần liên tiếp','Khóa MFA trong 10 phút','172.19.0.1','2026-11-15 12:42:19','68518e1d4f4cb2f9914a4135f58c420d63edc3512ab5f6853725c8a8e6833f36','8d1ace61202300ba780124a777f7c86a876606697e1295f414c7dd271f0d705e'),
(332,'sv_vinh','DASHBOARD_LOGIN_FAILED','DASHBOARD','Lần sai thứ 1/5','Còn 4 lần thử trước khi bị khóa','172.19.0.1','2026-11-15 12:44:12','8d1ace61202300ba780124a777f7c86a876606697e1295f414c7dd271f0d705e','8f0ec275916a43bdc6eacea5369bd8ea2bf50ef3106442e1c55155d9652d7d5e'),
(333,'sv_vinh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 12:44:21','8f0ec275916a43bdc6eacea5369bd8ea2bf50ef3106442e1c55155d9652d7d5e','94316ea0396b3a611770ec3f80bd72c01edf51f5a89fc7aa1656cde078858f21'),
(334,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 12:44:32','94316ea0396b3a611770ec3f80bd72c01edf51f5a89fc7aa1656cde078858f21','389af390ae79f2da97a2fed67210417e52d3b5e0d4d7d0794aed54b8e1b18bd3'),
(335,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 12:44:44','389af390ae79f2da97a2fed67210417e52d3b5e0d4d7d0794aed54b8e1b18bd3','8e31ab056d63ee6aef15ee46618d747118da8308394a3cd57483e9fccddba1aa'),
(336,'admin','UNLOCK_USER','sv_binh','Group: quarantine','Group: sinhvien | Unblocked IPs: Không có','172.19.0.1','2026-11-15 12:44:44','8e31ab056d63ee6aef15ee46618d747118da8308394a3cd57483e9fccddba1aa','c522318a0ce3d4a1dae01fdc7b57eec5723a7c4e5b455e8099885c4ae8cda6fb'),
(337,'sv_binh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 12:44:44','c522318a0ce3d4a1dae01fdc7b57eec5723a7c4e5b455e8099885c4ae8cda6fb','aba11310b9542a3b76cf8e5657b0cc9a3d374ead1e9a2679a0febbcb55bb9e46'),
(338,'admin','MANUAL_QUARANTINE','sv_binh','Group: sinhvien','Group: quarantine (VLAN 99) | Blocked IPs: 172.19.0.1 | Revoked SSO: 2','172.19.0.1','2026-11-15 12:44:44','aba11310b9542a3b76cf8e5657b0cc9a3d374ead1e9a2679a0febbcb55bb9e46','3633cdb66d78f37a64cca483d4d9a72007611df2fabd6f569e41d66b42a1649a'),
(339,'admin','UNLOCK_USER','sv_binh','Group: quarantine','Group: sinhvien | Unblocked IPs: 172.19.0.1','172.19.0.1','2026-11-15 12:44:45','3633cdb66d78f37a64cca483d4d9a72007611df2fabd6f569e41d66b42a1649a','cb20f9089663da3f6c7bf6271d0c25834c940ee6bfa0afafd6f539903b1a61f3'),
(340,'sv_binh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 12:44:45','cb20f9089663da3f6c7bf6271d0c25834c940ee6bfa0afafd6f539903b1a61f3','4dba853b53e39f5f40453c18db809bf8f740fce31abb6723f0eecc5f113b7f5e'),
(341,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 12:44:49','4dba853b53e39f5f40453c18db809bf8f740fce31abb6723f0eecc5f113b7f5e','42895adc950c4b7a792611a77b4b140eec4008f5193a61bd1163100ef1fa3903'),
(342,'admin','SSO_SINGLE_LOGOUT','ALL_CONNECTED_APPS','','Kích hoạt Single Logout (SLO). Thu hồi thành công 5 phiên ứng dụng vệ tinh.','172.19.0.1','2026-11-15 12:44:50','42895adc950c4b7a792611a77b4b140eec4008f5193a61bd1163100ef1fa3903','9d34cc6dcee05fb2f706ccee1033afb8e81ae93de0715451f09e964f6940fb6f'),
(343,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 12:44:56','9d34cc6dcee05fb2f706ccee1033afb8e81ae93de0715451f09e964f6940fb6f','d26daea4cb6d65c68821605fe74bc7013488babcbf9f5f0eaf0cffc79eafb744'),
(344,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 12:44:56','d26daea4cb6d65c68821605fe74bc7013488babcbf9f5f0eaf0cffc79eafb744','d708ed99df5c07bdde32e85001aa0e7932289fceb4f27210d78b3c71548e309b'),
(345,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 12:44:56','d708ed99df5c07bdde32e85001aa0e7932289fceb4f27210d78b3c71548e309b','b5f7d9bf10696236d2c9ff492f5bf3cd765cbe8b2f64d8c12c2c5bda8a74138c'),
(346,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 12:44:56','b5f7d9bf10696236d2c9ff492f5bf3cd765cbe8b2f64d8c12c2c5bda8a74138c','edfe1051f56d78713ec6446e0ae8cd20b0b01ec40a7de6b41bfc8d38f687481a'),
(347,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 12:44:56','edfe1051f56d78713ec6446e0ae8cd20b0b01ec40a7de6b41bfc8d38f687481a','1358acd9bf6a939d236c34318617e0e3b5d117c8d4b5ba0f2ea4f9fed575017d'),
(348,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 12:44:56','1358acd9bf6a939d236c34318617e0e3b5d117c8d4b5ba0f2ea4f9fed575017d','dc7ac400d58f214345a2b0974252ba447909394ba7d2a203ae23c563b66760d9'),
(349,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 12:44:56','dc7ac400d58f214345a2b0974252ba447909394ba7d2a203ae23c563b66760d9','6871d0f88db42492f7f58778102a9a66734f933e3e11dea6f6f833367620f2c4'),
(350,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 12:44:56','6871d0f88db42492f7f58778102a9a66734f933e3e11dea6f6f833367620f2c4','95ddf52ee46163f362551e37ca5f0814275901e30e5bdf091f8b67a3ee8fa59c'),
(351,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 12:44:56','95ddf52ee46163f362551e37ca5f0814275901e30e5bdf091f8b67a3ee8fa59c','e20173d30fe0ffdf2f5fc41969d2c8d87e3dfe2239c4b201e34a77635321ca04'),
(352,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 12:44:57','e20173d30fe0ffdf2f5fc41969d2c8d87e3dfe2239c4b201e34a77635321ca04','0a0c93c57caca5203f5e444cde26cdcb5bd4915c24c34223ac5878cf7cd9b6cb'),
(353,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 12:44:57','0a0c93c57caca5203f5e444cde26cdcb5bd4915c24c34223ac5878cf7cd9b6cb','77caeeffd81e5f62c9ac90ef1688b38de04ddca9dc6a3d35e4cfc01e4b3eac6c'),
(354,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 12:44:57','77caeeffd81e5f62c9ac90ef1688b38de04ddca9dc6a3d35e4cfc01e4b3eac6c','5980d05599aa64f0bc0151471925965980fe5b4f6272f79df0fd4fd568f9318b'),
(355,'sv_tuananh','SELF_REGISTER','OPENLDAP','NEW_USER_REGISTRATION','Group: sinhvien (VLAN 20), Name: Lê Tuấn Anh, Email: tuananh.le@ptit.edu.vn','172.19.0.1','2026-11-15 12:45:04','5980d05599aa64f0bc0151471925965980fe5b4f6272f79df0fd4fd568f9318b','7e7b8a3ab338dead27a2dfdbf04b10bc3f4d0416ff0c15edcb155fe4b7d78c52'),
(356,'sv_tuananh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 12:45:04','7e7b8a3ab338dead27a2dfdbf04b10bc3f4d0416ff0c15edcb155fe4b7d78c52','dbb8821a55919b5a58e9d08ae92027a9807a538cffa4a70886d7d16950f4c302'),
(357,'gv_huong','SELF_REGISTER','OPENLDAP','NEW_USER_REGISTRATION','Group: giangvien (VLAN 30), Name: Trần Thu Hương, Email: huong.tt@ptit.edu.vn','172.19.0.1','2026-11-15 12:45:04','dbb8821a55919b5a58e9d08ae92027a9807a538cffa4a70886d7d16950f4c302','d6c0722446415dbc3f0a7ad20ed07764e25c7c25865d83a424ada05881642989'),
(358,'gv_huong','DASHBOARD_LOGIN','SYSTEM','','Login success as user (giangvien)','172.19.0.1','2026-11-15 12:45:04','d6c0722446415dbc3f0a7ad20ed07764e25c7c25865d83a424ada05881642989','e106aa5079333d9092d134cac5411832ddc8ec60cb11b85a33fe42e1af0498a7'),
(359,'admin','DASHBOARD_LOGOUT','SYSTEM','','Đăng xuất và kích hoạt SLO. Thu hồi 0 phiên ứng dụng.','172.19.0.1','2026-11-15 12:46:14','e106aa5079333d9092d134cac5411832ddc8ec60cb11b85a33fe42e1af0498a7','fcc6aed47306c39882c7f38a052ae1fe8d01a8dd4fdf0500d508f88dfd57224b'),
(360,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 12:46:23','fcc6aed47306c39882c7f38a052ae1fe8d01a8dd4fdf0500d508f88dfd57224b','40b275a49e58437492e40b9aaf1ba3fa0e60a405e76d362e6b47cb61854da86b'),
(361,'SYSTEM_ACTIVE_DEFENSE','AUTO_QUARANTINE_BRUTEFORCE','sv_vinh','Group: sinhvien','Group: quarantine (VLAN 99) | Blocked IPs: 172.19.0.1','127.0.0.1','2026-11-15 12:47:28','40b275a49e58437492e40b9aaf1ba3fa0e60a405e76d362e6b47cb61854da86b','02b965013703804e8e9c5201c67ea3010a5e03d4c8c9d63a3f641db48f2e84d1'),
(362,'admin','UNLOCK_USER','sv_vinh','Group: quarantine','Group: sinhvien | Unblocked IPs: 172.19.0.1','172.19.0.1','2026-11-15 12:48:10','02b965013703804e8e9c5201c67ea3010a5e03d4c8c9d63a3f641db48f2e84d1','d4da1d6e0e6f889b96f2fa68d4e1cc60c5115a59a4af713a488e1f521bcb6362'),
(363,'sv_vinh','DASHBOARD_LOGIN_FAILED','DASHBOARD','Lần sai thứ 1/5','Còn 4 lần thử trước khi bị khóa','172.19.0.1','2026-11-15 12:48:33','d4da1d6e0e6f889b96f2fa68d4e1cc60c5115a59a4af713a488e1f521bcb6362','c2858fe8437a22b7100628225ad998bf9fd18ef4845d66be2baf552b34207cf5'),
(364,'sv_vinh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 12:48:44','c2858fe8437a22b7100628225ad998bf9fd18ef4845d66be2baf552b34207cf5','adf9f55997177450372a7a446e6f9eac89507f2029180f855428643ec25ae74c'),
(365,'sv_vinh','DASHBOARD_LOGOUT','SYSTEM','','Đăng xuất và kích hoạt SLO. Thu hồi 2 phiên ứng dụng.','172.19.0.1','2026-11-15 12:49:20','adf9f55997177450372a7a446e6f9eac89507f2029180f855428643ec25ae74c','432dfe5d72fd5a11db45027dfa1a6a960cd2ea24b30a0446a7c4398fa513ffe2'),
(366,'172.19.0.1','PASSWORD_RESET_REQUESTED','sv_an','','Tạo liên kết đổi mật khẩu gửi tới sv_an@ptit.edu.vn (Token TTL 15m)','172.19.0.1','2026-11-15 13:11:27','432dfe5d72fd5a11db45027dfa1a6a960cd2ea24b30a0446a7c4398fa513ffe2','5cb387cfa7d32f2fa089bbb805d779c5bed79900193e2e241dad5bd5bb7bbb29'),
(367,'sv_an','PASSWORD_RESET_SUCCESS','sv_an','','Đặt lại mật khẩu thành công qua email xác thực sv_an@ptit.edu.vn','172.19.0.1','2026-11-15 13:11:27','5cb387cfa7d32f2fa089bbb805d779c5bed79900193e2e241dad5bd5bb7bbb29','7d45096ff829063ec04fce3f48dd7a4492d99e0107fa24de7e0f2d939f054808'),
(368,'172.19.0.1','PASSWORD_RESET_REQUESTED','sv_an','','Tạo liên kết đổi mật khẩu gửi tới sv_an@ptit.edu.vn (Token TTL 15m)','172.19.0.1','2026-11-15 13:11:28','7d45096ff829063ec04fce3f48dd7a4492d99e0107fa24de7e0f2d939f054808','bcf9c8c424a7f1da2bf14c9e424f0d1be9b8fd3a1133a8f5f8256390085c4e1a'),
(369,'172.19.0.1','PASSWORD_RESET_REQUESTED','sv_an','','Tạo liên kết đổi mật khẩu gửi tới sv_an@ptit.edu.vn (Token TTL 15m)','172.19.0.1','2026-11-15 13:11:28','bcf9c8c424a7f1da2bf14c9e424f0d1be9b8fd3a1133a8f5f8256390085c4e1a','3e79198da2bbb8eede4d87de829c9df5a3f1dfd50d6ec72504e472acf012a615'),
(370,'sv_an','PASSWORD_RESET_SUCCESS','sv_an','','Đặt lại mật khẩu thành công qua email xác thực sv_an@ptit.edu.vn','172.19.0.1','2026-11-15 13:11:28','3e79198da2bbb8eede4d87de829c9df5a3f1dfd50d6ec72504e472acf012a615','19fcfb06fc74f4499cca0305a7d5a7db8d54e174d3435ead0e16396dff921718'),
(371,'sv_vinh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 13:13:07','19fcfb06fc74f4499cca0305a7d5a7db8d54e174d3435ead0e16396dff921718','ce7e4fda0d16336fd8c0dc206085d7493d03aaa1a54b94b85e6a45ff5176bcc9'),
(372,'gv_nguyen','DASHBOARD_LOGIN','SYSTEM','','Login success as user (giangvien)','172.19.0.1','2026-11-15 13:13:07','ce7e4fda0d16336fd8c0dc206085d7493d03aaa1a54b94b85e6a45ff5176bcc9','cf6f78138a6d3f0218ac7f840eb433338789189fd6d2b28d613a1ddf76a7872c'),
(373,'sv_vinh','SSO_SINGLE_LOGOUT','ALL_CONNECTED_APPS','','Kích hoạt Single Logout (SLO). Thu hồi thành công 4 phiên ứng dụng vệ tinh.','172.19.0.1','2026-11-15 13:13:08','cf6f78138a6d3f0218ac7f840eb433338789189fd6d2b28d613a1ddf76a7872c','e5248441d5fb931a58604d3318625001f4721e7473d7a302a80f9b22fac8376c'),
(374,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 13:13:08','e5248441d5fb931a58604d3318625001f4721e7473d7a302a80f9b22fac8376c','4e912fce0f5f2400d7799a3b46ca671ad5663d4a201396ccc5fd1c9ed07fab88'),
(375,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 13:13:24','4e912fce0f5f2400d7799a3b46ca671ad5663d4a201396ccc5fd1c9ed07fab88','c74de09a44e999ca08856b07ba326cc4b894e11c803d3a322b336b9f4943043d'),
(376,'admin','UNLOCK_USER','sv_binh','Group: quarantine','Group: sinhvien | Unblocked IPs: Không có','172.19.0.1','2026-11-15 13:13:24','c74de09a44e999ca08856b07ba326cc4b894e11c803d3a322b336b9f4943043d','428378e6a6e22d67957b1619ae7755cd5d0b3dd77ac1c11d7de72b57a39efb49'),
(377,'sv_binh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 13:13:24','428378e6a6e22d67957b1619ae7755cd5d0b3dd77ac1c11d7de72b57a39efb49','9ac8f8faed184b6d469293d4792df1c1dd9f60cba4ee8ed920314ffa9747acd6'),
(378,'admin','MANUAL_QUARANTINE','sv_binh','Group: sinhvien','Group: quarantine (VLAN 99) | Blocked IPs: 172.19.0.1 | Revoked SSO: 2','172.19.0.1','2026-11-15 13:13:24','9ac8f8faed184b6d469293d4792df1c1dd9f60cba4ee8ed920314ffa9747acd6','96325d640a6bc8ba5fe62f033737a7bd369af7338c1cf4ce1536e1f00048ab13'),
(379,'admin','UNLOCK_USER','sv_binh','Group: quarantine','Group: sinhvien | Unblocked IPs: 172.19.0.1','172.19.0.1','2026-11-15 13:13:25','96325d640a6bc8ba5fe62f033737a7bd369af7338c1cf4ce1536e1f00048ab13','93a1088a2139f08743ed5d637e561d13bdcc06f5d35324430f75ed04ad762c5b'),
(380,'sv_binh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 13:13:25','93a1088a2139f08743ed5d637e561d13bdcc06f5d35324430f75ed04ad762c5b','da1fe60fb4b783f051fbc5f624949756a719d2dbec32306c0e1b42f0712c0239'),
(381,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 13:14:26','da1fe60fb4b783f051fbc5f624949756a719d2dbec32306c0e1b42f0712c0239','67f17ee584235ff17caa2e79c1405ed87a0fbdc8a350732e77fa21b6811ce981'),
(382,'admin','SSO_SINGLE_LOGOUT','ALL_CONNECTED_APPS','','Kích hoạt Single Logout (SLO). Thu hồi thành công 5 phiên ứng dụng vệ tinh.','172.19.0.1','2026-11-15 13:14:27','67f17ee584235ff17caa2e79c1405ed87a0fbdc8a350732e77fa21b6811ce981','665c80e4888c957f0e8824fcad26d430487854f34632ea638e61ad471ebdaa6f'),
(383,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 13:14:38','665c80e4888c957f0e8824fcad26d430487854f34632ea638e61ad471ebdaa6f','be887f8ddcc57b4131debb6b6ff5f4d2f58d36a83b4be65a04a065a692bc1779'),
(384,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 13:14:38','be887f8ddcc57b4131debb6b6ff5f4d2f58d36a83b4be65a04a065a692bc1779','5141e609a15b8756ebf65c56e740ce573cc30e6fe69cf9d8d0a57d5c1b2b0e47'),
(385,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 13:14:38','5141e609a15b8756ebf65c56e740ce573cc30e6fe69cf9d8d0a57d5c1b2b0e47','8279cd9e92df3728c625ada4d8c9e6d0049d0fa485461d1b5d2b060d9ae587d4'),
(386,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 13:14:38','8279cd9e92df3728c625ada4d8c9e6d0049d0fa485461d1b5d2b060d9ae587d4','b727c3d89172a52f51193739ea6370f46349be29ad81d3b991508614164bd618'),
(387,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 13:14:38','b727c3d89172a52f51193739ea6370f46349be29ad81d3b991508614164bd618','035a37005b20e4a0f6d4ff4729cdf8829f623c9ac32380cd94cd31e2cbda1d9f'),
(388,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 13:14:38','035a37005b20e4a0f6d4ff4729cdf8829f623c9ac32380cd94cd31e2cbda1d9f','99ce8d78136f2661d737a985f96393238aad564e0c253021b7c8437a5f8401eb'),
(389,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 13:14:38','99ce8d78136f2661d737a985f96393238aad564e0c253021b7c8437a5f8401eb','bb88947ad721ee8b9694fe614827487455d266a7644967f05d385fca83348261'),
(390,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 13:14:39','bb88947ad721ee8b9694fe614827487455d266a7644967f05d385fca83348261','6f46e3470fdd155eca602727c02627c1b2c9d80860a080351774a7e3ad877924'),
(391,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 13:14:39','6f46e3470fdd155eca602727c02627c1b2c9d80860a080351774a7e3ad877924','231d15f59737bb256f3df5f8f3f82380ea8b766fa2f45b221c0fe88312b34e77'),
(392,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 13:14:39','231d15f59737bb256f3df5f8f3f82380ea8b766fa2f45b221c0fe88312b34e77','f4352c0b67102fc14852dbd95740ba7019aec9f15b0780f111c0d20d3114e273'),
(393,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 13:14:39','f4352c0b67102fc14852dbd95740ba7019aec9f15b0780f111c0d20d3114e273','cf3424c1f052bbc3dc8e3b0b87de2d69519c1f2702b43af9c6910d6b73b670e8'),
(394,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 13:14:39','cf3424c1f052bbc3dc8e3b0b87de2d69519c1f2702b43af9c6910d6b73b670e8','87794dc84e27d10afc17089c06684ba7c0145006625d724b365c054d9beae946'),
(395,'sv_tuananh','SELF_REGISTER','OPENLDAP','NEW_USER_REGISTRATION','Group: sinhvien (VLAN 20), Name: Lê Tuấn Anh, Email: tuananh.le@ptit.edu.vn','172.19.0.1','2026-11-15 13:14:45','87794dc84e27d10afc17089c06684ba7c0145006625d724b365c054d9beae946','6dc7ef92badc36dbe845677d6712ff0918e9d472a76a87e172081c48df2cc852'),
(396,'sv_tuananh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 13:14:45','6dc7ef92badc36dbe845677d6712ff0918e9d472a76a87e172081c48df2cc852','2da6362a57bba48ccf5b70d690fafa5ada60387bd73b81a7382a17183d2d396f'),
(397,'gv_huong','SELF_REGISTER','OPENLDAP','NEW_USER_REGISTRATION','Group: giangvien (VLAN 30), Name: Trần Thu Hương, Email: huong.tt@ptit.edu.vn','172.19.0.1','2026-11-15 13:14:45','2da6362a57bba48ccf5b70d690fafa5ada60387bd73b81a7382a17183d2d396f','6bf197f26c4c344dda026d99a0f15042350270ca38f429891811c1704e0009fb'),
(398,'gv_huong','DASHBOARD_LOGIN','SYSTEM','','Login success as user (giangvien)','172.19.0.1','2026-11-15 13:14:46','6bf197f26c4c344dda026d99a0f15042350270ca38f429891811c1704e0009fb','08dce7895ad9f2e5b4f31360699c27d15d53ede9e07102f4d629b59389f3c62e'),
(399,'admin','DASHBOARD_LOGIN_FAILED','DASHBOARD','Lần sai thứ 1/5','Còn 4 lần thử trước khi bị khóa','172.19.0.1','2026-11-15 13:14:57','08dce7895ad9f2e5b4f31360699c27d15d53ede9e07102f4d629b59389f3c62e','2c9ea5a3b46a875c710b83fce3c8125298ebd495c95f7a79eddb67a989c12de3'),
(400,'admin','DASHBOARD_LOGIN_FAILED','DASHBOARD','Lần sai thứ 2/5','Còn 3 lần thử trước khi bị khóa','172.19.0.1','2026-11-15 13:14:57','2c9ea5a3b46a875c710b83fce3c8125298ebd495c95f7a79eddb67a989c12de3','cb3746dcc48a07795acbce65ca5cbe6fd30877af500cb2181b23640d2bdc43c6'),
(401,'admin','DASHBOARD_LOGIN_FAILED','DASHBOARD','Lần sai thứ 3/5','Còn 2 lần thử trước khi bị khóa','172.19.0.1','2026-11-15 13:14:57','cb3746dcc48a07795acbce65ca5cbe6fd30877af500cb2181b23640d2bdc43c6','1f4f323b740e0e9add9c927da943a2a56568454c5338a0ded6b0370f6b99bd4c'),
(402,'admin','DASHBOARD_LOGIN_FAILED','DASHBOARD','Lần sai thứ 4/5','Còn 1 lần thử trước khi bị khóa','172.19.0.1','2026-11-15 13:14:57','1f4f323b740e0e9add9c927da943a2a56568454c5338a0ded6b0370f6b99bd4c','131e7b22ee73380f3f310ac6ab2b5c25f7955dfcf43c8c7c50159c80d395c346'),
(403,'admin','DASHBOARD_ACCOUNT_LOCKED','DASHBOARD','Nhập sai 5 lần liên tiếp từ IP 172.19.0.1','Khóa tài khoản admin trong 60 phút','172.19.0.1','2026-11-15 13:14:57','131e7b22ee73380f3f310ac6ab2b5c25f7955dfcf43c8c7c50159c80d395c346','fb509c02fed40578f2166e266cdfbf302ec0c7d3a30c8bb507f34f95fa55d579'),
(404,'172.19.0.1','DASHBOARD_IP_BLOCKED','DASHBOARD','Thử dò tài khoản: admin','Chặn địa chỉ IP 172.19.0.1 trong 60 phút','172.19.0.1','2026-11-15 13:14:57','fb509c02fed40578f2166e266cdfbf302ec0c7d3a30c8bb507f34f95fa55d579','aee4b82bb20cfcd5e3b3ca359fa4c7a7badc04d2c57c39a740c839e5a5ba6472'),
(405,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 13:14:57','aee4b82bb20cfcd5e3b3ca359fa4c7a7badc04d2c57c39a740c839e5a5ba6472','edbfb4965ad5eaa58d489016f05b9f48462b38a00f662906af55406b4434fa7c'),
(406,'admin','MFA_LOGIN_SUCCESS','SYSTEM','','Xác thực MFA thành công qua mã TOTP 6 số cho admin (TimeStep: 59824950)','172.19.0.1','2026-11-15 13:15:08','edbfb4965ad5eaa58d489016f05b9f48462b38a00f662906af55406b4434fa7c','7fe963654049f09cab387a04f86f28b8567235869181e10a3aeeb654f30d91ff'),
(407,'admin','MFA_REPLAY_ATTEMPT','SYSTEM','Replayed OTP code: 896866','','172.19.0.1','2026-11-15 13:15:08','7fe963654049f09cab387a04f86f28b8567235869181e10a3aeeb654f30d91ff','9159a08164876281a60f1964b78a2520b181c38b30894d4a20502a8627abe6d3'),
(408,'admin','MFA_LOGIN_FAILED','SYSTEM','Invalid TOTP','Lần sai thứ 1/3. Còn 2 lần thử.','172.19.0.1','2026-11-15 13:15:08','9159a08164876281a60f1964b78a2520b181c38b30894d4a20502a8627abe6d3','c324edf24bc9dbe3a5e4ac31db56f72e64961278bfbe8d0412c5bde916f7ba4e'),
(409,'admin','MFA_LOGIN_FAILED','SYSTEM','Invalid TOTP','Lần sai thứ 2/3. Còn 1 lần thử.','172.19.0.1','2026-11-15 13:15:08','c324edf24bc9dbe3a5e4ac31db56f72e64961278bfbe8d0412c5bde916f7ba4e','0fcc828b8d6a207b3b60acef12ec05f7aca8198a5d47a426f7c6b98357cc12c4'),
(410,'admin','MFA_LOCKED','SYSTEM','Nhập sai 3 lần liên tiếp','Khóa MFA trong 10 phút','172.19.0.1','2026-11-15 13:15:08','0fcc828b8d6a207b3b60acef12ec05f7aca8198a5d47a426f7c6b98357cc12c4','0c8837cd50e9af1b5a160650b46204de4816750f31ca429264800a7ba13c632d'),
(411,'172.19.0.1','PASSWORD_RESET_REQUESTED','sv_an','','Tạo liên kết đổi mật khẩu gửi tới sv_an@ptit.edu.vn (Token TTL 15m)','172.19.0.1','2026-11-15 13:16:07','0c8837cd50e9af1b5a160650b46204de4816750f31ca429264800a7ba13c632d','ac5c18c0f325d3119d722bc4b9f96448105e146689b6aa18ecf6ee176881599a'),
(412,'sv_an','PASSWORD_RESET_SUCCESS','sv_an','','Đặt lại mật khẩu thành công qua email xác thực sv_an@ptit.edu.vn','172.19.0.1','2026-11-15 13:16:07','ac5c18c0f325d3119d722bc4b9f96448105e146689b6aa18ecf6ee176881599a','95f779d6719965f3802c5b1ab3fc5fa12216e45d2747f38cefa17d57313189a4'),
(413,'172.19.0.1','PASSWORD_RESET_REQUESTED','sv_an','','Tạo liên kết đổi mật khẩu gửi tới sv_an@ptit.edu.vn (Token TTL 15m)','172.19.0.1','2026-11-15 13:16:09','95f779d6719965f3802c5b1ab3fc5fa12216e45d2747f38cefa17d57313189a4','0aaa3a65221454f29668aa01ccd7de4b02a3ed6b739c9ca67cb735be5e512123'),
(414,'172.19.0.1','PASSWORD_RESET_REQUESTED','sv_an','','Tạo liên kết đổi mật khẩu gửi tới sv_an@ptit.edu.vn (Token TTL 15m)','172.19.0.1','2026-11-15 13:16:09','0aaa3a65221454f29668aa01ccd7de4b02a3ed6b739c9ca67cb735be5e512123','e91a47a28aa679441c7f4b86c3cda319f584e88a7cf710da098a3b21b5a2d8c6'),
(415,'sv_an','PASSWORD_RESET_SUCCESS','sv_an','','Đặt lại mật khẩu thành công qua email xác thực sv_an@ptit.edu.vn','172.19.0.1','2026-11-15 13:16:09','e91a47a28aa679441c7f4b86c3cda319f584e88a7cf710da098a3b21b5a2d8c6','1d24258e37c11458046a915dc9d280f41dc24850db60cc52998128422efa4480'),
(416,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 13:17:34','1d24258e37c11458046a915dc9d280f41dc24850db60cc52998128422efa4480','42bd4fe11486abe69ccc26540914cd6b1330bede307a23182dfdae75f5365ff5'),
(417,'meoluoi','SELF_REGISTER','OPENLDAP','NEW_USER_REGISTRATION','Group: sinhvien (VLAN 20), Name: Hong Meo Luoi, Email: hongmeoluoi2202@gmail.com','172.19.0.1','2026-11-15 13:18:36','42bd4fe11486abe69ccc26540914cd6b1330bede307a23182dfdae75f5365ff5','3ab746e323b572cc6536b3801211b68af4f563779c13a450bbe4ccba355b6cbd'),
(418,'meoluoi','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 13:19:13','3ab746e323b572cc6536b3801211b68af4f563779c13a450bbe4ccba355b6cbd','65fd6545e53b5fb6bda468f1168a2a695945fb2d9a020819b17291298d5efec1'),
(419,'172.19.0.1','PASSWORD_RESET_REQUESTED','meoluoi','','Tạo liên kết đổi mật khẩu gửi tới hongmeoluoi2202@gmail.com (Token TTL 15m)','172.19.0.1','2026-11-15 13:19:50','65fd6545e53b5fb6bda468f1168a2a695945fb2d9a020819b17291298d5efec1','c0bef8cc6523c7359ee8f342c4fb04f8f67d75b656d7fae2a05b610e64afcefb'),
(420,'172.19.0.1','PASSWORD_RESET_REQUESTED','sv_an','','Tạo liên kết đổi mật khẩu gửi tới sv_an@ptit.edu.vn (Real SMTP: False, TTL: 15m)','172.19.0.1','2026-11-15 13:28:31','c0bef8cc6523c7359ee8f342c4fb04f8f67d75b656d7fae2a05b610e64afcefb','b30ea1ebc89949497040ff14f74829ca98c8b8e509f8ac20bc5af0b44e8004ad'),
(421,'sv_an','PASSWORD_RESET_SUCCESS','sv_an','','Đặt lại mật khẩu thành công qua email xác thực sv_an@ptit.edu.vn','172.19.0.1','2026-11-15 13:28:32','b30ea1ebc89949497040ff14f74829ca98c8b8e509f8ac20bc5af0b44e8004ad','0ff94fc51a30db44fa4eef9e2a94bc5da837db7f7d8699d9f941cc918e007e39'),
(422,'172.19.0.1','PASSWORD_RESET_REQUESTED','sv_an','','Tạo liên kết đổi mật khẩu gửi tới sv_an@ptit.edu.vn (Real SMTP: False, TTL: 15m)','172.19.0.1','2026-11-15 13:28:33','0ff94fc51a30db44fa4eef9e2a94bc5da837db7f7d8699d9f941cc918e007e39','b09b19a905a5a2d633504a1121fb0dcb3c8dadba07c713fed57895b00b21b250'),
(423,'172.19.0.1','PASSWORD_RESET_REQUESTED','sv_an','','Tạo liên kết đổi mật khẩu gửi tới sv_an@ptit.edu.vn (Real SMTP: False, TTL: 15m)','172.19.0.1','2026-11-15 13:28:33','b09b19a905a5a2d633504a1121fb0dcb3c8dadba07c713fed57895b00b21b250','0fbb10c6308133dc7a6dacf2a959c3f52c4c885c06d93e9ed471533533e49f33'),
(424,'sv_an','PASSWORD_RESET_SUCCESS','sv_an','','Đặt lại mật khẩu thành công qua email xác thực sv_an@ptit.edu.vn','172.19.0.1','2026-11-15 13:28:33','0fbb10c6308133dc7a6dacf2a959c3f52c4c885c06d93e9ed471533533e49f33','9997b5ceb0a3edf5e35065dd7e71a7a5cb7bf23e7d08dcb3b358ca48a0dc65d0'),
(425,'172.19.0.1','PASSWORD_RESET_REQUESTED','meoluoi','','Tạo liên kết đổi mật khẩu gửi tới hongmeoluoi2202@gmail.com (Real SMTP: False, TTL: 15m)','172.19.0.1','2026-11-15 13:30:05','9997b5ceb0a3edf5e35065dd7e71a7a5cb7bf23e7d08dcb3b358ca48a0dc65d0','eb735c2b84e039b7040a09cf847afa7559d12610ec9a4b9e8d966c95fa60cd8d'),
(426,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 13:31:38','eb735c2b84e039b7040a09cf847afa7559d12610ec9a4b9e8d966c95fa60cd8d','b2915f8b2e4171457df99a349b534637b6de136672d346a38ed34c9720727781'),
(427,'meoluoi','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 13:32:47','b2915f8b2e4171457df99a349b534637b6de136672d346a38ed34c9720727781','20fe9a0225254133c4c13845725cd74cf542007361971e5b47ab86931139ef2b'),
(428,'admin','MANUAL_QUARANTINE','meoluoi','Group: sinhvien','Group: quarantine (VLAN 99) | Blocked IPs: 172.19.0.1 | Revoked SSO: 2','172.19.0.1','2026-11-15 13:40:15','20fe9a0225254133c4c13845725cd74cf542007361971e5b47ab86931139ef2b','55aebaa8394f8a3f472f8551e06cb4a9d3c3e87c3c3e3ad8e835905d6fcb1b7b'),
(429,'admin','UNLOCK_USER','meoluoi','Group: quarantine','Group: sinhvien | Unblocked IPs: 172.19.0.1','172.19.0.1','2026-11-15 13:40:37','55aebaa8394f8a3f472f8551e06cb4a9d3c3e87c3c3e3ad8e835905d6fcb1b7b','d5e125f5eb8ec73f29a8d5e667a5475ebce1a7bd598bebd6cbf9a0d97ed9b78f'),
(430,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 13:42:07','d5e125f5eb8ec73f29a8d5e667a5475ebce1a7bd598bebd6cbf9a0d97ed9b78f','ccbf76831a68b343117e4edf62fc895e256cb58c766bddc63bb25bf01813375d'),
(431,'admin','SSO_SINGLE_LOGOUT','ALL_CONNECTED_APPS','','Kích hoạt Single Logout (SLO). Thu hồi thành công 5 phiên ứng dụng vệ tinh.','172.19.0.1','2026-11-15 13:42:08','ccbf76831a68b343117e4edf62fc895e256cb58c766bddc63bb25bf01813375d','6874b7462586ffcba72baa0aa79cd09a6a82b83c975017a53ed9937c3a038fc9'),
(432,'sv_vinh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 13:42:31','6874b7462586ffcba72baa0aa79cd09a6a82b83c975017a53ed9937c3a038fc9','ae6f713478239ddeefbfce653c12efc93663cf666384876faa58edfb982362c4'),
(433,'gv_nguyen','DASHBOARD_LOGIN','SYSTEM','','Login success as user (giangvien)','172.19.0.1','2026-11-15 13:42:32','ae6f713478239ddeefbfce653c12efc93663cf666384876faa58edfb982362c4','48a0ad8ba13ed75d0fca420fd9e2f178b292fa5cfc50fc76f8ac5a3599da1578'),
(434,'sv_vinh','SSO_SINGLE_LOGOUT','ALL_CONNECTED_APPS','','Kích hoạt Single Logout (SLO). Thu hồi thành công 4 phiên ứng dụng vệ tinh.','172.19.0.1','2026-11-15 13:42:32','48a0ad8ba13ed75d0fca420fd9e2f178b292fa5cfc50fc76f8ac5a3599da1578','424923df7aa601fb79b368f4a680970770a58d30db12033b69e9c2d63833bea6'),
(435,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 13:42:32','424923df7aa601fb79b368f4a680970770a58d30db12033b69e9c2d63833bea6','1bbb31ba4f98e3585cd7d9bc2d0870bb96269818e6e404e8f5d6240c87ba7b38'),
(436,'172.19.0.1','PASSWORD_RESET_REQUESTED','sv_an','','Tạo liên kết đổi mật khẩu gửi tới sv_an@ptit.edu.vn (Real SMTP: False, TTL: 15m)','172.19.0.1','2026-11-15 13:42:52','1bbb31ba4f98e3585cd7d9bc2d0870bb96269818e6e404e8f5d6240c87ba7b38','8049579ea48fff1407c421b0fbd29c5bec46207a35970de2871ead8871baf332'),
(437,'sv_an','PASSWORD_RESET_SUCCESS','sv_an','','Đặt lại mật khẩu thành công qua email xác thực sv_an@ptit.edu.vn','172.19.0.1','2026-11-15 13:42:52','8049579ea48fff1407c421b0fbd29c5bec46207a35970de2871ead8871baf332','f11b03063914376b35e0925df5a151e81685a7c35ca7e220f9f7fca546b1c942'),
(438,'172.19.0.1','PASSWORD_RESET_REQUESTED','sv_an','','Tạo liên kết đổi mật khẩu gửi tới sv_an@ptit.edu.vn (Real SMTP: False, TTL: 15m)','172.19.0.1','2026-11-15 13:42:53','f11b03063914376b35e0925df5a151e81685a7c35ca7e220f9f7fca546b1c942','c054787985cd6ed50cdda4a382fa793cee6113e6a16bb8d7650bc29d36315ab8'),
(439,'172.19.0.1','PASSWORD_RESET_REQUESTED','sv_an','','Tạo liên kết đổi mật khẩu gửi tới sv_an@ptit.edu.vn (Real SMTP: False, TTL: 15m)','172.19.0.1','2026-11-15 13:42:53','c054787985cd6ed50cdda4a382fa793cee6113e6a16bb8d7650bc29d36315ab8','c1943cb1964608f6b0143afd5b655db1c8b53d90a0b573e802a496f9b7f7cdd2'),
(440,'sv_an','PASSWORD_RESET_SUCCESS','sv_an','','Đặt lại mật khẩu thành công qua email xác thực sv_an@ptit.edu.vn','172.19.0.1','2026-11-15 13:42:53','c1943cb1964608f6b0143afd5b655db1c8b53d90a0b573e802a496f9b7f7cdd2','5a74258006d6f0c92cb374373235222c0ad2a0e7eaa22011ece72e4746695ab1'),
(441,'meoluoi','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 13:44:23','5a74258006d6f0c92cb374373235222c0ad2a0e7eaa22011ece72e4746695ab1','d99a14c6eaa1d43a9d21bb4246b76d2fd5885b785069a66c8e8ad8e517517ab3'),
(442,'meoluoi','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 13:44:48','d99a14c6eaa1d43a9d21bb4246b76d2fd5885b785069a66c8e8ad8e517517ab3','ffbe2d65a7be7c89e53555d487604981cf03d0d105c217db0a59bba60e79a9aa'),
(443,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 14:23:44','ffbe2d65a7be7c89e53555d487604981cf03d0d105c217db0a59bba60e79a9aa','80a8675d1996b82800a44d90fbd56e75638313f6ae02898e6001106875ae2d55'),
(444,'admin','DASHBOARD_LOGOUT','SYSTEM','','Đăng xuất và kích hoạt SLO. Thu hồi 1 phiên ứng dụng.','172.19.0.1','2026-11-15 14:23:45','80a8675d1996b82800a44d90fbd56e75638313f6ae02898e6001106875ae2d55','f1353c2303085f50edeb1bb26653d853c08dd75e1178f61a19cde81179fd3e51'),
(445,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 14:24:40','f1353c2303085f50edeb1bb26653d853c08dd75e1178f61a19cde81179fd3e51','baff60e471f13c42ccb3890a7358bb13a550e6910fe2641eefe21cac716b3781'),
(446,'admin','DASHBOARD_LOGOUT','SYSTEM','','Đăng xuất và kích hoạt SLO. Thu hồi 1 phiên ứng dụng.','172.19.0.1','2026-11-15 14:24:41','baff60e471f13c42ccb3890a7358bb13a550e6910fe2641eefe21cac716b3781','95684fbbd3e352d51306ab7c8600c3b95b76278434a33e4cd264acd636457e88'),
(447,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 14:24:55','95684fbbd3e352d51306ab7c8600c3b95b76278434a33e4cd264acd636457e88','e79cf34ce09ab2d75d8250b988209536de6615c153031fdab27259ed8d7ef4ce'),
(448,'sv_vinh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 14:25:29','e79cf34ce09ab2d75d8250b988209536de6615c153031fdab27259ed8d7ef4ce','3c951f0f93ac20d8072d73a3c390bd757673715aa4ac3576a6f0647ac66d66de'),
(449,'gv_nguyen','DASHBOARD_LOGIN','SYSTEM','','Login success as user (giangvien)','172.19.0.1','2026-11-15 14:25:30','3c951f0f93ac20d8072d73a3c390bd757673715aa4ac3576a6f0647ac66d66de','c39b108a0c0edec1fd552729b4f1952bdff1fab2c4aca365663cd2213a5c6429'),
(450,'sv_vinh','SSO_SINGLE_LOGOUT','ALL_CONNECTED_APPS','','Kích hoạt Single Logout (SLO). Thu hồi thành công 4 phiên ứng dụng vệ tinh.','172.19.0.1','2026-11-15 14:25:30','c39b108a0c0edec1fd552729b4f1952bdff1fab2c4aca365663cd2213a5c6429','2b6ede918e24c02ba27a720f7bf6350c3f26131db8251703c48b557e57d760f7'),
(451,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 14:25:30','2b6ede918e24c02ba27a720f7bf6350c3f26131db8251703c48b557e57d760f7','89605794ab2614a71164a08ddfe2652fb45f2a21436379439e25e081fabcb3aa'),
(452,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 14:25:38','89605794ab2614a71164a08ddfe2652fb45f2a21436379439e25e081fabcb3aa','8c47e60a0591b733d1283b0651d2d358c7f0a4070c16586a9444b28124fa526b'),
(453,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 14:26:21','8c47e60a0591b733d1283b0651d2d358c7f0a4070c16586a9444b28124fa526b','fa9ddda9d52f6b3ac311103de12d491fe4441d46ee16b819ee51e8e3abac7418'),
(454,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 14:26:48','fa9ddda9d52f6b3ac311103de12d491fe4441d46ee16b819ee51e8e3abac7418','700952840a19718e782ae38c95d7bc66ad4e09d83067d9f832e7f2bacdefa610'),
(455,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 14:27:54','700952840a19718e782ae38c95d7bc66ad4e09d83067d9f832e7f2bacdefa610','4cc366774b76d88334796925414dcdf4121ddd9ac790efa243c4a1e97b2b09f9'),
(456,'admin','SSO_SINGLE_LOGOUT','ALL_CONNECTED_APPS','','Kích hoạt Single Logout (SLO). Thu hồi thành công 5 phiên ứng dụng vệ tinh.','172.19.0.1','2026-11-15 14:27:55','4cc366774b76d88334796925414dcdf4121ddd9ac790efa243c4a1e97b2b09f9','56ed10dd0aadd1cbb83d2389e8af1f81b035192306b72f4b2a7a3c4d783ab60c'),
(457,'172.19.0.1','PASSWORD_RESET_REQUESTED','sv_an','','Tạo liên kết đổi mật khẩu gửi tới sv_an@ptit.edu.vn (Real SMTP: False, TTL: 15m)','172.19.0.1','2026-11-15 14:28:03','56ed10dd0aadd1cbb83d2389e8af1f81b035192306b72f4b2a7a3c4d783ab60c','c754ebe47808bac2a22b62bdd980e5cc6c98477f8f973b41cb54cae9f51dbae1'),
(458,'sv_an','PASSWORD_RESET_SUCCESS','sv_an','','Đặt lại mật khẩu thành công qua email xác thực sv_an@ptit.edu.vn','172.19.0.1','2026-11-15 14:28:03','c754ebe47808bac2a22b62bdd980e5cc6c98477f8f973b41cb54cae9f51dbae1','91c4f16b5f1956dadfd7620f96b46e832711de7e689f4bfc95b02963a6b508e8'),
(459,'172.19.0.1','PASSWORD_RESET_REQUESTED','sv_an','','Tạo liên kết đổi mật khẩu gửi tới sv_an@ptit.edu.vn (Real SMTP: False, TTL: 15m)','172.19.0.1','2026-11-15 14:28:04','91c4f16b5f1956dadfd7620f96b46e832711de7e689f4bfc95b02963a6b508e8','9a618ce9d4d3384494eefe7e5dfac621ba3799422ce2b74fce3b3572bc073b47'),
(460,'172.19.0.1','PASSWORD_RESET_REQUESTED','sv_an','','Tạo liên kết đổi mật khẩu gửi tới sv_an@ptit.edu.vn (Real SMTP: False, TTL: 15m)','172.19.0.1','2026-11-15 14:28:04','9a618ce9d4d3384494eefe7e5dfac621ba3799422ce2b74fce3b3572bc073b47','98ab29500a9e6cb38f8d4402db3d605b1aad4f63c6871815f7cf2fc3b73f6485'),
(461,'sv_an','PASSWORD_RESET_SUCCESS','sv_an','','Đặt lại mật khẩu thành công qua email xác thực sv_an@ptit.edu.vn','172.19.0.1','2026-11-15 14:28:04','98ab29500a9e6cb38f8d4402db3d605b1aad4f63c6871815f7cf2fc3b73f6485','b842268807f177b8364b37876293e9a7339fc4045336d7d8ca79c96103059578'),
(462,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 14:28:13','b842268807f177b8364b37876293e9a7339fc4045336d7d8ca79c96103059578','0e1ef39d5c921df6df24aa0a67dc5a3e95e73d3dfc72b6cb25134d046e5bb31f'),
(463,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 14:28:13','0e1ef39d5c921df6df24aa0a67dc5a3e95e73d3dfc72b6cb25134d046e5bb31f','469a4cade69b06646f73690ed4366b9e2e4eb75407520ba62d99ed3bff200d9a'),
(464,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 14:28:13','469a4cade69b06646f73690ed4366b9e2e4eb75407520ba62d99ed3bff200d9a','a7c6ebf2d9c4c91eddf84ecc3183bd73a9a48bd04cba02e19b8fd18b7de9162c'),
(465,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 14:28:13','a7c6ebf2d9c4c91eddf84ecc3183bd73a9a48bd04cba02e19b8fd18b7de9162c','f5bf4e385f14794f06bff1d0118f03f660324f0b9bc559268ea660d1a5249703'),
(466,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 14:28:13','f5bf4e385f14794f06bff1d0118f03f660324f0b9bc559268ea660d1a5249703','4d948efbcd3a2b101c6125fa9eb0f8221300077827d45180855566601e078cbe'),
(467,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 14:28:13','4d948efbcd3a2b101c6125fa9eb0f8221300077827d45180855566601e078cbe','3dbd9b3f038ec762eab146c336f75b5623b277bc3a24f04397e22fda32cad2b2'),
(468,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 14:28:13','3dbd9b3f038ec762eab146c336f75b5623b277bc3a24f04397e22fda32cad2b2','5e9e7e00e0f4279df203100da951413306e633189fb6597b8fd84df6a0f341e9'),
(469,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 14:28:13','5e9e7e00e0f4279df203100da951413306e633189fb6597b8fd84df6a0f341e9','d18c42e897a9f2529bb5ed9412a2e2ff499b0cd72d03174cb38b1d12f18f6b01'),
(470,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 14:28:13','d18c42e897a9f2529bb5ed9412a2e2ff499b0cd72d03174cb38b1d12f18f6b01','06cfbfbb28437002fd9ae4eb69d06e11bc605e113dee9feb7feaaba889b499f4'),
(471,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 14:28:13','06cfbfbb28437002fd9ae4eb69d06e11bc605e113dee9feb7feaaba889b499f4','6623f579edcf5460137845eb5f3911902419eb8e8aa12c19a39e16c245d0b009'),
(472,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 14:28:14','6623f579edcf5460137845eb5f3911902419eb8e8aa12c19a39e16c245d0b009','4caa095965cf8da41a176580f3261ea6393f5fd79308367766915e65dd9d5262'),
(473,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-15 14:28:14','4caa095965cf8da41a176580f3261ea6393f5fd79308367766915e65dd9d5262','e8ffe4505c05ec86f9a70db6164697113b273fe961136a0855bee21bd43dd702'),
(474,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 14:28:22','e8ffe4505c05ec86f9a70db6164697113b273fe961136a0855bee21bd43dd702','3f273b1c0fb5884fd29a808d623f45709c00cc53ee324ab2c321607b3451e5ba'),
(475,'admin','UNLOCK_USER','sv_binh','Group: quarantine','Group: sinhvien | Unblocked IPs: Không có','172.19.0.1','2026-11-15 14:28:23','3f273b1c0fb5884fd29a808d623f45709c00cc53ee324ab2c321607b3451e5ba','9fe7915d043a2d995ebb71d867412dc092d242462e75d44a7d88424b151351bf'),
(476,'sv_binh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 14:28:23','9fe7915d043a2d995ebb71d867412dc092d242462e75d44a7d88424b151351bf','ceeb6f0fd8d2a901fa78a31e17d394d9a4ec468753f237b8b2e0617a4cce59cb'),
(477,'admin','MANUAL_QUARANTINE','sv_binh','Group: sinhvien','Group: quarantine (VLAN 99) | Blocked IPs: 172.19.0.1 | Revoked SSO: 2','172.19.0.1','2026-11-15 14:28:23','ceeb6f0fd8d2a901fa78a31e17d394d9a4ec468753f237b8b2e0617a4cce59cb','ff9f25dc056f050713bd3fb1181cc8153fb7d067f759e600dc78c6cf4b4e4d07'),
(478,'admin','UNLOCK_USER','sv_binh','Group: quarantine','Group: sinhvien | Unblocked IPs: 172.19.0.1','172.19.0.1','2026-11-15 14:28:23','ff9f25dc056f050713bd3fb1181cc8153fb7d067f759e600dc78c6cf4b4e4d07','8468c714ac2cc0dfb01134ca0fa84e0c0fadb5444d858224061142d105073a82'),
(479,'sv_binh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 14:28:24','8468c714ac2cc0dfb01134ca0fa84e0c0fadb5444d858224061142d105073a82','7a882e00a287d9f485e9953a0b574ea005e0b7555799d888c6a0f198ba6e8113'),
(480,'sv_tuananh','SELF_REGISTER','OPENLDAP','NEW_USER_REGISTRATION','Group: sinhvien (VLAN 20), Name: Lê Tuấn Anh, Email: tuananh.le@ptit.edu.vn','172.19.0.1','2026-11-15 14:28:33','7a882e00a287d9f485e9953a0b574ea005e0b7555799d888c6a0f198ba6e8113','5aed067d26f87c55674662cdce06c56dea7c83e7bcd85f4363b4e3e12f723d92'),
(481,'sv_tuananh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-15 14:28:34','5aed067d26f87c55674662cdce06c56dea7c83e7bcd85f4363b4e3e12f723d92','fd3dbfa0fbeb659f4fcea306b7293443c76d088c202df9028bccb0053a9b1791'),
(482,'gv_huong','SELF_REGISTER','OPENLDAP','NEW_USER_REGISTRATION','Group: giangvien (VLAN 30), Name: Trần Thu Hương, Email: huong.tt@ptit.edu.vn','172.19.0.1','2026-11-15 14:28:34','fd3dbfa0fbeb659f4fcea306b7293443c76d088c202df9028bccb0053a9b1791','f2e7c532048590eb08209b9d247be91ff921070f45490b0b8db3d73d027f50da'),
(483,'gv_huong','DASHBOARD_LOGIN','SYSTEM','','Login success as user (giangvien)','172.19.0.1','2026-11-15 14:28:34','f2e7c532048590eb08209b9d247be91ff921070f45490b0b8db3d73d027f50da','33e1f85025c08ceaacd8e9178fd0de4215d3b2671cfd5c05b6ff8acf00f1ef76'),
(484,'admin','DASHBOARD_LOGIN_FAILED','DASHBOARD','Lần sai thứ 1/5','Còn 4 lần thử trước khi bị khóa','172.19.0.1','2026-11-15 14:29:25','33e1f85025c08ceaacd8e9178fd0de4215d3b2671cfd5c05b6ff8acf00f1ef76','54a7e20475ae3bb899c240b316cddef51c0704f1faaf5769d3e388b57e730a3c'),
(485,'admin','DASHBOARD_LOGIN_FAILED','DASHBOARD','Lần sai thứ 2/5','Còn 3 lần thử trước khi bị khóa','172.19.0.1','2026-11-15 14:29:26','54a7e20475ae3bb899c240b316cddef51c0704f1faaf5769d3e388b57e730a3c','aed3ce3b04fc4bdeec0f8da4ee2f4eeddd5c2f5787a46e03c1e57f47e638d39b'),
(486,'admin','DASHBOARD_LOGIN_FAILED','DASHBOARD','Lần sai thứ 3/5','Còn 2 lần thử trước khi bị khóa','172.19.0.1','2026-11-15 14:29:26','aed3ce3b04fc4bdeec0f8da4ee2f4eeddd5c2f5787a46e03c1e57f47e638d39b','cebd7769c6038cb8afeaec91ba90b4b87a1c327226e15bcf6ff8373470be8895'),
(487,'admin','DASHBOARD_LOGIN_FAILED','DASHBOARD','Lần sai thứ 4/5','Còn 1 lần thử trước khi bị khóa','172.19.0.1','2026-11-15 14:29:26','cebd7769c6038cb8afeaec91ba90b4b87a1c327226e15bcf6ff8373470be8895','986b3c436a97077032b3028d551978b73782492e817d96f768bd6ca907791ff0'),
(488,'admin','DASHBOARD_ACCOUNT_LOCKED','DASHBOARD','Nhập sai 5 lần liên tiếp từ IP 172.19.0.1','Khóa tài khoản admin trong 60 phút','172.19.0.1','2026-11-15 14:29:26','986b3c436a97077032b3028d551978b73782492e817d96f768bd6ca907791ff0','9f09557bfd7d2fb201a6abcf16d89bb3d81ce6c3e685631d8eb086f2318e7028'),
(489,'172.19.0.1','DASHBOARD_IP_BLOCKED','DASHBOARD','Thử dò tài khoản: admin','Chặn địa chỉ IP 172.19.0.1 trong 60 phút','172.19.0.1','2026-11-15 14:29:26','9f09557bfd7d2fb201a6abcf16d89bb3d81ce6c3e685631d8eb086f2318e7028','cf54548505369529290f0c523ab99b7b06e8bf8d2fc96cf7f08803858f7f4c05'),
(490,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-15 14:29:26','cf54548505369529290f0c523ab99b7b06e8bf8d2fc96cf7f08803858f7f4c05','ce08c9880e8231713675ab02a580abff85aa06a918d53302bc8c6b2a2dcb731b'),
(491,'admin','MFA_LOGIN_SUCCESS','SYSTEM','','Xác thực MFA thành công qua mã TOTP 6 số cho admin (TimeStep: 59825099)','172.19.0.1','2026-11-15 14:29:55','ce08c9880e8231713675ab02a580abff85aa06a918d53302bc8c6b2a2dcb731b','b0bc5a5f3726d7a9b86bf38342539c99abbd8a6c53e66faf2135367e1db6ba32'),
(492,'admin','MFA_REPLAY_ATTEMPT','SYSTEM','Replayed OTP code: 992419','','172.19.0.1','2026-11-15 14:29:55','b0bc5a5f3726d7a9b86bf38342539c99abbd8a6c53e66faf2135367e1db6ba32','04eca309bf9e457847d6fed61ebdf3a4fe2c8e76343225633941f5596aa92ea0'),
(493,'admin','MFA_LOGIN_FAILED','SYSTEM','Invalid TOTP','Lần sai thứ 1/3. Còn 2 lần thử.','172.19.0.1','2026-11-15 14:29:55','04eca309bf9e457847d6fed61ebdf3a4fe2c8e76343225633941f5596aa92ea0','acc7fb3de311771f438609493284efb786d4e77ce52d9ec9c7a0c14077fb1803'),
(494,'admin','MFA_LOGIN_FAILED','SYSTEM','Invalid TOTP','Lần sai thứ 2/3. Còn 1 lần thử.','172.19.0.1','2026-11-15 14:29:56','acc7fb3de311771f438609493284efb786d4e77ce52d9ec9c7a0c14077fb1803','31ed85d3ae0b6714399df3c3cfb0f3ce92e5c0e52aa795bcfa54d091b284358b'),
(495,'admin','MFA_LOCKED','SYSTEM','Nhập sai 3 lần liên tiếp','Khóa MFA trong 10 phút','172.19.0.1','2026-11-15 14:29:56','31ed85d3ae0b6714399df3c3cfb0f3ce92e5c0e52aa795bcfa54d091b284358b','c5e05de1770c43b654ad6bc2e49ba1f5fd4d063eda5c79260e4163dbf600bd1e'),
(496,'sv_vinh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-16 06:38:08','c5e05de1770c43b654ad6bc2e49ba1f5fd4d063eda5c79260e4163dbf600bd1e','ec44f1c70786e556ca5d772477930638773da7404c74a344fe6899746e930f9e'),
(497,'gv_nguyen','DASHBOARD_LOGIN','SYSTEM','','Login success as user (giangvien)','172.19.0.1','2026-11-16 06:38:09','ec44f1c70786e556ca5d772477930638773da7404c74a344fe6899746e930f9e','bfeba3efa8a11974aba8afd68c49c7d2c1e0b480fcb410097bf6e59bd894dfc9'),
(498,'sv_vinh','SSO_SINGLE_LOGOUT','ALL_CONNECTED_APPS','','Kích hoạt Single Logout (SLO). Thu hồi thành công 4 phiên ứng dụng vệ tinh.','172.19.0.1','2026-11-16 06:38:10','bfeba3efa8a11974aba8afd68c49c7d2c1e0b480fcb410097bf6e59bd894dfc9','4e7099ce65e75b108ae79dae90489869587f3ae2521945d8c8c0a1cfe7bfd9f9'),
(499,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-16 06:38:10','4e7099ce65e75b108ae79dae90489869587f3ae2521945d8c8c0a1cfe7bfd9f9','256f47611559c53314e6790668ecb6112fd58a6e010f724388abddb8ce246fad'),
(500,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-16 06:38:39','256f47611559c53314e6790668ecb6112fd58a6e010f724388abddb8ce246fad','322e8dc1f3a534bda864f30eaba83375c36f1997e058fde118c680eafd7604ab'),
(501,'admin','SSO_SINGLE_LOGOUT','ALL_CONNECTED_APPS','','Kích hoạt Single Logout (SLO). Thu hồi thành công 5 phiên ứng dụng vệ tinh.','172.19.0.1','2026-11-16 06:38:40','322e8dc1f3a534bda864f30eaba83375c36f1997e058fde118c680eafd7604ab','39f6ea0776b4291eebc6bd593c164675308d835321715fe2aa8bd5f8e3969c4e'),
(502,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-16 06:39:02','39f6ea0776b4291eebc6bd593c164675308d835321715fe2aa8bd5f8e3969c4e','54037227161cf6837664a8e003a4f303e860397391cf9413d9949952dcb3fc9d'),
(503,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-16 06:39:02','54037227161cf6837664a8e003a4f303e860397391cf9413d9949952dcb3fc9d','032a812c06a06f659144e38c47517085e54fd9e99c755ee5114ebcbc3264b098'),
(504,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-16 06:39:02','032a812c06a06f659144e38c47517085e54fd9e99c755ee5114ebcbc3264b098','1478685c28dcb1471c6041a4e1a22067a8779db7a29d246677e276a8138c19f0'),
(505,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-16 06:39:02','1478685c28dcb1471c6041a4e1a22067a8779db7a29d246677e276a8138c19f0','f055750242a176a4b40883af5c8f4185ed66a40d4a38b8a63ce3f0e92fb5d036'),
(506,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-16 06:39:02','f055750242a176a4b40883af5c8f4185ed66a40d4a38b8a63ce3f0e92fb5d036','dac4a61c8452c823284bdf73ac8289d21c6172274274a2a6c19c0f4dfdf24883'),
(507,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-16 06:39:02','dac4a61c8452c823284bdf73ac8289d21c6172274274a2a6c19c0f4dfdf24883','b3cbf891714ff04c1d0826d59f7e20fc0615d2fac8e1cf384b1affa02a45ce76'),
(508,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-16 06:39:03','b3cbf891714ff04c1d0826d59f7e20fc0615d2fac8e1cf384b1affa02a45ce76','752cb5a955bfe3dbec3996eda841aa21772b5bcc528bb2c6c65c3782c0a45f41'),
(509,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-16 06:39:03','752cb5a955bfe3dbec3996eda841aa21772b5bcc528bb2c6c65c3782c0a45f41','a736272187c221fda6d34593390e107ab0b10cc884a4235254000ecc423410b9'),
(510,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-16 06:39:03','a736272187c221fda6d34593390e107ab0b10cc884a4235254000ecc423410b9','b800a748e00c7ec45f7cbfeae0599f88722f599c6b2af25659ea57941ef7147f'),
(511,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-16 06:39:03','b800a748e00c7ec45f7cbfeae0599f88722f599c6b2af25659ea57941ef7147f','9c6976494194d0fd9cae41c8d1e15af2ddcff5ab900650483417791f6940a01f'),
(512,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-16 06:39:03','9c6976494194d0fd9cae41c8d1e15af2ddcff5ab900650483417791f6940a01f','59d4e79c6ff02c65110662364b457f97d89ac303df73081452de8c5fe73cd8c5'),
(513,'admin','SSO_AUTHORIZE_SUCCESS','qldt_lms','','Single Sign-On access granted for client: Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','172.19.0.1','2026-11-16 06:39:03','59d4e79c6ff02c65110662364b457f97d89ac303df73081452de8c5fe73cd8c5','54d9f12f050faf552518e4705028eaad7754b0b73d3e5b14c455cf39bf1b1f31'),
(514,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-16 06:39:38','54d9f12f050faf552518e4705028eaad7754b0b73d3e5b14c455cf39bf1b1f31','c4f639a25296f229ee79154560646366c8ce80feffd25cdc35f340dc13352597'),
(515,'admin','UNLOCK_USER','sv_binh','Group: quarantine','Group: sinhvien | Unblocked IPs: Không có','172.19.0.1','2026-11-16 06:39:38','c4f639a25296f229ee79154560646366c8ce80feffd25cdc35f340dc13352597','897305fa7beca6ba015e5238b1c4dd6864dece16a73ee7ca3ca9b29e473b59f8'),
(516,'sv_binh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-16 06:39:38','897305fa7beca6ba015e5238b1c4dd6864dece16a73ee7ca3ca9b29e473b59f8','be2795ae931829d2e896f18ef5b4a8db573eb91451f54e26baafb709706164c5'),
(517,'admin','MANUAL_QUARANTINE','sv_binh','Group: sinhvien','Group: quarantine (VLAN 99) | Blocked IPs: 172.19.0.1 | Revoked SSO: 2','172.19.0.1','2026-11-16 06:39:39','be2795ae931829d2e896f18ef5b4a8db573eb91451f54e26baafb709706164c5','2267b42f9aba9476d8398fc2d9329593d486c29a4f0b30af58425b2e0682d7f3'),
(518,'admin','UNLOCK_USER','sv_binh','Group: quarantine','Group: sinhvien | Unblocked IPs: 172.19.0.1','172.19.0.1','2026-11-16 06:39:39','2267b42f9aba9476d8398fc2d9329593d486c29a4f0b30af58425b2e0682d7f3','44579198f6848f7f3526bd73563e21a3b3ae0291cc6d69b7ad6f0967e943dc47'),
(519,'sv_binh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-16 06:39:39','44579198f6848f7f3526bd73563e21a3b3ae0291cc6d69b7ad6f0967e943dc47','c5c9f2992b21625f76683bf663b6dff45dc5db1b2f548da9ebf5386fadbae013'),
(520,'sv_tuananh','SELF_REGISTER','OPENLDAP','NEW_USER_REGISTRATION','Group: sinhvien (VLAN 20), Name: Lê Tuấn Anh, Email: tuananh.le@ptit.edu.vn','172.19.0.1','2026-11-16 06:39:56','c5c9f2992b21625f76683bf663b6dff45dc5db1b2f548da9ebf5386fadbae013','f163b832d4a57e42ba2702a7b5fc1409479ab7677723b6932e8f60015041f865'),
(521,'sv_tuananh','DASHBOARD_LOGIN','SYSTEM','','Login success as user (sinhvien)','172.19.0.1','2026-11-16 06:39:56','f163b832d4a57e42ba2702a7b5fc1409479ab7677723b6932e8f60015041f865','27dfbd48305972ec4bb831a90ccb894797be5bef5aeb9599c37c3e4a73f0fdcf'),
(522,'gv_huong','SELF_REGISTER','OPENLDAP','NEW_USER_REGISTRATION','Group: giangvien (VLAN 30), Name: Trần Thu Hương, Email: huong.tt@ptit.edu.vn','172.19.0.1','2026-11-16 06:39:56','27dfbd48305972ec4bb831a90ccb894797be5bef5aeb9599c37c3e4a73f0fdcf','9072ca415a294eec43774ab8046eab4eeada7188b6aa1e372bdf6c6ae5c2d18f'),
(523,'gv_huong','DASHBOARD_LOGIN','SYSTEM','','Login success as user (giangvien)','172.19.0.1','2026-11-16 06:39:56','9072ca415a294eec43774ab8046eab4eeada7188b6aa1e372bdf6c6ae5c2d18f','21b89cd3f422d493648616529ad975357a952e0ee476d8b20a3d090738344142'),
(524,'172.19.0.1','PASSWORD_RESET_REQUESTED','sv_an','','Tạo liên kết đổi mật khẩu gửi tới sv_an@ptit.edu.vn (Real SMTP: False, TTL: 15m)','172.19.0.1','2026-11-16 06:40:12','21b89cd3f422d493648616529ad975357a952e0ee476d8b20a3d090738344142','0ef442f98e519fe20f2918627d49d99f7fc3e79064656fa21d2faf6db4ebb4f6'),
(525,'sv_an','PASSWORD_RESET_SUCCESS','sv_an','','Đặt lại mật khẩu thành công qua email xác thực sv_an@ptit.edu.vn','172.19.0.1','2026-11-16 06:40:12','0ef442f98e519fe20f2918627d49d99f7fc3e79064656fa21d2faf6db4ebb4f6','21804b3e2585c8436a32a4adf4aac073491351d09ac4ffca3fcf1e3301b3a41f'),
(526,'172.19.0.1','PASSWORD_RESET_REQUESTED','sv_an','','Tạo liên kết đổi mật khẩu gửi tới sv_an@ptit.edu.vn (Real SMTP: False, TTL: 15m)','172.19.0.1','2026-11-16 06:40:14','21804b3e2585c8436a32a4adf4aac073491351d09ac4ffca3fcf1e3301b3a41f','6c4bac001be06b4a2363b790643b0b91a4e494a604cbb2aa70b044328e02cafa'),
(527,'172.19.0.1','PASSWORD_RESET_REQUESTED','sv_an','','Tạo liên kết đổi mật khẩu gửi tới sv_an@ptit.edu.vn (Real SMTP: False, TTL: 15m)','172.19.0.1','2026-11-16 06:40:14','6c4bac001be06b4a2363b790643b0b91a4e494a604cbb2aa70b044328e02cafa','127137c70e7d9d368e752fef695f31e7f0eaad40b43126b83ec24551182fbd93'),
(528,'sv_an','PASSWORD_RESET_SUCCESS','sv_an','','Đặt lại mật khẩu thành công qua email xác thực sv_an@ptit.edu.vn','172.19.0.1','2026-11-16 06:40:14','127137c70e7d9d368e752fef695f31e7f0eaad40b43126b83ec24551182fbd93','62d93e44f38da6487baac9d7148e3ad05e50dd585fc3fc796b4bffbef80b1798'),
(529,'admin','DASHBOARD_LOGIN_FAILED','DASHBOARD','Lần sai thứ 1/5','Còn 4 lần thử trước khi bị khóa','172.19.0.1','2026-11-16 06:42:04','62d93e44f38da6487baac9d7148e3ad05e50dd585fc3fc796b4bffbef80b1798','e46ab353d59b31d466288aa8bf91591f2e633a086384e46f0b2c80b661f43bf7'),
(530,'admin','DASHBOARD_LOGIN_FAILED','DASHBOARD','Lần sai thứ 2/5','Còn 3 lần thử trước khi bị khóa','172.19.0.1','2026-11-16 06:42:04','e46ab353d59b31d466288aa8bf91591f2e633a086384e46f0b2c80b661f43bf7','4da4c198fa107806d941dc462f150e3e5ca40b06564b5efa7e1808fe197f9a18'),
(531,'admin','DASHBOARD_LOGIN_FAILED','DASHBOARD','Lần sai thứ 3/5','Còn 2 lần thử trước khi bị khóa','172.19.0.1','2026-11-16 06:42:04','4da4c198fa107806d941dc462f150e3e5ca40b06564b5efa7e1808fe197f9a18','beb61dbbe3fae3bf52d210f98b10c4fdd366c8ab3446e63f7d8ab7de948b4162'),
(532,'admin','DASHBOARD_LOGIN_FAILED','DASHBOARD','Lần sai thứ 4/5','Còn 1 lần thử trước khi bị khóa','172.19.0.1','2026-11-16 06:42:04','beb61dbbe3fae3bf52d210f98b10c4fdd366c8ab3446e63f7d8ab7de948b4162','27878e3e5fdf10cd014117690337fd775b44d644cc85068bd2ca4755ef0c91e4'),
(533,'admin','DASHBOARD_ACCOUNT_LOCKED','DASHBOARD','Nhập sai 5 lần liên tiếp từ IP 172.19.0.1','Khóa tài khoản admin trong 60 phút','172.19.0.1','2026-11-16 06:42:04','27878e3e5fdf10cd014117690337fd775b44d644cc85068bd2ca4755ef0c91e4','f9e0390d1af0521931b157541e9152f1e2d1c498a18e67546ae2269b6d334fef'),
(534,'172.19.0.1','DASHBOARD_IP_BLOCKED','DASHBOARD','Thử dò tài khoản: admin','Chặn địa chỉ IP 172.19.0.1 trong 60 phút','172.19.0.1','2026-11-16 06:42:04','f9e0390d1af0521931b157541e9152f1e2d1c498a18e67546ae2269b6d334fef','e3c4783cc0e20cb831256641f75e5f58fb061c23b7e7deaeb8fd8a2ac461bd11'),
(535,'admin','DASHBOARD_LOGIN','SYSTEM','','Login success as admin (quantri)','172.19.0.1','2026-11-16 06:42:05','e3c4783cc0e20cb831256641f75e5f58fb061c23b7e7deaeb8fd8a2ac461bd11','818ba5a58428a2320f866835a43c9e1649e60cc1e6acd53f6ffb6c4c498824e6'),
(536,'admin','MFA_LOGIN_SUCCESS','SYSTEM','','Xác thực MFA thành công qua mã TOTP 6 số cho admin (TimeStep: 59827045)','172.19.0.1','2026-11-16 06:42:38','818ba5a58428a2320f866835a43c9e1649e60cc1e6acd53f6ffb6c4c498824e6','0ee4e629a63e35f0a353071d19e09692b5b8ee691e48c1a38018e5ac37190f8c'),
(537,'admin','MFA_REPLAY_ATTEMPT','SYSTEM','Replayed OTP code: 947488','','172.19.0.1','2026-11-16 06:42:38','0ee4e629a63e35f0a353071d19e09692b5b8ee691e48c1a38018e5ac37190f8c','584a2efb3101085632723ee8013cdcbeb6c269c6c3da60d3922b0ad894a7d7bc'),
(538,'admin','MFA_LOGIN_FAILED','SYSTEM','Invalid TOTP','Lần sai thứ 1/3. Còn 2 lần thử.','172.19.0.1','2026-11-16 06:42:38','584a2efb3101085632723ee8013cdcbeb6c269c6c3da60d3922b0ad894a7d7bc','f78304e8e28ea54c0c00f4b41f9beeac83ee18efc1afc7174a146c53fa0b50cc'),
(539,'admin','MFA_LOGIN_FAILED','SYSTEM','Invalid TOTP','Lần sai thứ 2/3. Còn 1 lần thử.','172.19.0.1','2026-11-16 06:42:39','f78304e8e28ea54c0c00f4b41f9beeac83ee18efc1afc7174a146c53fa0b50cc','b5da7ce9944fcb2d04ec6f9347a8aeaaf90a3d803ceca9685b0925299f70ec1f'),
(540,'admin','MFA_LOCKED','SYSTEM','Nhập sai 3 lần liên tiếp','Khóa MFA trong 10 phút','172.19.0.1','2026-11-16 06:42:39','b5da7ce9944fcb2d04ec6f9347a8aeaaf90a3d803ceca9685b0925299f70ec1f','9a75e159d06e9370b6252e3a74c2eb7676dfbea052102ec43f3dd473cdbae600');
/*!40000 ALTER TABLE `audit_logs` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_audit_logs_no_update BEFORE UPDATE ON audit_logs FOR EACH ROW SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SECURITY AUDIT VIOLATION: audit_logs is strictly append-only. UPDATE is prohibited.' 
*/;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_audit_logs_no_delete BEFORE DELETE ON audit_logs FOR EACH ROW SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'SECURITY AUDIT VIOLATION: audit_logs is strictly append-only. DELETE is prohibited.' 
*/;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `dashboard_account_lockouts`
--

DROP TABLE IF EXISTS `dashboard_account_lockouts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `dashboard_account_lockouts` (
  `username` varchar(64) NOT NULL,
  `failed_attempts` int(11) DEFAULT 0,
  `locked_until` datetime DEFAULT NULL,
  `last_failed_at` datetime DEFAULT NULL,
  `last_failed_ip` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dashboard_account_lockouts`
--

LOCK TABLES `dashboard_account_lockouts` WRITE;
/*!40000 ALTER TABLE `dashboard_account_lockouts` DISABLE KEYS */;
/*!40000 ALTER TABLE `dashboard_account_lockouts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dashboard_ip_lockouts`
--

DROP TABLE IF EXISTS `dashboard_ip_lockouts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `dashboard_ip_lockouts` (
  `ip_address` varchar(45) NOT NULL,
  `failed_attempts` int(11) DEFAULT 0,
  `blocked_until` datetime DEFAULT NULL,
  `last_attempt_at` datetime DEFAULT NULL,
  `last_target_user` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`ip_address`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dashboard_ip_lockouts`
--

LOCK TABLES `dashboard_ip_lockouts` WRITE;
/*!40000 ALTER TABLE `dashboard_ip_lockouts` DISABLE KEYS */;
/*!40000 ALTER TABLE `dashboard_ip_lockouts` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `nas`
--

DROP TABLE IF EXISTS `nas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `nas` (
  `id` int(10) NOT NULL AUTO_INCREMENT,
  `nasname` varchar(128) NOT NULL,
  `shortname` varchar(32) DEFAULT NULL,
  `type` varchar(30) DEFAULT 'other',
  `ports` int(5) DEFAULT NULL,
  `secret` varchar(60) NOT NULL DEFAULT 'secret',
  `server` varchar(64) DEFAULT NULL,
  `community` varchar(50) DEFAULT NULL,
  `description` varchar(200) DEFAULT 'RADIUS Client',
  PRIMARY KEY (`id`),
  KEY `nasname` (`nasname`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `nas`
--

LOCK TABLES `nas` WRITE;
/*!40000 ALTER TABLE `nas` DISABLE KEYS */;
/*!40000 ALTER TABLE `nas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `password_reset_tokens`
--

DROP TABLE IF EXISTS `password_reset_tokens`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `password_reset_tokens` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(64) NOT NULL,
  `email` varchar(128) NOT NULL,
  `token_hash` varchar(64) NOT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `expires_at` datetime NOT NULL,
  `is_used` tinyint(1) DEFAULT 0,
  `used_at` datetime DEFAULT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `token_hash` (`token_hash`),
  KEY `username` (`username`),
  KEY `expires_at` (`expires_at`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `password_reset_tokens`
--

LOCK TABLES `password_reset_tokens` WRITE;
/*!40000 ALTER TABLE `password_reset_tokens` DISABLE KEYS */;
INSERT INTO `password_reset_tokens` VALUES
(1,'sv_an','sv_an@ptit.edu.vn','b3e6e254a08c15b39dbd1db654031d4fe5a06eba872a36fd06a687fdd549cc72','2026-11-15 13:11:27','2026-11-15 13:26:27',1,'2026-11-15 13:11:27','172.19.0.1'),
(2,'sv_an','sv_an@ptit.edu.vn','c0d8d0cea963f961648a30b4f64adb788ad91dcadf67d27c58304fed31055490','2026-11-15 13:11:28','2026-11-15 13:26:28',1,'2026-11-15 13:11:28','172.19.0.1'),
(3,'sv_an','sv_an@ptit.edu.vn','999dee5f6065597a5de3898772b890d4ab53c30aa54d80c3c02cb78b507c058c','2026-11-15 13:11:28','2026-11-15 13:26:28',1,'2026-11-15 13:11:28','172.19.0.1'),
(4,'sv_an','sv_an@ptit.edu.vn','e0fcbff4201a727091b412bf3a10b208256c8f727e9968032b8009a4bd90844c','2026-11-15 13:16:07','2026-11-15 13:31:07',1,'2026-11-15 13:16:07','172.19.0.1'),
(5,'sv_an','sv_an@ptit.edu.vn','0a319cd3cb62b78ea5991fa5e522c950d8c165e393c69245052bab1d974b1dde','2026-11-15 13:16:08','2026-11-15 13:31:08',1,'2026-11-15 13:16:09','172.19.0.1'),
(6,'sv_an','sv_an@ptit.edu.vn','fa24c6b778c8f50aaddf2f3e2db0a82ec9326530a124edbf84554bf8f229a803','2026-11-15 13:16:09','2026-11-15 13:31:09',1,'2026-11-15 13:16:09','172.19.0.1'),
(7,'meoluoi','hongmeoluoi2202@gmail.com','7406a6345ce7c02cf5f37218cb98308b89892b84b9602addcd750f858c60583d','2026-11-15 13:19:50','2026-11-15 13:34:50',1,'2026-11-15 13:30:05','172.19.0.1'),
(8,'sv_an','sv_an@ptit.edu.vn','d7f9daa37d7647ed4961fcbc446c498bfdefeb9f11a47d2739298678390092a5','2026-11-15 13:28:31','2026-11-15 13:43:31',1,'2026-11-15 13:28:31','172.19.0.1'),
(9,'sv_an','sv_an@ptit.edu.vn','0ff80f4e91d12f5d869ca0933ffe196b16b134f29e1730520928f40e59ad736b','2026-11-15 13:28:33','2026-11-15 13:43:33',1,'2026-11-15 13:28:33','172.19.0.1'),
(10,'sv_an','sv_an@ptit.edu.vn','9b9760e41cefd8a937abd6424476c612bd5e5eb1fb27bd2dd3d85fe29207536f','2026-11-15 13:28:33','2026-11-15 13:43:33',1,'2026-11-15 13:28:33','172.19.0.1'),
(11,'meoluoi','hongmeoluoi2202@gmail.com','bbda316726f9d624f131eef53a928637efaaa07428f6063ba58cb2079fade7ad','2026-11-15 13:30:05','2026-11-15 13:45:05',0,NULL,'172.19.0.1'),
(12,'sv_an','sv_an@ptit.edu.vn','006129cf19e1f1cadfe4aa3a7d14cb19cf1649307a5c34ad93800751535e4712','2026-11-15 13:42:52','2026-11-15 13:57:52',1,'2026-11-15 13:42:52','172.19.0.1'),
(13,'sv_an','sv_an@ptit.edu.vn','32535391d0378f5b8ba4893275e5d1856108d7cdd6665b8bf1fa1f88680069b7','2026-11-15 13:42:53','2026-11-15 13:57:53',1,'2026-11-15 13:42:53','172.19.0.1'),
(14,'sv_an','sv_an@ptit.edu.vn','5560a1b42a1f1d81b8b442e30f6616e2b91cca2b1dd5f19ead280d8749aceee1','2026-11-15 13:42:53','2026-11-15 13:57:53',1,'2026-11-15 13:42:53','172.19.0.1'),
(15,'sv_an','sv_an@ptit.edu.vn','5be616530bd565cc8972fb0bee4d0286d6e254a7e21b612cde95ca177a26557d','2026-11-15 14:28:03','2026-11-15 14:43:03',1,'2026-11-15 14:28:03','172.19.0.1'),
(16,'sv_an','sv_an@ptit.edu.vn','f94a1fd89fcc006121ab07b577b42ec920fe42501dfdf634bc4c5654b4e78d46','2026-11-15 14:28:04','2026-11-15 14:43:04',1,'2026-11-15 14:28:04','172.19.0.1'),
(17,'sv_an','sv_an@ptit.edu.vn','bf2940517badcf427cbe972c22a21612318cb5171771611bb84f42562ba69e6c','2026-11-15 14:28:04','2026-11-15 14:43:04',1,'2026-11-15 14:28:04','172.19.0.1'),
(18,'sv_an','sv_an@ptit.edu.vn','8a18f96bca15d2c6b58293ec8e0b4746bdbe2fe9d98ad4bd2c17745874f06ef7','2026-11-16 06:40:12','2026-11-16 06:55:12',1,'2026-11-16 06:40:12','172.19.0.1'),
(19,'sv_an','sv_an@ptit.edu.vn','30359617b49bf7fd9c5ff39271714a13910eb1221386c3d983f378db7b643878','2026-11-16 06:40:14','2026-11-16 06:55:14',1,'2026-11-16 06:40:14','172.19.0.1'),
(20,'sv_an','sv_an@ptit.edu.vn','a14fd0877c53f3c5b243f0d5165f0d2a47f41b05e126994994fde8d14bf351c1','2026-11-16 06:40:14','2026-11-16 06:55:14',1,'2026-11-16 06:40:14','172.19.0.1');
/*!40000 ALTER TABLE `password_reset_tokens` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `policy_matrix`
--

DROP TABLE IF EXISTS `policy_matrix`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `policy_matrix` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `group_name` varchar(64) NOT NULL COMMENT 'Tên nhóm tương ứng trên OpenLDAP',
  `vlan_id` int(11) NOT NULL COMMENT 'Mã VLAN gán động (Dynamic VLAN ID)',
  `vlan_name` varchar(64) NOT NULL COMMENT 'Tên phân đoạn mạng',
  `subnet_cidr` varchar(32) NOT NULL COMMENT 'Dải địa chỉ IP giả định',
  `session_timeout` int(11) DEFAULT 14400 COMMENT 'Thời lượng tối đa của một phiên (giây)',
  `idle_timeout` int(11) DEFAULT 600 COMMENT 'Thời gian rảnh trước khi ngắt phiên (giây)',
  `priority` int(11) DEFAULT 10 COMMENT 'Trọng số ưu tiên khi giải quyết xung đột nhóm',
  `description` text DEFAULT NULL COMMENT 'Mô tả mục đích và phạm vi tài nguyên truy cập',
  `is_active` tinyint(1) DEFAULT 1 COMMENT '1 = Kích hoạt, 0 = Tạm dừng',
  `created_at` timestamp NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `group_name` (`group_name`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `policy_matrix`
--

LOCK TABLES `policy_matrix` WRITE;
/*!40000 ALTER TABLE `policy_matrix` DISABLE KEYS */;
INSERT INTO `policy_matrix` VALUES
(1,'quarantine',99,'VLAN Cách ly','10.10.99.0/24',1800,300,1000,'Phân đoạn cách ly tài khoản vi phạm hoặc nghi ngờ dò mật khẩu brute-force',1,'2026-11-14 12:22:48','2026-11-14 12:22:48'),
(2,'quantri',10,'VLAN Quản trị','10.10.10.0/24',7200,900,100,'Phân đoạn quản trị mạng nội bộ, máy chủ và hạ tầng',1,'2026-11-14 12:22:48','2026-11-14 12:22:48'),
(3,'giangvien',30,'VLAN Giảng viên','10.10.30.0/24',28800,1800,50,'Phân đoạn dành cho cán bộ giảng viên truy cập hệ thống nghiệp vụ và LMS',1,'2026-11-14 12:22:48','2026-11-14 12:22:48'),
(4,'sinhvien',20,'VLAN Sinh viên','10.10.20.0/24',14400,600,10,'Phân đoạn học tập cho sinh viên, truy cập Internet và Cổng thông tin đào tạo',1,'2026-11-14 12:22:48','2026-11-14 12:22:48');
/*!40000 ALTER TABLE `policy_matrix` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `quarantine_events`
--

DROP TABLE IF EXISTS `quarantine_events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `quarantine_events` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(64) NOT NULL,
  `event_type` enum('QUARANTINE','RELEASE') NOT NULL COMMENT 'Loai su kien: QUARANTINE hoac RELEASE',
  `reason` text DEFAULT NULL COMMENT 'Ly do cach ly hoac giai phong',
  `failed_count` int(11) DEFAULT 0 COMMENT 'So lan that bai ghi nhan',
  `source` varchar(64) NOT NULL COMMENT 'Nguon thuc hien (SYSTEM_ACTIVE_DEFENSE, admin...)',
  `previous_group` varchar(64) DEFAULT NULL COMMENT 'Nhom truoc do',
  `event_time` timestamp(6) NOT NULL DEFAULT current_timestamp(6),
  PRIMARY KEY (`id`),
  KEY `idx_user_time` (`username`,`event_time`),
  KEY `idx_event_type` (`event_type`)
) ENGINE=InnoDB AUTO_INCREMENT=60 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `quarantine_events`
--

LOCK TABLES `quarantine_events` WRITE;
/*!40000 ALTER TABLE `quarantine_events` DISABLE KEYS */;
INSERT INTO `quarantine_events` VALUES
(1,'forensic_test_user','QUARANTINE','Testing triggers',6,'TEST_SUITE',NULL,'2026-11-14 19:02:10.358127'),
(2,'student02','QUARANTINE','Vượt ngưỡng brute-force 6 lần trong 180s',6,'SYSTEM_ACTIVE_DEFENSE','sinhvien','2026-11-14 19:02:10.614880'),
(3,'student02','RELEASE','Giai phong qua test suite',0,'admin_test','quarantine','2026-11-14 19:02:10.713227'),
(4,'forensic_test_user','QUARANTINE','Testing triggers',6,'TEST_SUITE',NULL,'2026-11-15 02:30:31.309091'),
(5,'student02','QUARANTINE','Vượt ngưỡng brute-force 6 lần trong 180s',6,'SYSTEM_ACTIVE_DEFENSE','sinhvien','2026-11-15 02:30:31.535831'),
(6,'student02','RELEASE','Giai phong qua test suite',0,'admin_test','quarantine','2026-11-15 02:30:31.663056'),
(7,'forensic_test_user','QUARANTINE','Testing triggers',6,'TEST_SUITE',NULL,'2026-11-15 02:45:30.920710'),
(8,'forensic_test_user','QUARANTINE','Testing triggers',6,'TEST_SUITE',NULL,'2026-11-15 02:45:49.224922'),
(9,'sv_test','QUARANTINE','Vượt ngưỡng brute-force 6 lần trong 180s',6,'SYSTEM_ACTIVE_DEFENSE','sinhvien','2026-11-15 02:45:49.429245'),
(10,'sv_test','RELEASE','Giai phong qua test suite',0,'admin_test','quarantine','2026-11-15 02:45:49.491011'),
(11,'sv_vinh','QUARANTINE','Vượt ngưỡng brute-force 6 lần trong 180s',6,'SYSTEM_ACTIVE_DEFENSE','sinhvien','2026-11-15 02:48:25.433055'),
(12,'sv_an','QUARANTINE','Cách ly thủ công bởi quản trị viên',0,'admin','sinhvien','2026-11-15 03:16:58.351164'),
(13,'sv_an','RELEASE','Mở khóa bởi quản trị viên và khôi phục về nhóm sinhvien',0,'admin','quarantine','2026-11-15 03:22:45.801706'),
(14,'sv_vinh','RELEASE','Mở khóa bởi quản trị viên và khôi phục về nhóm sinhvien',0,'admin','quarantine','2026-11-15 03:22:50.318018'),
(15,'sv_vinh','QUARANTINE','Vượt ngưỡng brute-force 6 lần trong 180s',6,'SYSTEM_ACTIVE_DEFENSE','sinhvien','2026-11-15 04:07:40.840628'),
(16,'sv_vinh','RELEASE','Mở khóa bởi quản trị viên và khôi phục về nhóm sinhvien',0,'admin','quarantine','2026-11-15 04:08:55.270553'),
(17,'sv_vinh','QUARANTINE','Cách ly thủ công bởi quản trị viên',0,'admin','sinhvien','2026-11-15 09:17:17.112550'),
(18,'sv_vinh','RELEASE','Mở khóa bởi quản trị viên và khôi phục về nhóm sinhvien',0,'admin','quarantine','2026-11-15 09:18:07.863650'),
(19,'sv_vinh','QUARANTINE','Cách ly thủ công bởi quản trị viên',0,'admin','sinhvien','2026-11-15 09:18:31.442729'),
(20,'sv_binh','RELEASE','Mở khóa bởi quản trị viên và khôi phục về nhóm sinhvien. Giải phóng IP: Không có',0,'admin','quarantine','2026-11-15 10:07:08.645793'),
(21,'sv_binh','QUARANTINE','Cách ly thủ công bởi quản trị viên. Thu hồi 1 phiên SSO, chặn IP: 172.19.0.1',0,'admin','sinhvien','2026-11-15 10:07:09.285013'),
(22,'sv_binh','RELEASE','Mở khóa bởi quản trị viên và khôi phục về nhóm sinhvien. Giải phóng IP: 172.19.0.1',0,'admin','quarantine','2026-11-15 10:07:09.562587'),
(23,'sv_binh','RELEASE','Mở khóa bởi quản trị viên và khôi phục về nhóm sinhvien. Giải phóng IP: Không có',0,'admin','quarantine','2026-11-15 10:08:15.437915'),
(24,'sv_binh','QUARANTINE','Cách ly thủ công bởi quản trị viên. Thu hồi 2 phiên SSO, chặn IP: 172.19.0.1',0,'admin','sinhvien','2026-11-15 10:08:15.908354'),
(25,'sv_binh','RELEASE','Mở khóa bởi quản trị viên và khôi phục về nhóm sinhvien. Giải phóng IP: 172.19.0.1',0,'admin','quarantine','2026-11-15 10:08:16.294893'),
(26,'sv_vinh','QUARANTINE','Cách ly thủ công bởi quản trị viên. Thu hồi 0 phiên SSO, chặn IP: 172.19.0.1',0,'admin','sinhvien','2026-11-15 10:09:58.850423'),
(27,'sv_vinh','RELEASE','Mở khóa bởi quản trị viên và khôi phục về nhóm sinhvien. Giải phóng IP: 172.19.0.1',0,'admin','quarantine','2026-11-15 10:10:58.440236'),
(28,'sv_binh','RELEASE','Mở khóa bởi quản trị viên và khôi phục về nhóm sinhvien. Giải phóng IP: Không có',0,'admin','quarantine','2026-11-15 10:15:55.206966'),
(29,'sv_binh','QUARANTINE','Cách ly thủ công bởi quản trị viên. Thu hồi 2 phiên SSO, chặn IP: 172.19.0.1',0,'admin','sinhvien','2026-11-15 10:15:55.639980'),
(30,'sv_binh','RELEASE','Mở khóa bởi quản trị viên và khôi phục về nhóm sinhvien. Giải phóng IP: 172.19.0.1',0,'admin','quarantine','2026-11-15 10:15:55.950140'),
(31,'sv_vinh','QUARANTINE','Cách ly thủ công bởi quản trị viên. Thu hồi 1 phiên SSO, chặn IP: 172.19.0.1',0,'admin','sinhvien','2026-11-15 10:18:05.804345'),
(32,'sv_vinh','RELEASE','Mở khóa bởi quản trị viên và khôi phục về nhóm sinhvien. Giải phóng IP: 172.19.0.1',0,'admin','quarantine','2026-11-15 10:18:23.370271'),
(33,'sv_vinh','QUARANTINE','Vượt ngưỡng brute-force 6 lần trong 180s. Thu hồi phiên SSO, chặn IP: 172.19.0.1',6,'SYSTEM_ACTIVE_DEFENSE','sinhvien','2026-11-15 10:19:51.415147'),
(34,'sv_vinh','RELEASE','Mở khóa bởi quản trị viên và khôi phục về nhóm sinhvien. Giải phóng IP: 172.19.0.1',0,'admin','quarantine','2026-11-15 10:20:32.482385'),
(35,'sv_binh','RELEASE','Mở khóa bởi quản trị viên và khôi phục về nhóm sinhvien. Giải phóng IP: Không có',0,'admin','quarantine','2026-11-15 11:41:07.670349'),
(36,'sv_binh','QUARANTINE','Cách ly thủ công bởi quản trị viên. Thu hồi 2 phiên SSO, chặn IP: 172.19.0.1',0,'admin','sinhvien','2026-11-15 11:41:08.087207'),
(37,'sv_binh','RELEASE','Mở khóa bởi quản trị viên và khôi phục về nhóm sinhvien. Giải phóng IP: 172.19.0.1',0,'admin','quarantine','2026-11-15 11:41:08.424590'),
(38,'sv_vinh','QUARANTINE','Vượt ngưỡng brute-force 6 lần trong 180s. Thu hồi phiên SSO, chặn IP: 172.19.0.1',6,'SYSTEM_ACTIVE_DEFENSE','sinhvien','2026-11-15 12:33:45.172635'),
(39,'sv_binh','RELEASE','Mở khóa bởi quản trị viên và khôi phục về nhóm sinhvien. Giải phóng IP: Không có',0,'admin','quarantine','2026-11-15 12:34:51.271111'),
(40,'sv_binh','QUARANTINE','Cách ly thủ công bởi quản trị viên. Thu hồi 2 phiên SSO, chặn IP: 172.19.0.1',0,'admin','sinhvien','2026-11-15 12:34:51.699423'),
(41,'sv_binh','RELEASE','Mở khóa bởi quản trị viên và khôi phục về nhóm sinhvien. Giải phóng IP: 172.19.0.1',0,'admin','quarantine','2026-11-15 12:34:52.029367'),
(42,'sv_vinh','QUARANTINE','Vượt ngưỡng brute-force 9 lần trong 180s. Thu hồi phiên SSO, chặn IP: 172.19.0.1',9,'SYSTEM_ACTIVE_DEFENSE','sinhvien','2026-11-15 12:35:48.315184'),
(43,'sv_vinh','QUARANTINE','Vượt ngưỡng brute-force 9 lần trong 180s. Thu hồi phiên SSO, chặn IP: 172.19.0.1',9,'SYSTEM_ACTIVE_DEFENSE','sinhvien','2026-11-15 12:36:23.827799'),
(44,'sv_binh','RELEASE','Mở khóa bởi quản trị viên và khôi phục về nhóm sinhvien. Giải phóng IP: Không có',0,'admin','quarantine','2026-11-15 12:44:44.251032'),
(45,'sv_binh','QUARANTINE','Cách ly thủ công bởi quản trị viên. Thu hồi 2 phiên SSO, chặn IP: 172.19.0.1',0,'admin','sinhvien','2026-11-15 12:44:44.807790'),
(46,'sv_binh','RELEASE','Mở khóa bởi quản trị viên và khôi phục về nhóm sinhvien. Giải phóng IP: 172.19.0.1',0,'admin','quarantine','2026-11-15 12:44:45.123315'),
(47,'sv_vinh','QUARANTINE','Vượt ngưỡng brute-force 6 lần trong 180s. Thu hồi phiên SSO, chặn IP: 172.19.0.1',6,'SYSTEM_ACTIVE_DEFENSE','sinhvien','2026-11-15 12:47:28.284979'),
(48,'sv_vinh','RELEASE','Mở khóa bởi quản trị viên và khôi phục về nhóm sinhvien. Giải phóng IP: 172.19.0.1',0,'admin','quarantine','2026-11-15 12:48:10.424510'),
(49,'sv_binh','RELEASE','Mở khóa bởi quản trị viên và khôi phục về nhóm sinhvien. Giải phóng IP: Không có',0,'admin','quarantine','2026-11-15 13:13:24.560159'),
(50,'sv_binh','QUARANTINE','Cách ly thủ công bởi quản trị viên. Thu hồi 2 phiên SSO, chặn IP: 172.19.0.1',0,'admin','sinhvien','2026-11-15 13:13:24.953431'),
(51,'sv_binh','RELEASE','Mở khóa bởi quản trị viên và khôi phục về nhóm sinhvien. Giải phóng IP: 172.19.0.1',0,'admin','quarantine','2026-11-15 13:13:25.208743'),
(52,'meoluoi','QUARANTINE','Cách ly thủ công bởi quản trị viên. Thu hồi 2 phiên SSO, chặn IP: 172.19.0.1',0,'admin','sinhvien','2026-11-15 13:40:15.143034'),
(53,'meoluoi','RELEASE','Mở khóa bởi quản trị viên và khôi phục về nhóm sinhvien. Giải phóng IP: 172.19.0.1',0,'admin','quarantine','2026-11-15 13:40:37.485993'),
(54,'sv_binh','RELEASE','Mở khóa bởi quản trị viên và khôi phục về nhóm sinhvien. Giải phóng IP: Không có',0,'admin','quarantine','2026-11-15 14:28:23.026646'),
(55,'sv_binh','QUARANTINE','Cách ly thủ công bởi quản trị viên. Thu hồi 2 phiên SSO, chặn IP: 172.19.0.1',0,'admin','sinhvien','2026-11-15 14:28:23.526680'),
(56,'sv_binh','RELEASE','Mở khóa bởi quản trị viên và khôi phục về nhóm sinhvien. Giải phóng IP: 172.19.0.1',0,'admin','quarantine','2026-11-15 14:28:23.874083'),
(57,'sv_binh','RELEASE','Mở khóa bởi quản trị viên và khôi phục về nhóm sinhvien. Giải phóng IP: Không có',0,'admin','quarantine','2026-11-16 06:39:38.646846'),
(58,'sv_binh','QUARANTINE','Cách ly thủ công bởi quản trị viên. Thu hồi 2 phiên SSO, chặn IP: 172.19.0.1',0,'admin','sinhvien','2026-11-16 06:39:39.256052'),
(59,'sv_binh','RELEASE','Mở khóa bởi quản trị viên và khôi phục về nhóm sinhvien. Giải phóng IP: 172.19.0.1',0,'admin','quarantine','2026-11-16 06:39:39.603191');
/*!40000 ALTER TABLE `quarantine_events` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_quarantine_events_no_update BEFORE UPDATE ON quarantine_events FOR EACH ROW SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INTEGRITY VIOLATION: quarantine_events is strictly append-only. UPDATE is prohibited.' 
*/;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_quarantine_events_no_delete BEFORE DELETE ON quarantine_events FOR EACH ROW SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'INTEGRITY VIOLATION: quarantine_events is strictly append-only. DELETE is prohibited.' 
*/;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `radacct`
--

DROP TABLE IF EXISTS `radacct`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `radacct` (
  `radacctid` bigint(21) NOT NULL AUTO_INCREMENT,
  `acctsessionid` varchar(64) NOT NULL DEFAULT '',
  `acctuniqueid` varchar(32) NOT NULL DEFAULT '',
  `username` varchar(64) NOT NULL DEFAULT '',
  `realm` varchar(64) DEFAULT '',
  `nasipaddress` varchar(15) NOT NULL DEFAULT '',
  `nasportid` varchar(32) DEFAULT NULL,
  `nasporttype` varchar(32) DEFAULT NULL,
  `acctstarttime` datetime DEFAULT NULL,
  `acctupdatetime` datetime DEFAULT NULL,
  `acctstoptime` datetime DEFAULT NULL,
  `acctinterval` int(12) DEFAULT NULL,
  `acctsessiontime` int(12) unsigned DEFAULT NULL,
  `acctauthentic` varchar(32) DEFAULT NULL,
  `connectinfo_start` varchar(128) DEFAULT NULL,
  `connectinfo_stop` varchar(128) DEFAULT NULL,
  `acctinputoctets` bigint(20) DEFAULT NULL,
  `acctoutputoctets` bigint(20) DEFAULT NULL,
  `calledstationid` varchar(50) NOT NULL DEFAULT '',
  `callingstationid` varchar(50) NOT NULL DEFAULT '',
  `acctterminatecause` varchar(32) NOT NULL DEFAULT '',
  `servicetype` varchar(32) DEFAULT NULL,
  `framedprotocol` varchar(32) DEFAULT NULL,
  `framedipaddress` varchar(15) NOT NULL DEFAULT '',
  `framedipv6address` varchar(45) NOT NULL DEFAULT '',
  `framedipv6prefix` varchar(45) NOT NULL DEFAULT '',
  `framedinterfaceid` varchar(44) NOT NULL DEFAULT '',
  `delegatedipv6prefix` varchar(45) NOT NULL DEFAULT '',
  `class` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`radacctid`),
  UNIQUE KEY `acctuniqueid` (`acctuniqueid`),
  KEY `username` (`username`),
  KEY `framedipaddress` (`framedipaddress`),
  KEY `acctsessionid` (`acctsessionid`),
  KEY `acctstarttime` (`acctstarttime`),
  KEY `acctstoptime` (`acctstoptime`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `radacct`
--

LOCK TABLES `radacct` WRITE;
/*!40000 ALTER TABLE `radacct` DISABLE KEYS */;
/*!40000 ALTER TABLE `radacct` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `radcheck`
--

DROP TABLE IF EXISTS `radcheck`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `radcheck` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(64) NOT NULL DEFAULT '',
  `attribute` varchar(64) NOT NULL DEFAULT '',
  `op` char(2) NOT NULL DEFAULT '==',
  `value` varchar(253) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `username` (`username`(32))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `radcheck`
--

LOCK TABLES `radcheck` WRITE;
/*!40000 ALTER TABLE `radcheck` DISABLE KEYS */;
/*!40000 ALTER TABLE `radcheck` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `radgroupcheck`
--

DROP TABLE IF EXISTS `radgroupcheck`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `radgroupcheck` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `groupname` varchar(64) NOT NULL DEFAULT '',
  `attribute` varchar(64) NOT NULL DEFAULT '',
  `op` char(2) NOT NULL DEFAULT '==',
  `value` varchar(253) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `groupname` (`groupname`(32))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `radgroupcheck`
--

LOCK TABLES `radgroupcheck` WRITE;
/*!40000 ALTER TABLE `radgroupcheck` DISABLE KEYS */;
/*!40000 ALTER TABLE `radgroupcheck` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `radgroupreply`
--

DROP TABLE IF EXISTS `radgroupreply`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `radgroupreply` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `groupname` varchar(64) NOT NULL DEFAULT '',
  `attribute` varchar(64) NOT NULL DEFAULT '',
  `op` char(2) NOT NULL DEFAULT '=',
  `value` varchar(253) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `groupname` (`groupname`(32))
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `radgroupreply`
--

LOCK TABLES `radgroupreply` WRITE;
/*!40000 ALTER TABLE `radgroupreply` DISABLE KEYS */;
INSERT INTO `radgroupreply` VALUES
(1,'quantri','Tunnel-Type',':=','VLAN'),
(2,'quantri','Tunnel-Medium-Type',':=','IEEE-802'),
(3,'quantri','Tunnel-Private-Group-Id',':=','10'),
(4,'quantri','Session-Timeout',':=','7200'),
(5,'quantri','Idle-Timeout',':=','900'),
(6,'quantri','Termination-Action',':=','1'),
(7,'giangvien','Tunnel-Type',':=','VLAN'),
(8,'giangvien','Tunnel-Medium-Type',':=','IEEE-802'),
(9,'giangvien','Tunnel-Private-Group-Id',':=','30'),
(10,'giangvien','Session-Timeout',':=','28800'),
(11,'giangvien','Idle-Timeout',':=','1800'),
(12,'giangvien','Termination-Action',':=','1'),
(13,'sinhvien','Tunnel-Type',':=','VLAN'),
(14,'sinhvien','Tunnel-Medium-Type',':=','IEEE-802'),
(15,'sinhvien','Tunnel-Private-Group-Id',':=','20'),
(16,'sinhvien','Session-Timeout',':=','14400'),
(17,'sinhvien','Idle-Timeout',':=','600'),
(18,'sinhvien','Termination-Action',':=','1'),
(19,'quarantine','Tunnel-Type',':=','VLAN'),
(20,'quarantine','Tunnel-Medium-Type',':=','IEEE-802'),
(21,'quarantine','Tunnel-Private-Group-Id',':=','99'),
(22,'quarantine','Session-Timeout',':=','1800'),
(23,'quarantine','Idle-Timeout',':=','300'),
(24,'quarantine','Termination-Action',':=','1');
/*!40000 ALTER TABLE `radgroupreply` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `radius_temp_lock`
--

DROP TABLE IF EXISTS `radius_temp_lock`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `radius_temp_lock` (
  `username` varchar(64) NOT NULL,
  `until_at` datetime NOT NULL,
  PRIMARY KEY (`username`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `radius_temp_lock`
--

LOCK TABLES `radius_temp_lock` WRITE;
/*!40000 ALTER TABLE `radius_temp_lock` DISABLE KEYS */;
/*!40000 ALTER TABLE `radius_temp_lock` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `radpostauth`
--

DROP TABLE IF EXISTS `radpostauth`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `radpostauth` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(64) NOT NULL DEFAULT '',
  `pass` varchar(64) NOT NULL DEFAULT '',
  `reply` varchar(32) NOT NULL DEFAULT '',
  `authdate` timestamp(6) NOT NULL DEFAULT current_timestamp(6),
  `class` varchar(64) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `username` (`username`),
  KEY `authdate` (`authdate`)
) ENGINE=InnoDB AUTO_INCREMENT=262 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `radpostauth`
--

LOCK TABLES `radpostauth` WRITE;
/*!40000 ALTER TABLE `radpostauth` DISABLE KEYS */;
INSERT INTO `radpostauth` VALUES
(1,'forensic_test_user','','Access-Reject','2026-11-14 19:02:10.336899',NULL),
(2,'student02','','Access-Reject','2026-11-14 19:02:10.496036',NULL),
(3,'student02','','Access-Reject','2026-11-14 19:02:10.497776',NULL),
(4,'student02','','Access-Reject','2026-11-14 19:02:10.501245',NULL),
(5,'student02','','Access-Reject','2026-11-14 19:02:10.503009',NULL),
(6,'student02','','Access-Reject','2026-11-14 19:02:10.505850',NULL),
(7,'student02','','Access-Reject','2026-11-14 19:02:10.507207',NULL),
(8,'forensic_test_user','','Access-Reject','2026-11-15 02:30:31.277929',NULL),
(9,'student02','','Access-Reject','2026-11-15 02:30:31.425555',NULL),
(10,'student02','','Access-Reject','2026-11-15 02:30:31.429682',NULL),
(11,'student02','','Access-Reject','2026-11-15 02:30:31.439668',NULL),
(12,'student02','','Access-Reject','2026-11-15 02:30:31.443533',NULL),
(13,'student02','','Access-Reject','2026-11-15 02:30:31.447481',NULL),
(14,'student02','','Access-Reject','2026-11-15 02:30:31.451380',NULL),
(15,'sv_vinh','','Access-Reject','2026-11-15 02:32:17.408985',NULL),
(16,'sv_vinh','','Access-Reject','2026-11-15 02:32:19.438138',NULL),
(17,'sv_vinh','','Access-Reject','2026-11-15 02:32:21.453757',NULL),
(18,'sv_vinh','','Access-Reject','2026-11-15 02:32:23.476343',NULL),
(19,'sv_vinh','','Access-Reject','2026-11-15 02:32:25.501592',NULL),
(20,'sv_vinh','','Access-Reject','2026-11-15 02:32:27.526503',NULL),
(21,'sv_vinh','','Access-Reject','2026-11-15 02:32:29.537754',NULL),
(22,'sv_vinh','','Access-Reject','2026-11-15 02:32:31.557507',NULL),
(23,'sv_vinh','','Access-Reject','2026-11-15 02:32:33.574106',NULL),
(24,'sv_vinh','','Access-Reject','2026-11-15 02:32:35.590080',NULL),
(25,'sv_vinh','','Access-Reject','2026-11-15 02:32:37.610674',NULL),
(26,'sv_vinh','','Access-Reject','2026-11-15 02:32:39.627767',NULL),
(27,'ghost_user_999','','Access-Reject','2026-11-15 02:45:24.926709',NULL),
(28,'ghost_user_999','','Access-Reject','2026-11-15 02:45:24.931180',NULL),
(29,'ghost_user_999','','Access-Reject','2026-11-15 02:45:24.934083',NULL),
(30,'ghost_user_999','','Access-Reject','2026-11-15 02:45:24.936635',NULL),
(31,'ghost_user_999','','Access-Reject','2026-11-15 02:45:24.944079',NULL),
(32,'ghost_user_999','','Access-Reject','2026-11-15 02:45:24.948347',NULL),
(33,'forensic_test_user','','Access-Reject','2026-11-15 02:45:30.891251',NULL),
(34,'student02','','Access-Reject','2026-11-15 02:45:31.065731',NULL),
(35,'student02','','Access-Reject','2026-11-15 02:45:31.071370',NULL),
(36,'student02','','Access-Reject','2026-11-15 02:45:31.077228',NULL),
(37,'student02','','Access-Reject','2026-11-15 02:45:31.081543',NULL),
(38,'student02','','Access-Reject','2026-11-15 02:45:31.087018',NULL),
(39,'student02','','Access-Reject','2026-11-15 02:45:31.092305',NULL),
(40,'forensic_test_user','','Access-Reject','2026-11-15 02:45:49.207413',NULL),
(41,'sv_test','','Access-Reject','2026-11-15 02:45:49.311083',NULL),
(42,'sv_test','','Access-Reject','2026-11-15 02:45:49.312491',NULL),
(43,'sv_test','','Access-Reject','2026-11-15 02:45:49.313761',NULL),
(44,'sv_test','','Access-Reject','2026-11-15 02:45:49.317687',NULL),
(45,'sv_test','','Access-Reject','2026-11-15 02:45:49.319673',NULL),
(46,'sv_test','','Access-Reject','2026-11-15 02:45:49.321876',NULL),
(47,'sv_vinh','','Access-Reject','2026-11-15 02:46:53.924781',NULL),
(48,'sv_vinh','','Access-Reject','2026-11-15 02:46:55.942020',NULL),
(49,'sv_vinh','','Access-Reject','2026-11-15 02:46:57.962687',NULL),
(50,'sv_vinh','','Access-Reject','2026-11-15 02:46:59.978251',NULL),
(51,'sv_vinh','','Access-Reject','2026-11-15 02:47:02.001811',NULL),
(52,'sv_vinh','','Access-Reject','2026-11-15 02:48:23.931509',NULL),
(53,'sv_vinh','','Access-Reject','2026-11-15 02:48:25.950931',NULL),
(54,'sv_vinh','','Access-Reject','2026-11-15 02:48:27.956502',NULL),
(55,'sv_vinh','','Access-Reject','2026-11-15 02:48:29.963113',NULL),
(56,'sv_vinh','','Access-Reject','2026-11-15 02:48:31.978740',NULL),
(57,'sv_vinh','','Access-Reject','2026-11-15 02:48:33.984147',NULL),
(58,'sv_an','','Access-Reject','2026-11-15 03:02:11.770836',NULL),
(59,'gv_nguyen','','Access-Reject','2026-11-15 03:02:12.788994',NULL),
(60,'admin01','','Access-Reject','2026-11-15 03:02:13.795663',NULL),
(61,'sv_an','','Access-Reject','2026-11-15 03:02:14.811474',NULL),
(62,'sv_an','','Access-Reject','2026-11-15 03:02:44.276230',NULL),
(63,'sv_an','','Access-Accept','2026-11-15 03:04:42.224845',NULL),
(64,'gv_nguyen','','Access-Accept','2026-11-15 03:04:42.238046',NULL),
(65,'admin01','','Access-Accept','2026-11-15 03:04:42.245166',NULL),
(66,'sv_an','','Access-Reject','2026-11-15 03:04:42.251755',NULL),
(67,'user_khong_co','','Access-Reject','2026-11-15 03:04:43.255804',NULL),
(68,'sv_an','','Access-Accept','2026-11-15 03:15:34.543279',NULL),
(69,'sv_an','','Access-Accept','2026-11-15 03:17:04.099020',NULL),
(70,'sv_an','','Access-Accept','2026-11-15 03:17:15.801329',NULL),
(71,'sv_an','','Access-Accept','2026-11-15 03:17:30.310546',NULL),
(72,'sv_vinh','','Access-Reject','2026-11-15 03:43:32.999909',NULL),
(73,'sv_vinh','','Access-Reject','2026-11-15 03:43:35.021187',NULL),
(74,'sv_vinh','','Access-Reject','2026-11-15 03:43:37.052630',NULL),
(75,'sv_vinh','','Access-Reject','2026-11-15 03:49:49.302649',NULL),
(76,'sv_vinh','','Access-Reject','2026-11-15 03:49:51.317713',NULL),
(77,'sv_vinh','','Access-Reject','2026-11-15 03:49:53.345630',NULL),
(78,'sv_vinh','','Access-Accept','2026-11-15 03:49:55.358572',NULL),
(79,'sv_vinh','','Access-Accept','2026-11-15 03:49:55.406192',NULL),
(80,'sv_vinh','','Access-Reject','2026-11-15 03:56:31.479729',NULL),
(81,'sv_vinh','','Access-Reject','2026-11-15 03:56:33.508591',NULL),
(82,'sv_vinh','','Access-Reject','2026-11-15 03:56:35.534254',NULL),
(83,'sv_vinh','','Access-Accept','2026-11-15 03:56:37.558839',NULL),
(84,'sv_vinh','','Access-Accept','2026-11-15 03:56:37.570645',NULL),
(85,'sv_an','','Access-Accept','2026-11-15 03:56:46.505590',NULL),
(86,'sv_an','','Access-Reject','2026-11-15 03:56:49.952175',NULL),
(87,'sv_vinh','','Access-Reject','2026-11-15 04:07:00.739483',NULL),
(88,'sv_vinh','','Access-Reject','2026-11-15 04:07:02.745218',NULL),
(89,'sv_vinh','','Access-Reject','2026-11-15 04:07:04.755684',NULL),
(90,'sv_vinh','','Access-Accept','2026-11-15 04:07:06.774528',NULL),
(91,'sv_vinh','','Access-Accept','2026-11-15 04:07:06.814754',NULL),
(92,'sv_vinh','','Access-Reject','2026-11-15 04:07:36.140183',NULL),
(93,'sv_vinh','','Access-Reject','2026-11-15 04:07:38.170144',NULL),
(94,'sv_vinh','','Access-Reject','2026-11-15 04:07:40.191442',NULL),
(95,'sv_vinh','','Access-Reject','2026-11-15 04:07:42.208139',NULL),
(96,'sv_vinh','','Access-Reject','2026-11-15 04:07:44.224583',NULL),
(97,'sv_vinh','','Access-Reject','2026-11-15 04:07:46.243292',NULL),
(98,'sv_vinh','','Access-Reject','2026-11-15 04:07:48.258383',NULL),
(99,'sv_vinh','','Access-Reject','2026-11-15 04:07:50.269591',NULL),
(100,'sv_vinh','','Access-Reject','2026-11-15 04:07:52.280765',NULL),
(101,'sv_vinh','','Access-Reject','2026-11-15 04:07:54.292919',NULL),
(102,'sv_vinh','','Access-Reject','2026-11-15 04:07:56.295383',NULL),
(103,'sv_vinh','','Access-Reject','2026-11-15 04:07:58.306258',NULL),
(104,'sv_vinh','','Access-Reject','2026-11-15 04:08:00.320419',NULL),
(105,'sv_vinh','','Access-Reject','2026-11-15 04:08:02.325371',NULL),
(106,'sv_vinh','','Access-Reject','2026-11-15 04:08:04.334228',NULL),
(107,'sv_vinh','','Access-Reject','2026-11-15 04:08:06.347862',NULL),
(108,'sv_an','','Access-Accept','2026-11-15 05:47:25.276605',NULL),
(109,'gv_nguyen','','Access-Accept','2026-11-15 05:47:25.333337',NULL),
(110,'admin01','','Access-Accept','2026-11-15 05:47:25.341806',NULL),
(111,'sv_an','','Access-Reject','2026-11-15 05:47:25.349363',NULL),
(112,'user_khong_co','','Access-Reject','2026-11-15 05:47:26.362976',NULL),
(113,'sv_vinh','','Access-Reject','2026-11-15 09:16:57.832653',NULL),
(114,'sv_vinh','','Access-Reject','2026-11-15 09:16:59.869560',NULL),
(115,'sv_vinh','','Access-Reject','2026-11-15 09:17:01.897843',NULL),
(116,'sv_vinh','','Access-Accept','2026-11-15 09:17:03.916449',NULL),
(117,'sv_vinh','','Access-Accept','2026-11-15 09:17:03.952142',NULL),
(118,'sv_vinh','','Access-Reject','2026-11-15 09:17:28.098662',NULL),
(119,'sv_vinh','','Access-Reject','2026-11-15 09:17:30.114902',NULL),
(120,'sv_vinh','','Access-Reject','2026-11-15 09:17:32.122573',NULL),
(121,'sv_vinh','','Access-Accept','2026-11-15 09:17:34.132367',NULL),
(122,'sv_vinh','','Access-Accept','2026-11-15 09:17:34.146581',NULL),
(123,'sv_vinh','','Access-Reject','2026-11-15 10:19:41.167401',NULL),
(124,'sv_vinh','','Access-Reject','2026-11-15 10:19:43.180924',NULL),
(125,'sv_vinh','','Access-Reject','2026-11-15 10:19:45.194431',NULL),
(126,'sv_vinh','','Access-Reject','2026-11-15 10:19:47.206090',NULL),
(127,'sv_vinh','','Access-Reject','2026-11-15 10:19:49.226929',NULL),
(128,'sv_vinh','','Access-Reject','2026-11-15 10:19:51.252616',NULL),
(129,'sv_vinh','','Access-Reject','2026-11-15 10:19:53.263882',NULL),
(130,'sv_vinh','','Access-Reject','2026-11-15 10:19:55.289169',NULL),
(131,'sv_vinh','','Access-Reject','2026-11-15 10:19:57.307456',NULL),
(132,'sv_vinh','','Access-Reject','2026-11-15 10:19:59.323436',NULL),
(133,'sv_vinh','','Access-Reject','2026-11-15 10:20:01.349653',NULL),
(134,'sv_vinh','','Access-Reject','2026-11-15 10:20:03.373398',NULL),
(135,'sv_vinh','','Access-Reject','2026-11-15 12:33:34.506874',NULL),
(136,'sv_vinh','','Access-Reject','2026-11-15 12:33:36.538275',NULL),
(137,'sv_vinh','','Access-Reject','2026-11-15 12:33:38.558514',NULL),
(138,'sv_vinh','','Access-Reject','2026-11-15 12:33:40.574916',NULL),
(139,'sv_vinh','','Access-Reject','2026-11-15 12:33:42.595430',NULL),
(140,'sv_vinh','','Access-Reject','2026-11-15 12:33:44.612388',NULL),
(141,'sv_vinh','','Access-Reject','2026-11-15 12:33:46.642381',NULL),
(142,'sv_vinh','','Access-Reject','2026-11-15 12:33:48.654572',NULL),
(143,'sv_vinh','','Access-Reject','2026-11-15 12:33:50.672733',NULL),
(144,'sv_an','','Access-Accept','2026-11-15 12:34:19.513967',NULL),
(145,'gv_nguyen','','Access-Accept','2026-11-15 12:34:19.525454',NULL),
(146,'admin01','','Access-Accept','2026-11-15 12:34:19.534297',NULL),
(147,'sv_an','','Access-Reject','2026-11-15 12:34:19.543093',NULL),
(148,'user_khong_co','','Access-Reject','2026-11-15 12:34:20.555901',NULL),
(149,'sv_an','','Access-Accept','2026-11-15 12:42:57.927608',NULL),
(150,'gv_nguyen','','Access-Accept','2026-11-15 12:42:57.957480',NULL),
(151,'admin01','','Access-Accept','2026-11-15 12:42:57.973547',NULL),
(152,'sv_an','','Access-Reject','2026-11-15 12:42:57.984048',NULL),
(153,'user_khong_co','','Access-Reject','2026-11-15 12:42:58.990215',NULL),
(154,'sv_an','','Access-Accept','2026-11-15 12:43:05.860073',NULL),
(155,'gv_nguyen','','Access-Accept','2026-11-15 12:43:05.870872',NULL),
(156,'admin01','','Access-Accept','2026-11-15 12:43:05.881954',NULL),
(157,'sv_an','','Access-Reject','2026-11-15 12:43:05.890353',NULL),
(158,'sv_an','','Access-Accept','2026-11-15 12:43:14.615544',NULL),
(159,'sv_an','','Access-Accept','2026-11-15 12:43:21.027160',NULL),
(160,'sv_an','','Access-Accept','2026-11-15 12:43:37.202420',NULL),
(161,'gv_nguyen','','Access-Accept','2026-11-15 12:43:37.239435',NULL),
(162,'admin01','','Access-Accept','2026-11-15 12:43:37.254796',NULL),
(163,'sv_an','','Access-Reject','2026-11-15 12:43:37.265581',NULL),
(164,'user_khong_co','','Access-Reject','2026-11-15 12:43:38.277727',NULL),
(165,'sv_an','','Access-Accept','2026-11-15 12:44:10.286180',NULL),
(166,'gv_nguyen','','Access-Accept','2026-11-15 12:44:10.303415',NULL),
(167,'admin01','','Access-Accept','2026-11-15 12:44:10.315906',NULL),
(168,'sv_an','','Access-Reject','2026-11-15 12:44:10.326938',NULL),
(169,'user_khong_co','','Access-Reject','2026-11-15 12:44:11.340114',NULL),
(170,'sv_an','','Access-Accept','2026-11-15 12:44:17.429611',NULL),
(171,'sv_an','','Access-Accept','2026-11-15 12:44:36.934595',NULL),
(172,'sv_an','','Access-Accept','2026-11-15 12:45:34.685536',NULL),
(173,'gv_nguyen','','Access-Accept','2026-11-15 12:45:34.712174',NULL),
(174,'admin01','','Access-Accept','2026-11-15 12:45:34.725119',NULL),
(175,'sv_an','','Access-Reject','2026-11-15 12:45:34.734568',NULL),
(176,'user_khong_co','','Access-Reject','2026-11-15 12:45:35.764324',NULL),
(177,'sv_vinh','','Access-Reject','2026-11-15 12:47:17.119223',NULL),
(178,'sv_vinh','','Access-Reject','2026-11-15 12:47:19.135502',NULL),
(179,'sv_vinh','','Access-Reject','2026-11-15 12:47:21.156249',NULL),
(180,'sv_vinh','','Access-Reject','2026-11-15 12:47:23.186850',NULL),
(181,'sv_vinh','','Access-Reject','2026-11-15 12:47:25.206829',NULL),
(182,'sv_vinh','','Access-Reject','2026-11-15 12:47:27.226661',NULL),
(183,'sv_vinh','','Access-Reject','2026-11-15 12:47:29.242668',NULL),
(184,'sv_vinh','','Access-Reject','2026-11-15 12:47:31.258638',NULL),
(185,'sv_an','','Access-Reject','2026-11-15 13:11:27.430924',NULL),
(186,'sv_an','','Access-Accept','2026-11-15 13:11:28.438493',NULL),
(187,'sv_an','','Access-Accept','2026-11-15 13:11:28.725569',NULL),
(188,'sv_an','','Access-Accept','2026-11-15 13:12:35.372349',NULL),
(189,'gv_nguyen','','Access-Accept','2026-11-15 13:12:35.400022',NULL),
(190,'admin01','','Access-Accept','2026-11-15 13:12:35.409583',NULL),
(191,'sv_an','','Access-Reject','2026-11-15 13:12:35.418103',NULL),
(192,'user_khong_co','','Access-Reject','2026-11-15 13:12:36.422014',NULL),
(193,'sv_an','','Access-Reject','2026-11-15 13:16:07.883544',NULL),
(194,'sv_an','','Access-Accept','2026-11-15 13:16:08.887088',NULL),
(195,'sv_an','','Access-Accept','2026-11-15 13:16:09.194873',NULL),
(196,'sv_an','','Access-Reject','2026-11-15 13:28:32.081471',NULL),
(197,'sv_an','','Access-Accept','2026-11-15 13:28:33.089034',NULL),
(198,'sv_an','','Access-Accept','2026-11-15 13:28:33.442216',NULL),
(199,'sv_an','','Access-Accept','2026-11-15 13:28:38.247430',NULL),
(200,'gv_nguyen','','Access-Accept','2026-11-15 13:28:38.270980',NULL),
(201,'admin01','','Access-Accept','2026-11-15 13:28:38.282490',NULL),
(202,'sv_an','','Access-Reject','2026-11-15 13:28:38.293132',NULL),
(203,'user_khong_co','','Access-Reject','2026-11-15 13:28:39.302348',NULL),
(204,'sv_an','','Access-Reject','2026-11-15 13:42:52.401278',NULL),
(205,'sv_an','','Access-Accept','2026-11-15 13:42:53.406391',NULL),
(206,'sv_an','','Access-Accept','2026-11-15 13:42:53.666196',NULL),
(207,'sv_an','','Access-Accept','2026-11-15 14:25:11.391282',NULL),
(208,'gv_nguyen','','Access-Accept','2026-11-15 14:25:11.469748',NULL),
(209,'admin01','','Access-Accept','2026-11-15 14:25:11.492178',NULL),
(210,'sv_an','','Access-Reject','2026-11-15 14:25:11.511617',NULL),
(211,'sv_an','','Access-Accept','2026-11-15 14:25:19.123026',NULL),
(212,'gv_nguyen','','Access-Accept','2026-11-15 14:25:19.151591',NULL),
(213,'admin01','','Access-Accept','2026-11-15 14:25:19.184154',NULL),
(214,'sv_an','','Access-Reject','2026-11-15 14:25:19.208360',NULL),
(215,'user_khong_co','','Access-Reject','2026-11-15 14:25:20.217000',NULL),
(216,'sv_an','','Access-Reject','2026-11-15 14:28:03.517465',NULL),
(217,'sv_an','','Access-Accept','2026-11-15 14:28:04.524645',NULL),
(218,'sv_an','','Access-Accept','2026-11-15 14:28:04.857740',NULL),
(219,'sv_an','','Access-Accept','2026-11-16 06:25:53.135009',NULL),
(220,'gv_nguyen','','Access-Accept','2026-11-16 06:25:53.181072',NULL),
(221,'admin01','','Access-Accept','2026-11-16 06:25:53.194364',NULL),
(222,'sv_an','','Access-Reject','2026-11-16 06:25:53.204417',NULL),
(223,'sv_an','','Access-Accept','2026-11-16 06:36:50.192098',NULL),
(224,'gv_nguyen','','Access-Accept','2026-11-16 06:36:50.224009',NULL),
(225,'admin01','','Access-Accept','2026-11-16 06:36:50.238537',NULL),
(226,'sv_an','','Access-Reject','2026-11-16 06:36:50.256853',NULL),
(227,'sv_an','','Access-Accept','2026-11-16 06:37:28.708995',NULL),
(228,'gv_nguyen','','Access-Accept','2026-11-16 06:37:28.733602',NULL),
(229,'admin01','','Access-Accept','2026-11-16 06:37:28.743151',NULL),
(230,'sv_an','','Access-Reject','2026-11-16 06:37:28.761971',NULL),
(231,'user_khong_co','','Access-Reject','2026-11-16 06:37:29.766043',NULL),
(232,'sv_an','','Access-Reject','2026-11-16 06:40:13.024471',NULL),
(233,'sv_an','','Access-Accept','2026-11-16 06:40:14.037365',NULL),
(234,'sv_an','','Access-Accept','2026-11-16 06:40:14.349401',NULL),
(235,'sv_an','','Access-Accept','2026-11-16 06:44:50.197521',NULL),
(236,'gv_nguyen','','Access-Accept','2026-11-16 06:44:50.223531',NULL),
(237,'admin01','','Access-Accept','2026-11-16 06:44:50.232948',NULL),
(238,'sv_an','','Access-Reject','2026-11-16 06:44:50.249122',NULL),
(239,'sv_an','','Access-Accept','2026-11-16 06:45:11.515654',NULL),
(240,'gv_nguyen','','Access-Accept','2026-11-16 06:45:11.535390',NULL),
(241,'admin01','','Access-Accept','2026-11-16 06:45:11.543745',NULL),
(242,'sv_an','','Access-Reject','2026-11-16 06:45:11.551127',NULL),
(243,'user_khong_co','','Access-Reject','2026-11-16 06:45:12.603449',NULL),
(244,'sv_an','','Access-Accept','2026-11-16 18:46:10.363881',NULL),
(245,'gv_nguyen','','Access-Accept','2026-11-16 18:46:10.471045',NULL),
(246,'admin01','','Access-Accept','2026-11-16 18:46:10.482114',NULL),
(247,'sv_an','','Access-Reject','2026-11-16 18:46:10.493954',NULL),
(248,'sv_an','','Access-Accept','2026-11-16 18:46:25.994428',NULL),
(249,'gv_nguyen','','Access-Accept','2026-11-16 18:46:26.043481',NULL),
(250,'admin01','','Access-Accept','2026-11-16 18:46:26.055517',NULL),
(251,'sv_an','','Access-Reject','2026-11-16 18:46:26.064657',NULL),
(252,'user_khong_co','','Access-Reject','2026-11-16 18:46:27.070972',NULL),
(253,'sv_an','','Access-Accept','2026-11-16 18:57:11.101156',NULL),
(254,'gv_nguyen','','Access-Accept','2026-11-16 18:57:11.127428',NULL),
(255,'admin01','','Access-Accept','2026-11-16 18:57:11.139741',NULL),
(256,'sv_an','','Access-Reject','2026-11-16 18:57:11.148118',NULL),
(257,'sv_an','','Access-Accept','2026-11-16 18:57:46.058194',NULL),
(258,'gv_nguyen','','Access-Accept','2026-11-16 18:57:46.085763',NULL),
(259,'admin01','','Access-Accept','2026-11-16 18:57:46.095827',NULL),
(260,'sv_an','','Access-Reject','2026-11-16 18:57:46.104257',NULL),
(261,'user_khong_co','','Access-Reject','2026-11-16 18:57:47.125139',NULL);
/*!40000 ALTER TABLE `radpostauth` ENABLE KEYS */;
UNLOCK TABLES;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_radpostauth_no_update BEFORE UPDATE ON radpostauth FOR EACH ROW SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FORENSIC INTEGRITY VIOLATION: radpostauth is strictly append-only. UPDATE is prohibited.' 
*/;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;
/*!50003 SET @saved_cs_client      = @@character_set_client */ ;
/*!50003 SET @saved_cs_results     = @@character_set_results */ ;
/*!50003 SET @saved_col_connection = @@collation_connection */ ;
/*!50003 SET character_set_client  = utf8mb3 */ ;
/*!50003 SET character_set_results = utf8mb3 */ ;
/*!50003 SET collation_connection  = utf8mb3_general_ci */ ;
/*!50003 SET @saved_sql_mode       = @@sql_mode */ ;
/*!50003 SET sql_mode              = 'STRICT_TRANS_TABLES,ERROR_FOR_DIVISION_BY_ZERO,NO_AUTO_CREATE_USER,NO_ENGINE_SUBSTITUTION' */ ;
DELIMITER ;;
/*!50003 CREATE*/ /*!50017 DEFINER=`root`@`localhost`*/ /*!50003 TRIGGER trg_radpostauth_no_delete BEFORE DELETE ON radpostauth FOR EACH ROW SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'FORENSIC INTEGRITY VIOLATION: radpostauth is strictly append-only. DELETE is prohibited.' 
*/;;
DELIMITER ;
/*!50003 SET sql_mode              = @saved_sql_mode */ ;
/*!50003 SET character_set_client  = @saved_cs_client */ ;
/*!50003 SET character_set_results = @saved_cs_results */ ;
/*!50003 SET collation_connection  = @saved_col_connection */ ;

--
-- Table structure for table `radreply`
--

DROP TABLE IF EXISTS `radreply`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `radreply` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(64) NOT NULL DEFAULT '',
  `attribute` varchar(64) NOT NULL DEFAULT '',
  `op` char(2) NOT NULL DEFAULT '=',
  `value` varchar(253) NOT NULL DEFAULT '',
  PRIMARY KEY (`id`),
  KEY `username` (`username`(32))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `radreply`
--

LOCK TABLES `radreply` WRITE;
/*!40000 ALTER TABLE `radreply` DISABLE KEYS */;
/*!40000 ALTER TABLE `radreply` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `radusergroup`
--

DROP TABLE IF EXISTS `radusergroup`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `radusergroup` (
  `id` int(11) unsigned NOT NULL AUTO_INCREMENT,
  `username` varchar(64) NOT NULL DEFAULT '',
  `groupname` varchar(64) NOT NULL DEFAULT '',
  `priority` int(11) NOT NULL DEFAULT 1,
  PRIMARY KEY (`id`),
  KEY `username` (`username`(32))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `radusergroup`
--

LOCK TABLES `radusergroup` WRITE;
/*!40000 ALTER TABLE `radusergroup` DISABLE KEYS */;
/*!40000 ALTER TABLE `radusergroup` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sso_auth_codes`
--

DROP TABLE IF EXISTS `sso_auth_codes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sso_auth_codes` (
  `code` varchar(64) NOT NULL,
  `client_id` varchar(64) NOT NULL,
  `username` varchar(64) NOT NULL,
  `redirect_uri` varchar(255) NOT NULL,
  `expires_at` datetime NOT NULL,
  `code_challenge` varchar(128) DEFAULT NULL,
  `code_challenge_method` varchar(10) DEFAULT NULL,
  `nonce` varchar(128) DEFAULT NULL,
  PRIMARY KEY (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sso_auth_codes`
--

LOCK TABLES `sso_auth_codes` WRITE;
/*!40000 ALTER TABLE `sso_auth_codes` DISABLE KEYS */;
INSERT INTO `sso_auth_codes` VALUES
('2xNyKSSgVmDxHCFiDEoFUpEZGxmeZCUJ485XElhGY5s','qldt_lms','admin','http://qldt.ptit.edu.vn/sso/callback','2026-11-15 14:33:13','gUweJWmC7LtAhIbmOaubGJNGmhVAcAfYaoPXu_9szfc','S256','541efc8147f8e28e849d45ebb9637a2f'),
('4h06kPBtSiwSWpRX_Kdwt6N_HktyugDGGZLAdF1xWZA','qldt_lms','admin','http://qldt.ptit.edu.vn/sso/callback','2026-11-15 04:00:27','e9Yu5-os8VgO09b_rTKKVEwWn-nGUG4fgZxIPn6xlEI','S256','a08c143f7b7cd83e8629eb4925b76ace'),
('5Pq4DU7CHePVZQq7_eF1L-hcp5EgreMsCSTnz4ASgxM','qldt_lms','admin','http://qldt.ptit.edu.vn/sso/callback','2026-11-15 03:47:48','RexzOOhDY5N-Cg_FKBhOhuPt7J45kOIUwX5ndk77XVw','S256','ff3d74883942ff475750436acaf8b311'),
('6n7osA0CZhHy_RmtnM1gTVVgnnuinAk9a0Fgca72Mfs','qldt_lms','admin','http://qldt.ptit.edu.vn/sso/callback','2026-11-16 06:44:03','zSOLGdtEwViMLIdyKxt5kYQ1DtFLeMxlKkyTppsRY3k','S256','e9125df03b74f74c537f7c8a4e4641c0'),
('A2asImtysO5LIZMbrW5ZwcsGzv-iaxDuuHjmwX0PzMw','qldt_lms','admin','http://qldt.ptit.edu.vn/sso/callback','2026-11-15 04:00:27','e9Yu5-os8VgO09b_rTKKVEwWn-nGUG4fgZxIPn6xlEI','S256','a08c143f7b7cd83e8629eb4925b76ace'),
('ai-tz30ZUbqtA7rw4vhbym5rIzHCgkYy2el6ol7RRMU','qldt_lms','admin','http://qldt.ptit.edu.vn/sso/callback','2026-11-15 11:46:20','atLx2pcs1jCWFFlUXTp5nbhWQRBMLN1VHwSD21_yAAA','S256','8ed09ba37cd3328c23b18ce3880fe68e'),
('dv4J9mRnw-9ODPyLOpYEocUw9CKnq2OqAiPjzRB9w8g','qldt_lms','admin','http://qldt.ptit.edu.vn/sso/callback','2026-11-15 13:19:39','F9gir8yhZtWf4qErg_VqD2Wp-mFBpaD30E9lkvXPXoQ','S256','934881a12edbf288b636e8bfc42d51a9'),
('EeWeJc2UHV3MsiM3dpMVCz9zIweizSmdfbRcCe5SG3s','qldt_lms','admin','http://qldt.ptit.edu.vn/sso/callback','2026-11-15 13:19:39','F9gir8yhZtWf4qErg_VqD2Wp-mFBpaD30E9lkvXPXoQ','S256','934881a12edbf288b636e8bfc42d51a9'),
('EZnIEocvEG4mL1AszVdrqWEtB4fkiOi7YrtxfTC7Vxs','qldt_lms','admin','http://qldt.ptit.edu.vn/sso/callback','2026-11-15 06:16:15','eJmUlVb0gVXxonamxtU_s4zibqF2MNx3xm6EEBh4Tvk','S256','a7c654fc28ec6b7492dabbc026d43bf4'),
('iiC4xGPh6PGWASbc35DU8A9n-pyEGc03wDgbeqD4j6g','qldt_lms','admin','http://qldt.ptit.edu.vn/sso/callback','2026-11-15 03:47:48','RexzOOhDY5N-Cg_FKBhOhuPt7J45kOIUwX5ndk77XVw','S256','ff3d74883942ff475750436acaf8b311'),
('iU848BMSI2_xReJK_Id7-mZAsCopvH05RL2h1qc1HrM','qldt_lms','admin','http://qldt.ptit.edu.vn/sso/callback','2026-11-15 06:16:15','eJmUlVb0gVXxonamxtU_s4zibqF2MNx3xm6EEBh4Tvk','S256','a7c654fc28ec6b7492dabbc026d43bf4'),
('L4S_LNKJEWftwQ_s-j4UaEiAn-_kZcpEfhL_7Oybmgo','qldt_lms','admin','http://qldt.ptit.edu.vn/sso/callback','2026-11-15 12:49:56','HUIfQI4s-_Phax8AoUUOwJ_mq8i_TkUWki4ZBXOl2h4','S256','ced29a44237ec3bce69e5ca3347363e2'),
('LfQnnBcCBiWDwPEZyVMqmvXt3fKJitxtKSGN5vMmtr0','qldt_lms','admin','http://qldt.ptit.edu.vn/sso/callback','2026-11-15 03:48:02','LL4MZBFQP3FrmbUVdUq0Kh6Co-GJMxD9NMuO_UR45jo','S256','767714b618571f7eeb8db5ae6c4f74e5'),
('lQP7wlRpS2_oc6k1GoO5BOPFGkQGhT6OM24REYEBUUY','qldt_lms','admin','http://qldt.ptit.edu.vn/sso/callback','2026-11-15 10:13:01','Zqpb1nmo631Qy8LyE-B6W39JeaHP86wEh0ItoToOmQU','S256','70c721eaeec25f114fa5e52e0dd46116'),
('nDdueerT92vtR1Cvp2VmpJJyADTQmnKbskSz1pW1Avc','qldt_lms','admin','http://qldt.ptit.edu.vn/sso/callback','2026-11-15 03:48:02','LL4MZBFQP3FrmbUVdUq0Kh6Co-GJMxD9NMuO_UR45jo','S256','767714b618571f7eeb8db5ae6c4f74e5'),
('nomIak-fycAcbJDloMeoEURdEtDoW-0i7O1s-eNpCFY','qldt_lms','admin','http://qldt.ptit.edu.vn/sso/callback','2026-11-15 03:48:42','DnBN9JQpo4G8ZqAQQQS9AeZnelELfSiD-f5ueB7E_6U','S256','138d03093463acf5277d4a97ed09335f'),
('OzFUa-UECenMPd5BecZsZsEvgwbMqIm3NE8_XsCjpS8','qldt_lms','admin','http://qldt.ptit.edu.vn/sso/callback','2026-11-15 11:46:20','atLx2pcs1jCWFFlUXTp5nbhWQRBMLN1VHwSD21_yAAA','S256','8ed09ba37cd3328c23b18ce3880fe68e'),
('PX1plQ_VslbHPNRx7k1t3gOT1I4EY7HBw2cP3vjaBXA','qldt_lms','admin','http://qldt.ptit.edu.vn/sso/callback','2026-11-15 09:14:22','-Z12UfVZG498L-Gc3tzSvdNkvpT3RC2UgWz-NBK4XR4','S256','2fe393e79bc159f0f4ef2b2296235bc1'),
('r6JY4CXUH-oUoU8v5Es_XbSce-Vq9JxVOMIiSTt8RZM','qldt_lms','admin','http://qldt.ptit.edu.vn/sso/callback','2026-11-16 06:44:03','zSOLGdtEwViMLIdyKxt5kYQ1DtFLeMxlKkyTppsRY3k','S256','e9125df03b74f74c537f7c8a4e4641c0'),
('UCTTcmOOundBpqdMLZuWYC9eWwpZwA0e68hJJid_P-w','qldt_lms','admin','http://qldt.ptit.edu.vn/sso/callback','2026-11-15 03:48:42','DnBN9JQpo4G8ZqAQQQS9AeZnelELfSiD-f5ueB7E_6U','S256','138d03093463acf5277d4a97ed09335f'),
('VItYXH0cj5zEpDf_RGAiSRPIMLu2tG3yqC4Gr5ILnHo','qldt_lms','admin','http://qldt.ptit.edu.vn/sso/callback','2026-11-15 12:39:41','pQeFqS8WCBGChyXnD8wIe3PKigrfGlLNliodHcCifGI','S256','9c8138e068715cafeece4fce880c6590'),
('w1ouVgDVbNU3Au0j5aNHUKEds-1gkMOS5fDGrWJzfKw','qldt_lms','admin','http://qldt.ptit.edu.vn/sso/callback','2026-11-15 14:33:13','gUweJWmC7LtAhIbmOaubGJNGmhVAcAfYaoPXu_9szfc','S256','541efc8147f8e28e849d45ebb9637a2f'),
('WyMO4FjogCYe3mu_KUmTcgi_tEM9sph3fp6jjT90hrA','qldt_lms','admin','http://qldt.ptit.edu.vn/sso/callback','2026-11-15 12:39:41','pQeFqS8WCBGChyXnD8wIe3PKigrfGlLNliodHcCifGI','S256','9c8138e068715cafeece4fce880c6590'),
('ydiNH8fA9OJlVeiJgRzXiHAj4BVmeuuhleuulC1cZS8','qldt_lms','admin','http://qldt.ptit.edu.vn/sso/callback','2026-11-15 09:14:22','-Z12UfVZG498L-Gc3tzSvdNkvpT3RC2UgWz-NBK4XR4','S256','2fe393e79bc159f0f4ef2b2296235bc1'),
('_1Xa_UPNKoTFgPYP73gQXpvoJ1y-iMPYqsizbr0GO0c','qldt_lms','admin','http://qldt.ptit.edu.vn/sso/callback','2026-11-15 12:49:56','HUIfQI4s-_Phax8AoUUOwJ_mq8i_TkUWki4ZBXOl2h4','S256','ced29a44237ec3bce69e5ca3347363e2'),
('_lfuLle6OCO674eMLjTGsx35qxmL3zflFwLUlhikgd8','qldt_lms','admin','http://qldt.ptit.edu.vn/sso/callback','2026-11-15 10:13:01','Zqpb1nmo631Qy8LyE-B6W39JeaHP86wEh0ItoToOmQU','S256','70c721eaeec25f114fa5e52e0dd46116');
/*!40000 ALTER TABLE `sso_auth_codes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sso_client_sessions`
--

DROP TABLE IF EXISTS `sso_client_sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sso_client_sessions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `session_id` varchar(64) NOT NULL,
  `client_id` varchar(64) NOT NULL,
  `username` varchar(64) NOT NULL,
  `access_token_jti` varchar(64) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `is_active` tinyint(1) DEFAULT 1,
  `revoked_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `session_id` (`session_id`),
  KEY `client_id` (`client_id`),
  KEY `access_token_jti` (`access_token_jti`)
) ENGINE=InnoDB AUTO_INCREMENT=164 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sso_client_sessions`
--

LOCK TABLES `sso_client_sessions` WRITE;
/*!40000 ALTER TABLE `sso_client_sessions` DISABLE KEYS */;
INSERT INTO `sso_client_sessions` VALUES
(1,'09ffcdef933d','qldt_lms','admin','bc41744343178105376e81f48a743311','2026-11-15 06:08:53',1,NULL),
(2,'09ffcdef933d','elibrary','admin','e6aa49eaa0d5f1afba1c72bbe4fc8409','2026-11-15 06:08:53',1,NULL),
(3,'09ffcdef933d','vpn_portal','admin','98ad8a75fada2fb77da65299a4e4f822','2026-11-15 06:08:53',1,NULL),
(4,'09ffcdef933d','webmail','admin','6e6ce367eb94613921ab997a10112a7b','2026-11-15 06:08:53',1,NULL),
(5,'ef969335026c','qldt_lms','admin','0ae55a2572ed1f4046625ce85b5cf2cd','2026-11-15 06:09:24',1,NULL),
(6,'ef969335026c','elibrary','admin','17e2118c9cd0523fbccfb3c00d6a904c','2026-11-15 06:09:24',1,NULL),
(7,'ef969335026c','vpn_portal','admin','dc181222843d51a9145113a6fc7bec46','2026-11-15 06:09:24',1,NULL),
(8,'ef969335026c','webmail','admin','4ebe5d48b2d9bdb273bf86c56a2e54ee','2026-11-15 06:09:24',1,NULL),
(9,'213732fc66b2','qldt_lms','admin','e29ba2cb3700103cf69c32bec4ce4eda','2026-11-15 06:09:44',1,NULL),
(10,'213732fc66b2','elibrary','admin','13debf043451ceeef512712ff1595603','2026-11-15 06:09:44',1,NULL),
(11,'213732fc66b2','vpn_portal','admin','49be7823532d9d06d72ced0499c92fd8','2026-11-15 06:09:44',1,NULL),
(12,'213732fc66b2','webmail','admin','47ac6524d424842c714779de88978e37','2026-11-15 06:09:44',1,NULL),
(13,'213732fc66b2','qldt_lms','admin','7b2b16d774c1bf6ff9c82c769925bc15','2026-11-15 06:09:44',1,NULL),
(14,'05cf074b8d07','qldt_lms','admin','c787dc699d5328d5bc6ff5d609cb9bf4','2026-11-15 06:10:45',0,'2026-11-15 06:10:46'),
(15,'05cf074b8d07','elibrary','admin','8bf1fcab4d11919feee95f45113b6db3','2026-11-15 06:10:45',0,'2026-11-15 06:10:46'),
(16,'05cf074b8d07','vpn_portal','admin','d170cecd3b4a7596c2498ef30deb64e5','2026-11-15 06:10:46',0,'2026-11-15 06:10:46'),
(17,'05cf074b8d07','webmail','admin','c833a84491dffe750dd5983b4499e07b','2026-11-15 06:10:46',0,'2026-11-15 06:10:46'),
(18,'05cf074b8d07','qldt_lms','admin','fe29818986be61be9d4fd7960d91b27a','2026-11-15 06:10:46',0,'2026-11-15 06:10:46'),
(19,'c9a7bcea8005','qldt_lms','admin','223b8b2e60eb9372064f26f9b3235042','2026-11-15 06:11:05',0,'2026-11-15 06:11:05'),
(20,'c9a7bcea8005','elibrary','admin','2564a09c8e69140e069a8d9233660250','2026-11-15 06:11:05',0,'2026-11-15 06:11:05'),
(21,'c9a7bcea8005','vpn_portal','admin','96ee5bee5968a933d49a7caddb12de18','2026-11-15 06:11:05',0,'2026-11-15 06:11:05'),
(22,'c9a7bcea8005','webmail','admin','95414f893e6c9abb5431177c0f68cf74','2026-11-15 06:11:05',0,'2026-11-15 06:11:05'),
(23,'c9a7bcea8005','qldt_lms','admin','ee984ca97ddc6987db5350b07f0e8471','2026-11-15 06:11:05',0,'2026-11-15 06:11:05'),
(24,'381299073251','qldt_lms','admin','5fd2d9503707c33d050cedf07f71b4dd','2026-11-15 06:11:15',1,NULL),
(25,'345175c981f0','qldt_lms','admin','cc59322de7348bba70a864d3cc61f9af','2026-11-15 08:47:08',0,'2026-11-15 08:47:47'),
(26,'24904983cad9','qldt_lms','sv_vinh','18ecc8db9d00ec2ebae3e81359dc424d','2026-11-15 09:09:15',0,'2026-11-15 09:09:15'),
(27,'24904983cad9','elibrary','sv_vinh','aec5cab76f759e0349bf99d1e4d5c732','2026-11-15 09:09:15',0,'2026-11-15 09:09:15'),
(28,'24904983cad9','vpn_portal','sv_vinh','7f64b68fb800d6e4159ae1db3b6615db','2026-11-15 09:09:15',0,'2026-11-15 09:09:15'),
(29,'24904983cad9','webmail','sv_vinh','c5defe7a0ebb97cf18ffdbe88f1cf760','2026-11-15 09:09:15',0,'2026-11-15 09:09:15'),
(30,'489041a57930','qldt_lms','admin','bf595478732f3e195570afd404bf6965','2026-11-15 09:09:23',1,NULL),
(31,'0a2b71192636','qldt_lms','admin','18542d94c8498667d042a454e45e3413','2026-11-15 09:09:31',0,'2026-11-15 09:09:31'),
(32,'0a2b71192636','elibrary','admin','0c09098dd3104e1abf716731c93a0b21','2026-11-15 09:09:31',0,'2026-11-15 09:09:31'),
(33,'0a2b71192636','vpn_portal','admin','98b7421a71c2d0054d6fcdba31d245d4','2026-11-15 09:09:31',0,'2026-11-15 09:09:31'),
(34,'0a2b71192636','webmail','admin','80de6ae19e0d127577660613ac33d2b8','2026-11-15 09:09:31',0,'2026-11-15 09:09:31'),
(35,'0a2b71192636','qldt_lms','admin','d1f242fa7335ee579e9dba8723e34886','2026-11-15 09:09:31',0,'2026-11-15 09:09:31'),
(36,'9cb28f6fd8ce','qldt_lms','sv_vinh','97062fb9d59af1cdb66be71b39d43782','2026-11-15 09:12:44',0,'2026-11-15 10:04:20'),
(37,'614d1b7b9c9a','qldt_lms','sv_vinh','6da3c612c155169a9d7854cf0ce67bba','2026-11-15 09:14:58',0,'2026-11-15 09:15:26'),
(38,'614d1b7b9c9a','elibrary','sv_vinh','f8f30d3dd321b4b7ffb45141fc046ed6','2026-11-15 09:15:18',0,'2026-11-15 09:15:26'),
(39,'4acfe80e253d','qldt_lms','sv_vinh','bb695100216b2ee0bae077b417f74609','2026-11-15 09:18:38',0,'2026-11-15 10:04:20'),
(40,'4acfe80e253d','elibrary','sv_vinh','7865487e9bd0864d764770ef7756a105','2026-11-15 09:18:48',0,'2026-11-15 10:04:20'),
(41,'4acfe80e253d','qldt_lms','sv_vinh','2b75ec77e3151ef92f675d874e1def94','2026-11-15 09:19:53',0,'2026-11-15 10:04:20'),
(42,'c430c6d1106e','qldt_lms','sv_binh','f5d6828a381351c39b25c78357cce465','2026-11-15 10:07:09',0,'2026-11-15 10:07:09'),
(43,'196c5be9925f','qldt_lms','sv_binh','e4862620b41f4e2758a4ea6f9838695a','2026-11-15 10:07:09',0,'2026-11-15 10:08:15'),
(44,'8af263384b36','qldt_lms','sv_vinh','af46a56246d9bdffcf16acf9323281b3','2026-11-15 10:07:54',0,'2026-11-15 10:07:55'),
(45,'8af263384b36','elibrary','sv_vinh','9c15b4d5887c6659e744a973e34dc467','2026-11-15 10:07:54',0,'2026-11-15 10:07:55'),
(46,'8af263384b36','vpn_portal','sv_vinh','daf2b15842252b395a07b50e29bdb60c','2026-11-15 10:07:54',0,'2026-11-15 10:07:55'),
(47,'8af263384b36','webmail','sv_vinh','ea30ef4f257ffa4380f0c9ac8d002be1','2026-11-15 10:07:55',0,'2026-11-15 10:07:55'),
(48,'ba54ea64acf9','qldt_lms','admin','e85947285c2d515aa07e4f6978128cd2','2026-11-15 10:08:02',1,NULL),
(49,'4f4a9afdfd8f','qldt_lms','admin','d03d4c20db521e7cd94108176abb682d','2026-11-15 10:08:08',0,'2026-11-15 10:08:08'),
(50,'4f4a9afdfd8f','elibrary','admin','c31ddd6b8eac34ef37c24c16fa79d7fa','2026-11-15 10:08:08',0,'2026-11-15 10:08:08'),
(51,'4f4a9afdfd8f','vpn_portal','admin','73e77ca276d5b13e11c0a834fcbdab15','2026-11-15 10:08:08',0,'2026-11-15 10:08:08'),
(52,'4f4a9afdfd8f','webmail','admin','f05904e579bbefaf901b4fba2d3b1f49','2026-11-15 10:08:08',0,'2026-11-15 10:08:08'),
(53,'4f4a9afdfd8f','qldt_lms','admin','c9f67a16764bbbab5f2f9178fcc5237d','2026-11-15 10:08:08',0,'2026-11-15 10:08:08'),
(54,'226336914741','qldt_lms','sv_binh','36082b0bfd30c254efc634532d751b44','2026-11-15 10:08:15',0,'2026-11-15 10:08:15'),
(55,'a15ce64c5775','qldt_lms','sv_binh','865563f1d31d39f607da442f3754a934','2026-11-15 10:08:16',0,'2026-11-15 10:15:55'),
(56,'9cb28f6fd8ce','vpn_portal','admin','2a1a6f07d01fb774f01945a4bfef73f3','2026-11-15 10:12:27',0,'2026-11-15 12:21:56'),
(57,'1cab062f96f7','vpn_portal','sv_vinh','3f31011e16fa3939caea24892b5a4339','2026-11-15 10:13:04',0,'2026-11-15 10:13:08'),
(58,'d9fc76c6f395','qldt_lms','sv_binh','bb811783a6c2bb6ca1ad1f62b9c3865d','2026-11-15 10:15:55',0,'2026-11-15 10:15:55'),
(59,'695587d07689','qldt_lms','sv_binh','570b6e71ad5027f94d74b4bb3a1562f3','2026-11-15 10:15:56',0,'2026-11-15 11:41:08'),
(60,'1cab062f96f7','qldt_lms','sv_vinh','7c5127c39c144f0997b1f7395f99ce79','2026-11-15 10:17:05',0,'2026-11-15 10:18:05'),
(61,'9e0d8edbb9ae','qldt_lms','sv_tuananh','c8c4ad962123e9321fd3fc44536faaa1','2026-11-15 11:38:25',1,NULL),
(62,'8f55274cac52','qldt_lms','sv_tuananh','1e8748acfbd14e117089764ef9bb1e58','2026-11-15 11:40:44',1,NULL),
(63,'9b2dd412fd7e','qldt_lms','sv_binh','111766c2e3ed43b333a15ac199dd741b','2026-11-15 11:41:07',0,'2026-11-15 11:41:08'),
(64,'ab33a06e8ce5','qldt_lms','sv_binh','cd2d258d97e9bac1adf13d6c567709b1','2026-11-15 11:41:08',0,'2026-11-15 12:34:51'),
(65,'410031792896','qldt_lms','admin','4938784f79fca2e53a2d23bf6f6c598d','2026-11-15 11:41:14',0,'2026-11-15 11:41:15'),
(66,'410031792896','elibrary','admin','ad9d1833c1692a44fb22b6e2ebcf8dd7','2026-11-15 11:41:14',0,'2026-11-15 11:41:15'),
(67,'410031792896','vpn_portal','admin','459f8854bd2d07fbffbbfb4ce93e173d','2026-11-15 11:41:15',0,'2026-11-15 11:41:15'),
(68,'410031792896','webmail','admin','b30e2abc6b7cb8e6f2d736d7622a27a8','2026-11-15 11:41:15',0,'2026-11-15 11:41:15'),
(69,'410031792896','qldt_lms','admin','7d0d7c6f4ed35bbd195e88c13b64f5eb','2026-11-15 11:41:15',0,'2026-11-15 11:41:15'),
(70,'3fb47fb2b1ea','qldt_lms','admin','d57b2687d49b2c3934fb260ba40d8eb0','2026-11-15 11:41:21',1,NULL),
(71,'28e18ad40b16','qldt_lms','sv_tuananh','78554f6b8c36f1f80aa41e3e64587b5a','2026-11-15 12:15:53',1,NULL),
(72,'a503a01c56a1','qldt_lms','sv_tuananh','e41905c81196e67f7dfcb01d7fc35892','2026-11-15 12:21:53',1,NULL),
(73,'5765ee49a7cf','qldt_lms','sv_tuananh','6eaaf2607f6aa200351f2888807bd69a','2026-11-15 12:34:34',1,NULL),
(74,'65d8351d190c','qldt_lms','admin','c84bff26b7c2e585707745d4f3a414cc','2026-11-15 12:34:41',1,NULL),
(75,'51b22760e663','qldt_lms','sv_binh','0176b0acffa6a0292dbebf9d53f8a0f3','2026-11-15 12:34:51',0,'2026-11-15 12:34:51'),
(76,'2db8d45b6fb1','qldt_lms','sv_binh','7b533a33c5b4c2e35feb0abd4334f42b','2026-11-15 12:34:52',0,'2026-11-15 12:44:44'),
(77,'07ce007c6e8d','qldt_lms','admin','4379957bd17d077a0f37d0450333b15d','2026-11-15 12:36:37',0,'2026-11-15 12:36:37'),
(78,'07ce007c6e8d','elibrary','admin','b8943062607fca744bd96c89cb67d342','2026-11-15 12:36:37',0,'2026-11-15 12:36:37'),
(79,'07ce007c6e8d','vpn_portal','admin','41455632e9787c8f73528a9fa7a3f3e4','2026-11-15 12:36:37',0,'2026-11-15 12:36:37'),
(80,'07ce007c6e8d','webmail','admin','6ebf596423d2dd94984031d153741e3d','2026-11-15 12:36:37',0,'2026-11-15 12:36:37'),
(81,'07ce007c6e8d','qldt_lms','admin','edb30fcae2d10167597be7eac3d73774','2026-11-15 12:36:37',0,'2026-11-15 12:36:37'),
(82,'9c7b4eb0bc5a','qldt_lms','sv_vinh','3c2b66a237548149084ce7c080c4089d','2026-11-15 12:40:54',0,'2026-11-15 12:40:55'),
(83,'9c7b4eb0bc5a','elibrary','sv_vinh','f4ef7a3ef664972dacabcb9c17e083ca','2026-11-15 12:40:54',0,'2026-11-15 12:40:55'),
(84,'9c7b4eb0bc5a','vpn_portal','sv_vinh','6a3699ef90bed48409d5dc5c87dce0ed','2026-11-15 12:40:55',0,'2026-11-15 12:40:55'),
(85,'9c7b4eb0bc5a','webmail','sv_vinh','2317fac7da1c49bacff019cc8d069bc3','2026-11-15 12:40:55',0,'2026-11-15 12:40:55'),
(86,'e545ac603031','qldt_lms','sv_vinh','c87254dc94fa22411d22c0319dd58b85','2026-11-15 12:41:22',0,'2026-11-15 12:41:22'),
(87,'e545ac603031','elibrary','sv_vinh','019b2ed53427fea841c62f5d3758647b','2026-11-15 12:41:22',0,'2026-11-15 12:41:22'),
(88,'e545ac603031','vpn_portal','sv_vinh','cfea728cbf2b6f063aa463c9e3ee5b3f','2026-11-15 12:41:22',0,'2026-11-15 12:41:22'),
(89,'e545ac603031','webmail','sv_vinh','b74f7164ada47e20bea449659afa0efc','2026-11-15 12:41:22',0,'2026-11-15 12:41:22'),
(90,'bdead9f8246f','qldt_lms','sv_binh','26ff49cd9f9c839eaa3ae37e8bafdaa9','2026-11-15 12:44:44',0,'2026-11-15 12:44:44'),
(91,'70bc132f1551','qldt_lms','sv_binh','2538128d113282b1bd3793411839dd8e','2026-11-15 12:44:45',0,'2026-11-15 13:13:24'),
(92,'4e3a5fa03483','qldt_lms','admin','46ef1d075b5b7f2545e91136d3a44cce','2026-11-15 12:44:49',0,'2026-11-15 12:44:50'),
(93,'4e3a5fa03483','elibrary','admin','9c5ff28a6756b1f5ca03e136f6f09116','2026-11-15 12:44:49',0,'2026-11-15 12:44:50'),
(94,'4e3a5fa03483','vpn_portal','admin','031dc6433e279411bd5ad6b42c72bde6','2026-11-15 12:44:49',0,'2026-11-15 12:44:50'),
(95,'4e3a5fa03483','webmail','admin','611e19653bf367a7538dc150b9ef6d85','2026-11-15 12:44:50',0,'2026-11-15 12:44:50'),
(96,'4e3a5fa03483','qldt_lms','admin','8b67c16bf04a4a111b7127a97e328b4d','2026-11-15 12:44:50',0,'2026-11-15 12:44:50'),
(97,'f18ce4225081','qldt_lms','admin','9c104c654735cb1f68e5a422ad6553e2','2026-11-15 12:44:57',1,NULL),
(98,'60a9b38b6d3a','qldt_lms','sv_tuananh','9f3bc6fcbee9ff7ad3db90742a8c20c6','2026-11-15 12:45:04',1,NULL),
(99,'9366a2a68691','qldt_lms','sv_vinh','03cd249f67e01a63b8d807c1d0965331','2026-11-15 12:48:47',0,'2026-11-15 12:49:20'),
(100,'9366a2a68691','elibrary','sv_vinh','fb524955c30972043351082468b64686','2026-11-15 12:48:52',0,'2026-11-15 12:49:20'),
(101,'f4121a9b2d8b','qldt_lms','sv_vinh','b871de05d642a1e9c60a502f0a5a89ab','2026-11-15 13:13:07',0,'2026-11-15 13:13:08'),
(102,'f4121a9b2d8b','elibrary','sv_vinh','3183d534a45832930b76c3cd8e3aed92','2026-11-15 13:13:07',0,'2026-11-15 13:13:08'),
(103,'f4121a9b2d8b','vpn_portal','sv_vinh','e90120b04d2c04a3398afe5dcd6a8d49','2026-11-15 13:13:07',0,'2026-11-15 13:13:08'),
(104,'f4121a9b2d8b','webmail','sv_vinh','43454d87e384930d550aa0b323378cbb','2026-11-15 13:13:07',0,'2026-11-15 13:13:08'),
(105,'8ad19b772a30','qldt_lms','sv_binh','921d1d9254f222c82b90290966cb6787','2026-11-15 13:13:24',0,'2026-11-15 13:13:24'),
(106,'f38db143f468','qldt_lms','sv_binh','9bed3d3e9e2c38a741fc256fe87d05be','2026-11-15 13:13:25',0,'2026-11-15 14:28:23'),
(107,'71c2a7e6a8fe','qldt_lms','admin','c998a604df8dfe6b06b8cd03f17f3543','2026-11-15 13:14:26',0,'2026-11-15 13:14:27'),
(108,'71c2a7e6a8fe','elibrary','admin','151b73c6c565c539e22225293f9215e7','2026-11-15 13:14:26',0,'2026-11-15 13:14:27'),
(109,'71c2a7e6a8fe','vpn_portal','admin','974df927879028f12478e01f6d5692c3','2026-11-15 13:14:26',0,'2026-11-15 13:14:27'),
(110,'71c2a7e6a8fe','webmail','admin','96f1fe41ab73eda823f81cb0ec585f6a','2026-11-15 13:14:27',0,'2026-11-15 13:14:27'),
(111,'71c2a7e6a8fe','qldt_lms','admin','9e19bd3ce3cfccd7fff5c94ab8245069','2026-11-15 13:14:27',0,'2026-11-15 13:14:27'),
(112,'e2c951b0d503','qldt_lms','admin','59de093aad9a7475aa00d5ae5501d9ee','2026-11-15 13:14:39',1,NULL),
(113,'bb1796546227','qldt_lms','sv_tuananh','9e8f44ac9e2f1b70a366e5c9c7be3ea8','2026-11-15 13:14:45',1,NULL),
(114,'9366a2a68691','webmail','meoluoi','69c7e9dfd9ef70b6b10d9297ef55b689','2026-11-15 13:32:51',0,'2026-11-15 13:40:15'),
(115,'9366a2a68691','webmail','meoluoi','db66d4606d0395c211d3d32ecbcdfe7d','2026-11-15 13:39:32',0,'2026-11-15 13:40:15'),
(116,'3f5929aecaa1','qldt_lms','admin','c5a667c5c40a92a44dbabe824f2317f1','2026-11-15 13:42:08',0,'2026-11-15 13:42:08'),
(117,'3f5929aecaa1','elibrary','admin','1ff076c7531a8a877ae1ae55a5356b77','2026-11-15 13:42:08',0,'2026-11-15 13:42:08'),
(118,'3f5929aecaa1','vpn_portal','admin','0d43c426e9920c632535d21bce4ec118','2026-11-15 13:42:08',0,'2026-11-15 13:42:08'),
(119,'3f5929aecaa1','webmail','admin','aa3e43863dc2c70671d10b39e790ddd1','2026-11-15 13:42:08',0,'2026-11-15 13:42:08'),
(120,'3f5929aecaa1','qldt_lms','admin','2affdd62f9237237ad4c6e4d3358b2f6','2026-11-15 13:42:08',0,'2026-11-15 13:42:08'),
(121,'b9f0c1344115','qldt_lms','sv_vinh','3eb2c0182ac67416372ca901ce5f78f5','2026-11-15 13:42:31',0,'2026-11-15 13:42:32'),
(122,'b9f0c1344115','elibrary','sv_vinh','e0e1dfd1904fe885ac03781a5f8d4592','2026-11-15 13:42:31',0,'2026-11-15 13:42:32'),
(123,'b9f0c1344115','vpn_portal','sv_vinh','d76f4ff71f39e3b55d750caa224d01ee','2026-11-15 13:42:31',0,'2026-11-15 13:42:32'),
(124,'b9f0c1344115','webmail','sv_vinh','4a83b99d781bb51f226ae810931615c5','2026-11-15 13:42:31',0,'2026-11-15 13:42:32'),
(125,'9366a2a68691','vpn_portal','meoluoi','b61efc27fde7c55d685672cf6e55d8bd','2026-11-15 13:44:52',1,NULL),
(126,'d2ab23e07cac','webmail','admin','a96fe4c6f38fd2ab2c2cabcb207ee0a8','2026-11-15 14:23:44',0,'2026-11-15 14:23:45'),
(127,'7b162bc893c7','webmail','admin','88c6a4256d93645da51b9fd6103c97fa','2026-11-15 14:24:41',0,'2026-11-15 14:24:41'),
(128,'efd94c093106','webmail','admin','9d271cd08dd9b34831713a545d7bd440','2026-11-15 14:25:02',1,NULL),
(129,'f9de4de54e73','qldt_lms','sv_vinh','3068c3a91772761424317fa5bda6eac4','2026-11-15 14:25:29',0,'2026-11-15 14:25:30'),
(130,'f9de4de54e73','elibrary','sv_vinh','46feadf2b60c562d5d7adc09fb80925b','2026-11-15 14:25:29',0,'2026-11-15 14:25:30'),
(131,'f9de4de54e73','vpn_portal','sv_vinh','0bbee634606686c822bce1bfd47712fe','2026-11-15 14:25:29',0,'2026-11-15 14:25:30'),
(132,'f9de4de54e73','webmail','sv_vinh','9d203b009f002823a9cc80a2262c7404','2026-11-15 14:25:29',0,'2026-11-15 14:25:30'),
(133,'1b0f10c4789a','qldt_lms','admin','0e7fceebdc065909abe78199c6c94cfc','2026-11-15 14:25:38',1,NULL),
(134,'1b0f10c4789a','elibrary','admin','12fb7a918bd81a2e2a38fb2ca40b231a','2026-11-15 14:25:38',1,NULL),
(135,'1b0f10c4789a','vpn_portal','admin','06d3426b5de434512523b7005e2c1232','2026-11-15 14:25:38',1,NULL),
(136,'1b0f10c4789a','webmail','admin','b7bb9df3c86174c9b6c6876b9e26feee','2026-11-15 14:25:38',1,NULL),
(137,'27fe1bebf0bc','qldt_lms','admin','3d0f93a102d330972678bfa40626a0bc','2026-11-15 14:26:21',1,NULL),
(138,'27fe1bebf0bc','elibrary','admin','b9d0f5bf8d8662e5d94b710c0b01a82c','2026-11-15 14:26:21',1,NULL),
(139,'27fe1bebf0bc','vpn_portal','admin','a1381469ff2a9fb30717913653b0e0cb','2026-11-15 14:26:21',1,NULL),
(140,'27fe1bebf0bc','webmail','admin','489ec18a4df77e5375f47c60ddf23b08','2026-11-15 14:26:21',1,NULL),
(141,'4919a7c24152','webmail','admin','d0a18439da8dfb1ba03ad77394b2eb24','2026-11-15 14:26:48',1,NULL),
(142,'cc8f59947f36','qldt_lms','admin','8d3bd9791bd67e8cf854b4701734d359','2026-11-15 14:27:55',0,'2026-11-15 14:27:55'),
(143,'cc8f59947f36','elibrary','admin','1db4b1b4ed89327b15c50e3aaa7556b8','2026-11-15 14:27:55',0,'2026-11-15 14:27:55'),
(144,'cc8f59947f36','vpn_portal','admin','504ef581cf68909e35f5386dad37e2d9','2026-11-15 14:27:55',0,'2026-11-15 14:27:55'),
(145,'cc8f59947f36','webmail','admin','ad8a38761f158baa9b97fe8566b71c12','2026-11-15 14:27:55',0,'2026-11-15 14:27:55'),
(146,'cc8f59947f36','qldt_lms','admin','3e7155c256b8b40f3c0849fbe1af41ab','2026-11-15 14:27:55',0,'2026-11-15 14:27:55'),
(147,'11cd4b0830bd','qldt_lms','admin','11dc48e84fe86a570ec9a265be3ede79','2026-11-15 14:28:14',1,NULL),
(148,'8a5a04aec9e2','qldt_lms','sv_binh','49e9b22e85a76bf93026516e563b0a9d','2026-11-15 14:28:23',0,'2026-11-15 14:28:23'),
(149,'9b0051916a62','qldt_lms','sv_binh','12b4603e05422b41e270a771b8e5da1e','2026-11-15 14:28:24',0,'2026-11-16 06:39:39'),
(150,'31919914a6c2','qldt_lms','sv_tuananh','3702f30a9007adad14efdb631af6e3ac','2026-11-15 14:28:34',1,NULL),
(151,'46d659797dae','qldt_lms','sv_vinh','c7fd78d2c203e44655fa49274155c450','2026-11-16 06:38:08',0,'2026-11-16 06:38:10'),
(152,'46d659797dae','elibrary','sv_vinh','731e1089e7f6c7cb2b5935fb381ce504','2026-11-16 06:38:08',0,'2026-11-16 06:38:10'),
(153,'46d659797dae','vpn_portal','sv_vinh','f396750bf8006d1e250c8e1642fbb930','2026-11-16 06:38:09',0,'2026-11-16 06:38:10'),
(154,'46d659797dae','webmail','sv_vinh','b46b65b713435f01427a49230d715614','2026-11-16 06:38:09',0,'2026-11-16 06:38:10'),
(155,'e75e52d46cab','qldt_lms','admin','32be3a5abba8a4e6ef7638027bea0e1b','2026-11-16 06:38:39',0,'2026-11-16 06:38:39'),
(156,'e75e52d46cab','elibrary','admin','c8155b48db02d19b5946ab24e0a5cd0d','2026-11-16 06:38:39',0,'2026-11-16 06:38:39'),
(157,'e75e52d46cab','vpn_portal','admin','414a527f88038c8ecdc27c3af6a07a06','2026-11-16 06:38:39',0,'2026-11-16 06:38:39'),
(158,'e75e52d46cab','webmail','admin','a43ce3828b3c4d84c13980361a07579b','2026-11-16 06:38:39',0,'2026-11-16 06:38:39'),
(159,'e75e52d46cab','qldt_lms','admin','92976cdc7d1c147cf397988936379818','2026-11-16 06:38:39',0,'2026-11-16 06:38:39'),
(160,'5a9cf701a6fc','qldt_lms','admin','8dad331092cefc35bc2972754ec1e110','2026-11-16 06:39:03',1,NULL),
(161,'e127a6683abf','qldt_lms','sv_binh','c8e5c8ef32dc3ea5dbe8556378fdf077','2026-11-16 06:39:39',0,'2026-11-16 06:39:39'),
(162,'92e4af55b7fd','qldt_lms','sv_binh','62badfac9f27b7bbc8b23ebe0088cfa9','2026-11-16 06:39:39',1,NULL),
(163,'a650312e5061','qldt_lms','sv_tuananh','e729fd73bdec72cfa0d3417e347ef2a0','2026-11-16 06:39:56',1,NULL);
/*!40000 ALTER TABLE `sso_client_sessions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sso_clients`
--

DROP TABLE IF EXISTS `sso_clients`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sso_clients` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `client_id` varchar(64) NOT NULL,
  `client_name` varchar(128) NOT NULL,
  `client_secret` varchar(255) NOT NULL,
  `redirect_uri` varchar(255) NOT NULL,
  `description` varchar(255) DEFAULT '',
  `icon_class` varchar(64) DEFAULT 'fa-solid fa-cube',
  `is_active` tinyint(1) DEFAULT 1,
  `created_at` datetime DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `client_id` (`client_id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sso_clients`
--

LOCK TABLES `sso_clients` WRITE;
/*!40000 ALTER TABLE `sso_clients` DISABLE KEYS */;
INSERT INTO `sso_clients` VALUES
(1,'qldt_lms','Cổng Đào tạo & Quản lý Học tập (QLĐT / LMS)','pbkdf2:sha256:100000$2fb521182a218097dee0a2f6113c8602$d62b4288a8bf5133e8b2c3cea50d9833d499bbadbcadaf97e74ef99f14d4b135','http://localhost:5000/sso/callback,http://qldt.ptit.edu.vn/sso/callback','Hệ thống quản lý điểm thi, thời khóa biểu và lớp học trực tuyến LMS','fa-solid fa-graduation-cap',1,'2026-11-14 12:22:48'),
(2,'elibrary','Thư viện Số & Học liệu PTIT (E-Library)','pbkdf2:sha256:100000$168c66db0f033aba39fca9db45866d55$327470c4cfa4f49129339b5ba94d6f569404dc062a99776dbae63512713c5d7a','http://localhost:5000/sso/callback,http://lib.ptit.edu.vn/sso/callback','Cổng tra cứu tài liệu học tập, giáo trình chuyên ngành ATTT','fa-solid fa-book-bookmark',1,'2026-11-14 12:22:48'),
(3,'vpn_portal','Cổng Truy cập Từ xa (Zero-Trust VPN Gateway)','pbkdf2:sha256:100000$5ce7e5243c5de6e7b01bc4847f560895$1bc08e0f0b4e81011036fd6efeb7c9dfcf635b430461357883b7b45fbaacba02','http://localhost:5000/sso/callback,http://vpn.ptit.edu.vn/sso/callback','Cổng kết nối bảo mật VPN IPSec/SSL dành cho giảng viên và quản trị viên','fa-solid fa-shield-halved',1,'2026-11-14 12:22:48'),
(4,'webmail','Hệ thống Thư điện tử Sinh viên & Cán bộ (Webmail)','pbkdf2:sha256:100000$7b3417615f1cdb1f75a3db805e8d9315$b5c7438d5955a0c5046716a6ab1f719665190f71613df4d6abc4353e08fbc8c9','http://localhost:5000/sso/callback,http://mail.ptit.edu.vn/sso/callback','Dịch vụ Email cộng tác nội bộ trường @ptit.edu.vn','fa-solid fa-envelope',1,'2026-11-14 12:22:48'),
(5,'nac_admin','Bảng điều khiển Quản trị mạng Trung tâm (NAC Console)','pbkdf2:sha256:100000$c0224b2000f63ca11761e81f6b630161$9d0cc92d2d87318851ddad6900f2978e7e7431782b7c9cdf9ab050083349972f','http://localhost:5000/sso/callback','Trung tâm điều khiển NAC, RADIUS AAA và OpenLDAP','fa-solid fa-network-wired',1,'2026-11-14 12:22:48');
/*!40000 ALTER TABLE `sso_clients` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sso_sessions`
--

DROP TABLE IF EXISTS `sso_sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `sso_sessions` (
  `session_id` varchar(64) NOT NULL,
  `username` varchar(64) NOT NULL,
  `ip_address` varchar(45) DEFAULT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `created_at` datetime DEFAULT current_timestamp(),
  `last_activity` datetime DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `is_active` tinyint(1) DEFAULT 1,
  `logged_out_at` datetime DEFAULT NULL,
  PRIMARY KEY (`session_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sso_sessions`
--

LOCK TABLES `sso_sessions` WRITE;
/*!40000 ALTER TABLE `sso_sessions` DISABLE KEYS */;
INSERT INTO `sso_sessions` VALUES
('01ed37bd8099','sv_tuananh','172.19.0.1','Python-urllib/3.9','2026-11-15 11:37:48','2026-11-15 11:37:48',1,NULL),
('0299fef2fca6','gv_huong','172.19.0.1','Python-urllib/3.9','2026-11-15 12:15:53','2026-11-15 12:15:53',1,NULL),
('05cf074b8d07','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 06:10:45','2026-11-15 06:10:46',0,'2026-11-15 06:10:46'),
('07ce007c6e8d','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 12:36:37','2026-11-15 12:36:37',0,'2026-11-15 12:36:37'),
('09b26601f79b','admin','172.19.0.1','python-requests/2.32.5','2026-11-15 11:41:07','2026-11-15 11:41:07',1,NULL),
('09ffcdef933d','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 06:08:52','2026-11-15 06:08:53',1,NULL),
('0a2b71192636','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 09:09:31','2026-11-15 09:09:31',0,'2026-11-15 09:09:31'),
('0adceb999509','admin','172.19.0.1','python-requests/2.32.5','2026-11-15 14:25:30','2026-11-15 14:25:30',1,NULL),
('0f1c506ed0a0','gv_nguyen','172.19.0.1','python-requests/2.32.5','2026-11-15 10:07:55','2026-11-15 10:07:55',1,NULL),
('0f5c52ac93ce','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 06:11:14','2026-11-15 06:11:14',1,NULL),
('11cd4b0830bd','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 14:28:13','2026-11-15 14:28:14',1,NULL),
('13011a44873f','gv_nguyen','172.19.0.1','python-requests/2.32.5','2026-11-15 09:09:15','2026-11-15 09:09:15',1,NULL),
('14eaa4f64126','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 12:42:13','2026-11-15 12:42:13',1,NULL),
('15d0fb70b036','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 13:14:38','2026-11-15 13:14:38',1,NULL),
('16ad1d886550','sv_tuananh','172.19.0.1','Python-urllib/3.9','2026-11-15 11:37:14','2026-11-15 11:37:14',1,NULL),
('19509259b817','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 14:28:13','2026-11-15 14:28:13',1,NULL),
('196c5be9925f','sv_binh','172.19.0.1','python-requests/2.32.5','2026-11-15 10:07:09','2026-11-16 06:39:39',0,'2026-11-16 06:39:39'),
('1b0f10c4789a','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 14:25:38','2026-11-15 14:25:38',1,NULL),
('1b5602c14e2f','sv_vinh','172.19.0.1','python-requests/2.32.5','2026-11-15 10:07:39','2026-11-15 12:47:28',0,'2026-11-15 12:47:28'),
('1c6cc3f5dc3b','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 12:44:56','2026-11-15 12:44:56',1,NULL),
('1cab062f96f7','sv_vinh','172.19.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-15 10:11:08','2026-11-15 12:47:28',0,'2026-11-15 12:47:28'),
('213732fc66b2','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 06:09:44','2026-11-15 06:09:44',1,NULL),
('226336914741','sv_binh','172.19.0.1','python-requests/2.32.5','2026-11-15 10:08:15','2026-11-16 06:39:39',0,'2026-11-16 06:39:39'),
('24904983cad9','sv_vinh','172.19.0.1','python-requests/2.32.5','2026-11-15 09:09:15','2026-11-15 12:47:28',0,'2026-11-15 12:47:28'),
('25daed2d7b58','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 09:09:22','2026-11-15 09:09:22',1,NULL),
('27fe1bebf0bc','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 14:26:21','2026-11-15 14:26:21',1,NULL),
('28e18ad40b16','sv_tuananh','172.19.0.1','Python-urllib/3.9','2026-11-15 12:15:53','2026-11-15 12:15:53',1,NULL),
('296ba533b76d','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 09:09:22','2026-11-15 09:09:22',1,NULL),
('2a78d1cfbfbb','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 12:44:56','2026-11-15 12:44:56',1,NULL),
('2b9b81be3acf','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 13:15:08','2026-11-15 13:15:08',1,NULL),
('2db8d45b6fb1','sv_binh','172.19.0.1','python-requests/2.32.5','2026-11-15 12:34:52','2026-11-16 06:39:39',0,'2026-11-16 06:39:39'),
('31919914a6c2','sv_tuananh','172.19.0.1','Python-urllib/3.9','2026-11-15 14:28:34','2026-11-15 14:28:34',1,NULL),
('332af1a2ff6e','gv_huong','172.19.0.1','Python-urllib/3.9','2026-11-15 12:34:34','2026-11-15 12:34:34',1,NULL),
('345175c981f0','admin','172.19.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-15 08:47:00','2026-11-15 08:47:47',0,'2026-11-15 08:47:47'),
('34900ffba556','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 12:44:56','2026-11-15 12:44:56',1,NULL),
('381299073251','admin',NULL,NULL,'2026-11-15 06:11:15','2026-11-15 06:11:15',1,NULL),
('3e0df1b4c886','admin','172.19.0.1','Python-urllib/3.9','2026-11-16 06:39:02','2026-11-16 06:39:02',1,NULL),
('3e67d05eded6','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 12:34:41','2026-11-15 12:34:41',1,NULL),
('3f5929aecaa1','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 13:42:07','2026-11-15 13:42:08',0,'2026-11-15 13:42:08'),
('3fb47fb2b1ea','admin',NULL,NULL,'2026-11-15 11:41:21','2026-11-15 11:41:21',1,NULL),
('3fd12185b092','gv_nguyen','172.19.0.1','python-requests/2.32.5','2026-11-15 13:13:07','2026-11-15 13:13:07',1,NULL),
('410031792896','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 11:41:14','2026-11-15 11:41:15',0,'2026-11-15 11:41:15'),
('46d659797dae','sv_vinh','172.19.0.1','python-requests/2.32.5','2026-11-16 06:38:08','2026-11-16 06:38:10',0,'2026-11-16 06:38:10'),
('477273fed48a','admin','172.19.0.1','python-requests/2.32.5','2026-11-15 13:13:08','2026-11-15 13:13:08',1,NULL),
('489041a57930','admin',NULL,NULL,'2026-11-15 09:09:23','2026-11-15 09:09:23',1,NULL),
('4919a7c24152','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 14:26:48','2026-11-15 14:26:48',1,NULL),
('4940645620cf','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 09:09:22','2026-11-15 09:09:22',1,NULL),
('4a5ba1ed5933','admin','172.19.0.1','python-requests/2.32.5','2026-11-15 10:07:08','2026-11-15 10:07:08',1,NULL),
('4acfe80e253d','sv_vinh','172.19.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-15 09:14:29','2026-11-15 12:47:28',0,'2026-11-15 12:47:28'),
('4c9c1fe756cc','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 12:44:56','2026-11-15 12:44:56',1,NULL),
('4e3a5fa03483','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 12:44:49','2026-11-15 12:44:50',0,'2026-11-15 12:44:50'),
('4f4a9afdfd8f','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 10:08:07','2026-11-15 10:08:08',0,'2026-11-15 10:08:08'),
('51b22760e663','sv_binh','172.19.0.1','python-requests/2.32.5','2026-11-15 12:34:51','2026-11-16 06:39:39',0,'2026-11-16 06:39:39'),
('545f0eeb4122','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 11:41:20','2026-11-15 11:41:20',1,NULL),
('548cd4bbf580','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 12:34:41','2026-11-15 12:34:41',1,NULL),
('5765ee49a7cf','sv_tuananh','172.19.0.1','Python-urllib/3.9','2026-11-15 12:34:34','2026-11-15 12:34:34',1,NULL),
('58aa1453c958','gv_huong','172.19.0.1','Python-urllib/3.9','2026-11-15 12:45:04','2026-11-15 12:45:04',1,NULL),
('59a440f1d62e','admin','172.19.0.1','python-requests/2.32.5','2026-11-15 10:08:15','2026-11-15 10:08:15',1,NULL),
('5a9cf701a6fc','admin','172.19.0.1','Python-urllib/3.9','2026-11-16 06:39:03','2026-11-16 06:39:03',1,NULL),
('5b1092cdaa6b','gv_huong','172.19.0.1','Python-urllib/3.9','2026-11-15 14:28:34','2026-11-15 14:28:34',1,NULL),
('5b5128d044d9','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 06:11:14','2026-11-15 06:11:14',1,NULL),
('5e15d1277d40','admin','172.19.0.1','python-requests/2.32.5','2026-11-15 10:07:55','2026-11-15 10:07:55',1,NULL),
('60a9b38b6d3a','sv_tuananh','172.19.0.1','Python-urllib/3.9','2026-11-15 12:45:04','2026-11-15 12:45:04',1,NULL),
('614d1b7b9c9a','sv_vinh','172.19.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-15 09:14:52','2026-11-15 12:47:28',0,'2026-11-15 12:47:28'),
('62b10d69d537','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 06:11:14','2026-11-15 06:11:14',1,NULL),
('65d8351d190c','admin',NULL,NULL,'2026-11-15 12:34:41','2026-11-15 12:34:41',1,NULL),
('695587d07689','sv_binh','172.19.0.1','python-requests/2.32.5','2026-11-15 10:15:56','2026-11-16 06:39:39',0,'2026-11-16 06:39:39'),
('6c9df7d42ce1','sv_vinh','172.19.0.1','python-requests/2.32.5','2026-11-15 09:08:20','2026-11-15 12:47:28',0,'2026-11-15 12:47:28'),
('6dd55079efc9','sv_vinh','172.19.0.1','python-requests/2.32.5','2026-11-15 12:34:27','2026-11-15 12:47:28',0,'2026-11-15 12:47:28'),
('6f8f96838a61','gv_huong','172.19.0.1','Python-urllib/3.9','2026-11-15 11:40:44','2026-11-15 11:40:44',1,NULL),
('70bc132f1551','sv_binh','172.19.0.1','python-requests/2.32.5','2026-11-15 12:44:45','2026-11-16 06:39:39',0,'2026-11-16 06:39:39'),
('71c2a7e6a8fe','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 13:14:26','2026-11-15 13:14:27',0,'2026-11-15 13:14:27'),
('72457f47341a','gv_nguyen','172.19.0.1','python-requests/2.32.5','2026-11-15 12:41:22','2026-11-15 12:41:22',1,NULL),
('7488d1d2e905','admin','172.19.0.1','python-requests/2.32.5','2026-11-15 13:13:24','2026-11-15 13:13:24',1,NULL),
('790fc9bd8b58','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 13:14:38','2026-11-15 13:14:38',1,NULL),
('79901b587b12','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 13:14:38','2026-11-15 13:14:38',1,NULL),
('7b162bc893c7','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 14:24:40','2026-11-15 14:24:41',0,'2026-11-15 14:24:41'),
('7d31f41e58a9','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 11:41:20','2026-11-15 11:41:20',1,NULL),
('7de0c5cad234','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 10:08:01','2026-11-15 10:08:01',1,NULL),
('81046815d16c','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 09:09:22','2026-11-15 09:09:22',1,NULL),
('8585e362a6dc','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 10:08:00','2026-11-15 10:08:00',1,NULL),
('870149d2808d','admin','172.19.0.1','python-requests/2.32.5','2026-11-15 10:15:55','2026-11-15 10:15:55',1,NULL),
('88adc7a01c7e','sv_tuananh','172.19.0.1','Python-urllib/3.9','2026-11-15 11:37:55','2026-11-15 11:37:55',1,NULL),
('8a5a04aec9e2','sv_binh','172.19.0.1','python-requests/2.32.5','2026-11-15 14:28:23','2026-11-16 06:39:39',0,'2026-11-16 06:39:39'),
('8ad19b772a30','sv_binh','172.19.0.1','python-requests/2.32.5','2026-11-15 13:13:24','2026-11-16 06:39:39',0,'2026-11-16 06:39:39'),
('8af263384b36','sv_vinh','172.19.0.1','python-requests/2.32.5','2026-11-15 10:07:54','2026-11-15 12:47:28',0,'2026-11-15 12:47:28'),
('8db9e87a6468','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 13:14:57','2026-11-15 13:14:57',1,NULL),
('8f55274cac52','sv_tuananh','172.19.0.1','Python-urllib/3.9','2026-11-15 11:40:44','2026-11-15 11:40:44',1,NULL),
('8f6f688b1a25','admin','172.19.0.1','python-requests/2.32.5','2026-11-15 14:28:22','2026-11-15 14:28:22',1,NULL),
('8fefed78753a','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 06:11:14','2026-11-15 06:11:14',1,NULL),
('92e4af55b7fd','sv_binh','172.19.0.1','python-requests/2.32.5','2026-11-16 06:39:39','2026-11-16 06:39:39',1,NULL),
('9366a2a68691','meoluoi','172.19.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-15 12:44:21','2026-11-15 13:44:52',1,NULL),
('9422ca29d76c','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 09:09:22','2026-11-15 09:09:22',1,NULL),
('962fccc44758','admin','172.19.0.1','python-requests/2.32.5','2026-11-15 12:41:22','2026-11-15 12:41:22',1,NULL),
('9aa66e5a18e9','gv_huong','172.19.0.1','Python-urllib/3.9','2026-11-15 12:21:54','2026-11-15 12:21:54',1,NULL),
('9aaac9c11d36','gv_nguyen','172.19.0.1','python-requests/2.32.5','2026-11-15 13:42:32','2026-11-15 13:42:32',1,NULL),
('9af14b9d6a75','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 12:16:08','2026-11-15 12:16:08',1,NULL),
('9b0051916a62','sv_binh','172.19.0.1','python-requests/2.32.5','2026-11-15 14:28:24','2026-11-16 06:39:39',0,'2026-11-16 06:39:39'),
('9b2dd412fd7e','sv_binh','172.19.0.1','python-requests/2.32.5','2026-11-15 11:41:07','2026-11-16 06:39:39',0,'2026-11-16 06:39:39'),
('9c7b4eb0bc5a','sv_vinh','172.19.0.1','python-requests/2.32.5','2026-11-15 12:40:54','2026-11-15 12:47:28',0,'2026-11-15 12:47:28'),
('9cb28f6fd8ce','admin','172.19.0.1','Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/158.0.0.0 Safari/537.36','2026-11-15 09:12:35','2026-11-15 13:31:38',1,NULL),
('9e0d8edbb9ae','sv_tuananh','172.19.0.1','Python-urllib/3.9','2026-11-15 11:38:25','2026-11-15 11:38:25',1,NULL),
('9e385355d64e','gv_nguyen','172.19.0.1','python-requests/2.32.5','2026-11-15 14:25:30','2026-11-15 14:25:30',1,NULL),
('9e6b0dfcc1bb','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 09:09:22','2026-11-15 09:09:22',1,NULL),
('a15ce64c5775','sv_binh','172.19.0.1','python-requests/2.32.5','2026-11-15 10:08:16','2026-11-16 06:39:39',0,'2026-11-16 06:39:39'),
('a50019567327','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 12:34:40','2026-11-15 12:34:40',1,NULL),
('a503a01c56a1','sv_tuananh','172.19.0.1','Python-urllib/3.9','2026-11-15 12:21:53','2026-11-15 12:21:53',1,NULL),
('a521df9a5aa5','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 10:08:00','2026-11-15 10:08:00',1,NULL),
('a650312e5061','sv_tuananh','172.19.0.1','Python-urllib/3.9','2026-11-16 06:39:56','2026-11-16 06:39:56',1,NULL),
('a72161fc0da9','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 12:42:18','2026-11-15 12:42:18',1,NULL),
('a973ff88650d','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 11:41:20','2026-11-15 11:41:20',1,NULL),
('aa366b69ac2a','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 12:44:56','2026-11-15 12:44:56',1,NULL),
('ab33a06e8ce5','sv_binh','172.19.0.1','python-requests/2.32.5','2026-11-15 11:41:08','2026-11-16 06:39:39',0,'2026-11-16 06:39:39'),
('ad6acb6f8289','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 12:34:40','2026-11-15 12:34:40',1,NULL),
('adf934ce0419','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 12:44:56','2026-11-15 12:44:56',1,NULL),
('b1a1bbda94b0','admin','172.19.0.1','python-requests/2.32.5','2026-11-16 06:39:38','2026-11-16 06:39:38',1,NULL),
('b1e295234844','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 13:14:38','2026-11-15 13:14:38',1,NULL),
('b23b90c8ebf7','admin','172.19.0.1','python-requests/2.32.5','2026-11-15 12:44:44','2026-11-15 12:44:44',1,NULL),
('b3d5b278ad92','sv_vinh','172.19.0.1','python-requests/2.32.5','2026-11-15 12:35:53','2026-11-15 12:47:28',0,'2026-11-15 12:47:28'),
('b51d8b14cf67','admin','172.19.0.1','Python-urllib/3.9','2026-11-16 06:42:38','2026-11-16 06:42:38',1,NULL),
('b6632b854acc','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 11:41:20','2026-11-15 11:41:20',1,NULL),
('b75c3c78b0bb','gv_huong','172.19.0.1','Python-urllib/3.9','2026-11-16 06:39:56','2026-11-16 06:39:56',1,NULL),
('b9f0c1344115','sv_vinh','172.19.0.1','python-requests/2.32.5','2026-11-15 13:42:31','2026-11-15 13:42:32',0,'2026-11-15 13:42:32'),
('ba54ea64acf9','admin',NULL,NULL,'2026-11-15 10:08:02','2026-11-15 10:08:02',1,NULL),
('bb1796546227','sv_tuananh','172.19.0.1','Python-urllib/3.9','2026-11-15 13:14:45','2026-11-15 13:14:45',1,NULL),
('bb965152e437','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 13:14:38','2026-11-15 13:14:38',1,NULL),
('bc08cdf07cec','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 12:34:40','2026-11-15 12:34:40',1,NULL),
('bd264109da8b','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 06:11:14','2026-11-15 06:11:14',1,NULL),
('bdead9f8246f','sv_binh','172.19.0.1','python-requests/2.32.5','2026-11-15 12:44:44','2026-11-16 06:39:39',0,'2026-11-16 06:39:39'),
('c11308fe3b5d','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 11:41:20','2026-11-15 11:41:20',1,NULL),
('c21469bfe60c','gv_nguyen','172.19.0.1','python-requests/2.32.5','2026-11-16 06:38:09','2026-11-16 06:38:09',1,NULL),
('c2b092bbd695','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 09:09:22','2026-11-15 09:09:22',1,NULL),
('c353276320f7','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 12:38:34','2026-11-15 12:38:34',1,NULL),
('c3cf3d09c2c6','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 11:41:20','2026-11-15 11:41:20',1,NULL),
('c430c6d1106e','sv_binh','172.19.0.1','python-requests/2.32.5','2026-11-15 10:07:09','2026-11-16 06:39:39',0,'2026-11-16 06:39:39'),
('c6dbefcad9a4','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 14:29:55','2026-11-15 14:29:55',1,NULL),
('c78842fd6c08','admin','172.19.0.1','python-requests/2.32.5','2026-11-16 06:38:10','2026-11-16 06:38:10',1,NULL),
('c9a7bcea8005','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 06:11:05','2026-11-15 06:11:05',0,'2026-11-15 06:11:05'),
('cc21b176fc24','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 06:11:14','2026-11-15 06:11:14',1,NULL),
('cc8f59947f36','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 14:27:54','2026-11-15 14:27:55',0,'2026-11-15 14:27:55'),
('ce5161354332','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 10:08:01','2026-11-15 10:08:01',1,NULL),
('cf2d9b081159','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 13:14:38','2026-11-15 13:14:38',1,NULL),
('d1958d917138','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 10:08:00','2026-11-15 10:08:00',1,NULL),
('d2ab23e07cac','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 14:23:44','2026-11-15 14:23:45',0,'2026-11-15 14:23:45'),
('d4a7bbd6f8c2','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 14:29:26','2026-11-15 14:29:26',1,NULL),
('d574547002d3','gv_huong','172.19.0.1','Python-urllib/3.9','2026-11-15 13:14:46','2026-11-15 13:14:46',1,NULL),
('d5f5ab947923','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 06:11:15','2026-11-15 06:11:15',1,NULL),
('d8816b131ebf','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 12:34:41','2026-11-15 12:34:41',1,NULL),
('d9fc76c6f395','sv_binh','172.19.0.1','python-requests/2.32.5','2026-11-15 10:15:55','2026-11-16 06:39:39',0,'2026-11-16 06:39:39'),
('e127a6683abf','sv_binh','172.19.0.1','python-requests/2.32.5','2026-11-16 06:39:38','2026-11-16 06:39:39',0,'2026-11-16 06:39:39'),
('e2c951b0d503','admin',NULL,NULL,'2026-11-15 13:14:39','2026-11-15 13:14:39',1,NULL),
('e2fa488ee3be','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 12:34:40','2026-11-15 12:34:40',1,NULL),
('e4797fdbb3be','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 13:14:38','2026-11-15 13:14:38',1,NULL),
('e545ac603031','sv_vinh','172.19.0.1','python-requests/2.32.5','2026-11-15 12:41:22','2026-11-15 12:47:28',0,'2026-11-15 12:47:28'),
('e75e52d46cab','admin','172.19.0.1','Python-urllib/3.9','2026-11-16 06:38:39','2026-11-16 06:38:39',0,'2026-11-16 06:38:39'),
('e80353c52b7c','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 11:41:20','2026-11-15 11:41:20',1,NULL),
('eb040b053fd8','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 12:44:55','2026-11-15 12:44:55',1,NULL),
('ebcbff670f97','admin','172.19.0.1','python-requests/2.32.5','2026-11-15 09:09:15','2026-11-15 09:09:15',1,NULL),
('ef969335026c','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 06:09:24','2026-11-15 06:09:24',1,NULL),
('efd94c093106','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 14:24:55','2026-11-15 14:25:02',1,NULL),
('f18ce4225081','admin',NULL,NULL,'2026-11-15 12:44:57','2026-11-15 12:44:57',1,NULL),
('f315371cc5e4','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 10:08:01','2026-11-15 10:08:01',1,NULL),
('f38db143f468','sv_binh','172.19.0.1','python-requests/2.32.5','2026-11-15 13:13:25','2026-11-16 06:39:39',0,'2026-11-16 06:39:39'),
('f4121a9b2d8b','sv_vinh','172.19.0.1','python-requests/2.32.5','2026-11-15 13:13:07','2026-11-15 13:13:08',0,'2026-11-15 13:13:08'),
('f54be914e424','admin','172.19.0.1','python-requests/2.32.5','2026-11-15 12:34:51','2026-11-15 12:34:51',1,NULL),
('f7c83486eb13','admin','172.19.0.1','python-requests/2.32.5','2026-11-15 13:42:32','2026-11-15 13:42:32',1,NULL),
('f90d0c4819de','gv_nguyen','172.19.0.1','python-requests/2.32.5','2026-11-15 12:40:55','2026-11-15 12:40:55',1,NULL),
('f9de4de54e73','sv_vinh','172.19.0.1','python-requests/2.32.5','2026-11-15 14:25:29','2026-11-15 14:25:30',0,'2026-11-15 14:25:30'),
('fc48ef11978a','admin','172.19.0.1','Python-urllib/3.9','2026-11-15 10:08:01','2026-11-15 10:08:01',1,NULL),
('fda84e15923e','admin','172.19.0.1','Python-urllib/3.9','2026-11-16 06:42:05','2026-11-16 06:42:05',1,NULL);
/*!40000 ALTER TABLE `sso_sessions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_mfa`
--

DROP TABLE IF EXISTS `user_mfa`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_mfa` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `username` varchar(64) NOT NULL,
  `recovery_codes` text DEFAULT NULL,
  `secret_key` varchar(255) NOT NULL,
  `is_enabled` tinyint(1) DEFAULT 0,
  `created_at` datetime DEFAULT current_timestamp(),
  `failed_attempts` int(11) NOT NULL DEFAULT 0,
  `locked_until` bigint(20) NOT NULL DEFAULT 0,
  `last_step` bigint(20) NOT NULL DEFAULT -1,
  `last_used_at` datetime DEFAULT NULL,
  `failed_otp_attempts` int(11) DEFAULT 0,
  `otp_locked_until` datetime DEFAULT NULL,
  `last_verified_step` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `username` (`username`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_mfa`
--

LOCK TABLES `user_mfa` WRITE;
/*!40000 ALTER TABLE `user_mfa` DISABLE KEYS */;
INSERT INTO `user_mfa` VALUES
(1,'admin',NULL,'JBSWY3DPEHPK3PXP',0,'2026-11-14 12:23:27',0,0,-1,'2026-11-16 06:42:38',3,'2026-11-16 06:52:39',59827045),
(2,'sv_vinh',NULL,'W74IB3ON4J5T3YDFTLBJCMHH7L6DR7GS',0,'2026-11-15 09:12:50',0,0,-1,NULL,0,NULL,NULL);
/*!40000 ALTER TABLE `user_mfa` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'radius'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-11-17  4:03:15
