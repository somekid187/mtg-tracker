USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_refreshToken_create $$

CREATE PROCEDURE sp_refreshToken_create(
    IN  in_fk_appUser           BIGINT,
    IN  in_tokenHash            VARCHAR(255),
    IN  in_ipLastUsed           VARCHAR(255),
    IN  in_ipCreated            VARCHAR(255),
    IN  in_deviceName           VARCHAR(255),
    IN  in_expiresAt            DATETIME,
    IN  in_fk_rotatedFrom       BIGINT,        -- NULL for a brand-new token
    OUT out_response            JSON
)
proc:
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
            SET out_response = JSON_OBJECT(
                'success', FALSE,
                'message', 'An error occurred while creating the refresh token.',
                'code',    'INTERNAL_SERVER_ERROR'
            );
        END;

    START TRANSACTION;

    -- Verify the user exists
    IF NOT EXISTS (SELECT 1 FROM AppUser WHERE pk_appUser = in_fk_appUser) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT(
            'success', FALSE,
            'message', 'User not found.',
            'code',    'VALIDATION_USER_NOT_FOUND'
        );
        LEAVE proc;
    END IF;

    -- If this is a rotated token, verify the predecessor exists and belongs to the same user
    IF in_fk_rotatedFrom IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM RefreshToken
            WHERE pk_refreshToken    = in_fk_rotatedFrom
              AND fk_appUser_refreshes = in_fk_appUser
        ) THEN
            ROLLBACK;
            SET out_response = JSON_OBJECT(
                'success', FALSE,
                'message', 'The token being rotated does not exist or does not belong to this user.',
                'code',    'VALIDATION_INVALID_ROTATED_FROM'
            );
            LEAVE proc;
        END IF;

        -- Revoke the old token now that it is being rotated
        UPDATE RefreshToken
        SET revokedAt = NOW()
        WHERE pk_refreshToken = in_fk_rotatedFrom
          AND revokedAt IS NULL;
    END IF;

    -- Insert the new token
    INSERT INTO RefreshToken (
        tokenHash,
        ipLastUsed,
        ipCreated,
        deviceName,
        expiresAt,
        createdAt,
        revokedAt,
        fk_refreshToken_rotatedFrom,
        fk_appUser_refreshes
    )
    VALUES (
        in_tokenHash,
        in_ipLastUsed,
        in_ipCreated,
        in_deviceName,
        in_expiresAt,
        NOW(),
        NULL,               -- not revoked yet
        in_fk_rotatedFrom,  -- NULL for first-time tokens
        in_fk_appUser
    );

    COMMIT;

    SET out_response = JSON_OBJECT(
        'success', TRUE,
        'message', 'Refresh token created successfully.',
        'code',    'SUCCESS_CREATED',
        'data',    JSON_OBJECT('pk_refreshToken', LAST_INSERT_ID())
    );
END $$

DELIMITER ;
