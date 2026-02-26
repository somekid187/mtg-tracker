USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_create_user $$

CREATE PROCEDURE sp_create_user(
    IN in_username VARCHAR(255),
    IN in_email VARCHAR(255),
    IN in_passwordHash VARCHAR(255),
    IN in_verificationToken VARCHAR(255),
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            -- Rollback transaction on error
            ROLLBACK;
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while creating the user.');
        END;

    -- Start transaction
    START TRANSACTION;

    -- Check if username already exists
    IF EXISTS (SELECT 1 FROM AppUser WHERE username = in_username) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Username already exists.');
        LEAVE proc;
    END IF;

    -- Check if email already exists
    IF EXISTS (SELECT 1 FROM AppUser WHERE email = in_email) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Email already exists.');
        LEAVE proc;
    END IF;

    -- Insert new user
    INSERT INTO AppUser (username, email, passwordHash, verificationToken)
    VALUES (in_username, in_email, in_passwordHash, in_verificationToken);

    -- Commit transaction
    COMMIT;

    SET out_response = JSON_OBJECT('success', TRUE,
                                   'message',
                                   'User created successfully. Please check your email for verification instructions.',
                       'userId', LAST_INSERT_ID());
END $$