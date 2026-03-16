USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_refreshToken_delete $$

CREATE PROCEDURE sp_refreshToken_delete(
    IN in_pk_refreshToken BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            -- Rollback transaction on error
            ROLLBACK;
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while deleting the refresh token.',
            'code', 'INTERNAL_SERVER_ERROR');
        END;

    -- Start transaction
    START TRANSACTION;

    -- Check if refresh token exists
    IF NOT EXISTS (SELECT 1 FROM RefreshToken WHERE pk_refreshToken = in_pk_refreshToken) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Refresh token not found.',
                           'code', 'VALIDATION_REFRESHTOKEN_NOT_FOUND');
        LEAVE proc;
    END IF;

    -- Delete refresh token
    DELETE FROM RefreshToken WHERE pk_refreshToken = in_pk_refreshToken;

    -- Commit transaction
    COMMIT;

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Refresh token deleted successfully.',
    'code', 'REFRESHTOKEN_DELETED');
END $$