call usernames_cleanup();
DELIMITER $$
CREATE PROCEDURE `usernames_cleanup` ()
LANGUAGE SQL
SQL SECURITY DEFINER
COMMENT 'A procedure to cleanup (adding a leading _1) repeated usernames on a user table'
BEGIN
	DECLARE counter INT DEFAULT 1;
	DECLARE userid INT;
	DECLARE done INT DEFAULT 0;
	DECLARE usercount INT DEFAULT 0;
	DECLARE current_username VARCHAR(50) DEFAULT '';
	DECLARE previous_username VARCHAR(50) DEFAULT '';
	DECLARE new_username VARCHAR(50) DEFAULT '';
	DECLARE userdata CURSOR FOR SELECT u.userid, u.username FROM user u INNER JOIN user u2 ON u.username = u2.username WHERE u.userid <> u2.userid GROUP BY u.userid ORDER BY u.username, u.userid ASC;							
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = 1;

	CREATE TABLE IF NOT EXISTS double_usernames(userid INT, old_username VARCHAR(50), new_username VARCHAR(50));

	OPEN userdata;
	
	select FOUND_ROWS() into usercount;
	
	read_loop: LOOP
		
		FETCH userdata INTO userid, current_username;
		
		IF done = 1 THEN
      			LEAVE read_loop;
    		END IF;
		
		IF current_username = previous_username THEN
			/* 
			- If instead if usernames we have emails we can create the new_usermeial adding a +01
			SET new_useremail = CONCAT(SUBSTRING_INDEX(current_useremail, '@', 1), '+0', counter,  '@',SUBSTRING_INDEX(current_useremail, '@', -1));
			*/
			SET new_username = CONCAT(current_username, '_0', counter);
			SET counter = counter + 1;
			INSERT INTO double_usernames VALUES(userid, current_username, new_username);
		ELSE
			INSERT INTO double_usernames VALUES(userid, current_username, '');
			SET counter = 1;
		END IF;
		
		SET previous_username = current_username;
	
	END LOOP;
	
	CLOSE userdata;
END$$

/* 
- We can either update the usernames or just delete the extra users 
*/
UPDATE tbl_user
INNER JOIN
double_usernames
ON tbl_user.userid = double_usernames.userid
SET tbl_user.username = double_usernames.new_username
WHERE double_usernames.new_username != ''
