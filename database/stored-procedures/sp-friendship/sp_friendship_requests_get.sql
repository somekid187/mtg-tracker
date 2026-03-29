USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_friendship_requests_get $$

CREATE PROCEDURE sp_friendship_requests_get(
    IN in_fk_appUser BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching friend requests.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    SET out_response = (
        SELECT JSON_OBJECT(
            'success', TRUE,
            'message', 'Friend requests fetched successfully.',
            'code', 'SUCCESS',
            'data', COALESCE(JSON_ARRAYAGG(
                JSON_OBJECT(
                    'pk_friendship',      f.pk_friendship,
                    'createdAt',          f.createdAt,
                    'requesterId',        f.fk_appUser_requests,
                    'requesterUsername',  au.username
                )
            ), JSON_ARRAY())
        )
        FROM Friendship f
        JOIN AppUser au ON au.pk_appUser = f.fk_appUser_requests
        WHERE f.fk_appUser_receives = in_fk_appUser
          AND f.status = 'pending'
    );
END $$

DELIMITER ;
