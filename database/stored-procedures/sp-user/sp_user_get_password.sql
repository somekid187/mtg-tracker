USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_user_get_password $$

CREATE PROCEDURE sp_user_get_password(
    IN in_email VARCHAR(255),
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching the password.',
            'code', 'INTERNAL_SERVER_ERROR');
        END;

    IF(in_email IS NULL OR in_email = '') THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Email cannot be null or empty.',
                           'code', 'INVALID_EMAIL');
        LEAVE proc;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM AppUser WHERE email = in_email) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'User not found.',
                           'code', 'INVALID_CREDENTIALS');
        LEAVE proc;
    END IF;

    SELECT JSON_OBJECT(
        'success', TRUE,
        'message', 'Password fetched successfully.',
        'code', 'SUCCESS_OK',
        'data', JSON_OBJECT(
            'passwordHash', passwordHash
        )
    )
    INTO out_response
    FROM AppUser
    WHERE email = in_email;
END $$