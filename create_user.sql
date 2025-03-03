CREATE USER 'toolinguser'@'%' IDENTIFIED BY 'devopsacts';
GRANT ALL PRIVILEGES ON * . * TO 'toolinguser'@'%';
FLUSH PRIVILEGES;
