USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_user_delete $$

CREATE PROCEDURE sp_user_delete(
    IN in_pk_appUser BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            -- Rollback transaction on error
            ROLLBACK;
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while deleting the user.');
        END;

    -- Start transaction
    START TRANSACTION;

    -- Check if user exists
    IF NOT EXISTS (SELECT 1 FROM AppUser WHERE pk_appUser = in_pk_appUser) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'User not found.');
        LEAVE proc;
    END IF;

    -- Delete user
    DELETE FROM AppUser WHERE pk_appUser = in_pk_appUser;

    -- Commit transaction
    COMMIT;

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'User deleted successfully.');
END $$

DELIMITER ;