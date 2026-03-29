USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_user_get_by_id $$

CREATE PROCEDURE sp_user_get_by_id(
    IN in_pk_appUser BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching the user.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    IF(in_pk_appUser IS NULL) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'User ID cannot be null.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM AppUser WHERE pk_appUser = in_pk_appUser) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'User not found.', 'code', 'USER_NOT_FOUND');
        LEAVE proc;
    END IF;

    SELECT JSON_OBJECT(
        'success', TRUE,
        'message', 'User fetched successfully.',
        'code', 'SUCCESS_OK',
        'data', JSON_OBJECT(
            'pk_appUser', pk_appUser,
            'username', username,
            'email', email,
            'createdAt', createdAt,
            'lastLogin', lastLogin,
            'isActive', isActive,
            'emailVerified', emailVerified
        )
    )
    INTO out_response
    FROM AppUser
    WHERE pk_appUser = in_pk_appUser;
END $$

DELIMITER ;