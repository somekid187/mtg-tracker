USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_refreshToken_revoke $$

CREATE PROCEDURE sp_refreshToken_revoke(
    IN  in_tokenHash            VARCHAR(255),
    IN  in_fk_appUser           BIGINT,
    OUT out_response            JSON
)
proc:
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
            SET out_response = JSON_OBJECT(
                'success', FALSE,
                'message', 'An error occurred while revoking the refresh token.',
                'code',    'INTERNAL_SERVER_ERROR'
            );
        END;

    START TRANSACTION;

    -- Verify the token exists, belongs to the user, and is not already revoked
    IF NOT EXISTS (
        SELECT 1 FROM RefreshToken
        WHERE tokenHash = in_tokenHash
          AND fk_appUser_refreshes = in_fk_appUser
    ) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT(
            'success', FALSE,
            'message', 'Refresh token not found or does not belong to the user.',
            'code',    'VALIDATION_TOKEN_NOT_FOUND'
        );
        LEAVE proc;
    END IF;

    IF EXISTS (
        SELECT 1 FROM RefreshToken
        WHERE tokenHash = in_tokenHash
          AND revokedAt IS NOT NULL
    ) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT(
            'success', FALSE,
            'message', 'Refresh token is already revoked.',
            'code',    'VALIDATION_TOKEN_ALREADY_REVOKED'
        );
        LEAVE proc;
    END IF;

    -- Revoke the token
    UPDATE RefreshToken
    SET revokedAt = NOW()
    WHERE tokenHash = in_tokenHash;

    COMMIT;

    SET out_response = JSON_OBJECT(
        'success', TRUE,
        'message', 'Refresh token revoked successfully.',
        'code',    'SUCCESS_OK'
    );
END $$

DELIMITER ;

