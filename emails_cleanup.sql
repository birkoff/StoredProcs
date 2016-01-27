call emails_cleanup();
DELIMITER $$
CREATE PROCEDURE `emails_cleanup` ()
LANGUAGE SQL
SQL SECURITY DEFINER
COMMENT 'A procedure to cleanup (adding a leading +1) repeated emails on a user table'
BEGIN
	DECLARE counter INT DEFAULT 1;
	DECLARE userid INT;
	DECLARE done INT DEFAULT 0;
	DECLARE usercount INT DEFAULT 0;
	DECLARE current_email VARCHAR(50) DEFAULT '';
	DECLARE previous_email VARCHAR(50) DEFAULT '';
	DECLARE new_email VARCHAR(50) DEFAULT '';
	DECLARE username VARCHAR(50) DEFAULT '';
	DECLARE userdata CURSOR FOR SELECT u.userid, u.username, u.email FROM user u INNER JOIN user u2 ON u.email = u2.email WHERE u.userid <> u2.userid GROUP BY u.userid ORDER BY u.email, u.userid ASC;							
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

	CREATE TABLE IF NOT EXISTS double_emails(userid INT, username VARCHAR(50), old_email VARCHAR(50), new_email VARCHAR(50));

	OPEN userdata;
	
	select FOUND_ROWS() into usercount;
	
	read_loop: LOOP
		
		FETCH userdata INTO userid, username, current_email;
		
		IF done = 1 THEN
      			LEAVE read_loop;
    		END IF;
		
		IF current_email = previous_email THEN
		 	SET new_email = CONCAT(SUBSTRING_INDEX(current_email, '@', 1), '+0', counter,  '@',SUBSTRING_INDEX(current_email, '@', -1));
			SET counter = counter + 1;
			INSERT INTO double_emails VALUES(userid, username, current_email, new_email);
		ELSE
			INSERT INTO double_emails VALUES(userid, username, current_email, '');
			SET counter = 1;
		END IF;
		
		SET previous_email = current_email;
	
	END LOOP;
	
	CLOSE userdata;
	
END$$
