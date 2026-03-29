-- TEST 1: Create a new users
CALL sp_create_user('testuser', 'test@test.lu', 'hashedpassword', 'verificationtoken', @response);
UPDATE AppUser SET pk_appUser = 1 WHERE username = 'testuser';
SELECT @response AS TEST1_response;
CALL sp_create_user('testuser2', 'test2@test.lu', 'hashedpassword', 'verificationtoken', @response);
UPDATE AppUser SET pk_appUser = 2 WHERE username = 'testuser2';
SELECT @response AS TEST1_response;
CALL sp_create_user('testuser3', 'test3@test.lu', 'hashedpassword', 'verificationtoken', @response);
UPDATE AppUser SET pk_appUser = 3 WHERE username = 'testuser3';
SELECT @response AS TEST1_response;

-- TEST 2: Attempt to create a user with an existing username
CALL sp_create_user('testuser', 'test4@test.lu', 'hashedpassword', 'verificationtoken', @response);
SELECT @response AS TEST2_response;

-- TEST 3: Attempt to create a user with an existing email
CALL sp_create_user('testuser4', 'test@test.lu', 'hashedpassword', 'verificationtoken', @response);
SELECT @response AS TEST3_response;

-- TEST 4: Update an existing user only username
CALL sp_update_user(1, 'updateduser', NULL, @response);
SELECT @response AS TEST4_response;

-- TEST 5: Update an existing user only email
CALL sp_update_user(1, NULL, 'test4@test.lu', @response);
SELECT @response AS TEST5_response;

-- TEST 6: Attempt to update a user to an existing username
CALL sp_update_user(1, 'testuser2', NULL, @response);
SELECT @response AS TEST6_response;

-- TEST 7: Attempt to update a user to an existing email
CALL sp_update_user(1, NULL,  'test2@test.lu', @response);
SELECT @response AS TEST7_response;

-- TEST 8: Delete an existing user
CALL sp_delete_user(1, @response);
SELECT @response AS TEST8_response;

-- TEST 9: Attempt to delete a non-existing user
CALL sp_delete_user(999, @response);
SELECT @response AS TEST9_response;

-- TEST 10: Fetch users with pagination
CALL sp_get_user(1, @response);
SELECT @response AS TEST10_response;

-- TEST 11: Fetch users with pagination (page 2)
CALL sp_get_user(2, @response);
SELECT @response AS TEST11_response;



-- REMOVE TEST DATA
DELETE FROM AppUser;
SELECT * FROM AppUser;