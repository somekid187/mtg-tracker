USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_refreshToken_cleanup $$

CREATE PROCEDURE sp_refreshToken_cleanup(
    OUT out_response JSON
)
proc:
BEGIN
    DECLARE v_deleted INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
            SET out_response = JSON_OBJECT(
                'success', FALSE,
                'message', 'An error occurred while cleaning up refresh tokens.',
                'code',    'INTERNAL_SERVER_ERROR'
            );
        END;

    START TRANSACTION;

    -- Delete tokens that are expired or revoked
    DELETE FROM RefreshToken
    WHERE expiresAt < NOW()
       OR revokedAt IS NOT NULL;

    SET v_deleted = ROW_COUNT();

    COMMIT;

    SET out_response = JSON_OBJECT(
        'success', TRUE,
        'message', CONCAT('Cleaned up ', v_deleted, ' expired/revoked refresh tokens.'),
        'code',    'SUCCESS_OK',
        'data',    JSON_OBJECT('deletedCount', v_deleted)
    );
END $$

DELIMITER ;
