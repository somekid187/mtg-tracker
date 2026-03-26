USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_user_get_by_username $$

CREATE PROCEDURE sp_user_get_by_username(
    IN in_username VARCHAR(255),
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while searching for the user.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    IF (in_username IS NULL OR in_username = '') THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Username cannot be empty.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM AppUser WHERE username = in_username) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'User not found.', 'code', 'USER_NOT_FOUND');
        LEAVE proc;
    END IF;

    SELECT JSON_OBJECT(
        'success', TRUE,
        'message', 'User found.',
        'code', 'SUCCESS_OK',
        'data', JSON_OBJECT(
            'userId', pk_appUser,
            'username', username
        )
    )
    INTO out_response
    FROM AppUser
    WHERE username = in_username;
END $$

DELIMITER ;
