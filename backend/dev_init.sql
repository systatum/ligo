CREATE DATABASE IF NOT EXISTS ligo_development;
CREATE DATABASE IF NOT EXISTS ligo_test;

CREATE USER 'devroot'@'localhost' IDENTIFIED BY 'devroot';
GRANT ALL PRIVILEGES ON ligo_development.* TO 'devroot'@'localhost';
GRANT ALL PRIVILEGES ON ligo_test.* TO 'devroot'@'localhost';

-- so that we can connect from outside the container, e.g. from host machine
CREATE USER 'devroot'@'%' IDENTIFIED BY 'devroot';
GRANT ALL PRIVILEGES ON ligo_development.* TO 'devroot'@'%';
GRANT ALL PRIVILEGES ON ligo_test.* TO 'devroot'@'%';

ALTER USER 'devroot'@'localhost' IDENTIFIED WITH mysql_native_password BY 'devroot';
ALTER USER 'devroot'@'%' IDENTIFIED WITH mysql_native_password BY 'devroot';

FLUSH PRIVILEGES;
