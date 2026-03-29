USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_refreshToken_get_by_id $$

CREATE PROCEDURE sp_refreshToken_get_by_id(
    IN in_pk_refreshToken BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching the refresh token.',
            'code', 'INTERNAL_SERVER_ERROR');
        END;

    SELECT JSON_OBJECT(
        'success', TRUE,
        'message', 'Refresh token fetched successfully.',
        'code', 'SUCCESS_OK',
        'data', JSON_OBJECT(
            'pk_refreshToken', pk_refreshToken,
            'tokenHash', tokenHash,
            'expiresAt', expiresAt,
            'createdAt', createdAt,
            'revokedAt', revokedAt,
            'fk_appUser_refreshes', fk_appUser_refreshes
        )
    )
    INTO out_response
    FROM RefreshToken
    WHERE pk_refreshToken = in_pk_refreshToken;

END $$
