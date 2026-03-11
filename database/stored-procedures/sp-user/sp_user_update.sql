USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_user_update $$

CREATE PROCEDURE sp_user_update(
    IN in_pk_appUser BIGINT,
    IN in_username VARCHAR(255),
    IN in_email VARCHAR(255),
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            -- Rollback transaction on error
            ROLLBACK;
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while updating the user.');
        END;

    -- Start transaction
    START TRANSACTION;

    -- Check if user exists
    IF NOT EXISTS (SELECT 1 FROM AppUser WHERE pk_appUser = in_pk_appUser) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'User not found.');
        LEAVE proc;
    END IF;

    -- Update user information
    UPDATE AppUser
    SET username = COALESCE(in_username, username),
        email = COALESCE(in_email, email)
    WHERE pk_appUser = in_pk_appUser;

    -- Commit transaction
    COMMIT;

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'User updated successfully.');
END $$

DELIMITER ;