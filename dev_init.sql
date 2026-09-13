CREATE DATABASE IF NOT EXISTS ligo_development;
CREATE DATABASE IF NOT EXISTS ligo_test;

CREATE USER 'devroot'@'%' IDENTIFIED BY 'devroot';
GRANT ALL PRIVILEGES ON ligo_development.* TO 'devroot'@'%';
GRANT ALL PRIVILEGES ON ligo_test.* TO 'devroot'@'%';

ALTER USER 'devroot'@'%' IDENTIFIED WITH mysql_native_password BY 'devroot';

FLUSH PRIVILEGES;
