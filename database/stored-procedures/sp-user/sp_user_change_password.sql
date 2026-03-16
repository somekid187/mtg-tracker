USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_user_change_password$$

CREATE PROCEDURE sp_user_change_password(
    IN in_resetToken VARCHAR(255),
    IN in_newPassword VARCHAR(255),
    OUT out_response JSON
)
proc: BEGIN
    DECLARE currentPasswordHash VARCHAR(255);
    DECLARE storedResetToken VARCHAR(255);
    DECLARE tokenExpiry DATETIME;
    DECLARE userId BIGINT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET out_response = JSON_OBJECT(
            'success', FALSE,
            'message', 'An error occurred.',
            'code', 'INTERNAL_SERVER_ERROR'
        );
    END;

    -- Fetch user details
    SELECT passwordHash, resetToken, tokenExpiresAt, pk_appUser
    INTO currentPasswordHash, storedResetToken, tokenExpiry, userId
    FROM AppUser;

    IF currentPasswordHash IS NULL THEN
        SET out_response = JSON_OBJECT(
            'success', FALSE,
            'message', 'User not found.',
            'code', 'USER_NOT_FOUND'
        );
        LEAVE proc;
    END IF;

    -- Password change with reset token
    IF in_resetToken IS NOT NULL THEN
        IF storedResetToken IS NULL OR storedResetToken != in_resetToken OR tokenExpiry < NOW() THEN
            SET out_response = JSON_OBJECT(
                'success', FALSE,
                'message', 'Invalid or expired reset token.',
                'code', 'INVALID_RESET_TOKEN'
            );
            LEAVE proc;
        END IF;
    ELSE
        SET out_response = JSON_OBJECT(
            'success', FALSE,
            'message', 'Either a reset token or the old password must be provided.',
            'code', 'MISSING_CREDENTIALS'
        );
        LEAVE proc;
    END IF;

    START TRANSACTION;

    -- Update the password and clear the reset token
    UPDATE AppUser
    SET
        passwordHash = in_newPassword,
        resetToken = NULL,
        tokenExpiresAt = NULL
    WHERE pk_appUser = userId;

    COMMIT;

    SET out_response = JSON_OBJECT(
        'success', TRUE,
        'message', 'Password changed successfully.',
        'code', 'PASSWORD_CHANGED'
    );

END$$

DELIMITER ;

