USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_friendships_get_by_user $$

CREATE PROCEDURE sp_friendships_get_by_user(
    IN in_fk_appUser BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching friendships.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    SET out_response = (
        SELECT JSON_OBJECT(
            'success', TRUE,
            'message', 'Friendships fetched successfully.',
            'code', 'SUCCESS',
            'data', COALESCE(JSON_ARRAYAGG(
                JSON_OBJECT(
                    'pk_friendship',  f.pk_friendship,
                    'status',         f.status,
                    'createdAt',      f.createdAt,
                    'friendId',       IF(f.fk_appUser_requests = in_fk_appUser, f.fk_appUser_receives, f.fk_appUser_requests),
                    'friendUsername', au.username
                )
            ), JSON_ARRAY())
        )
        FROM Friendship f
        JOIN AppUser au
          ON au.pk_appUser = IF(f.fk_appUser_requests = in_fk_appUser, f.fk_appUser_receives, f.fk_appUser_requests)
        WHERE (f.fk_appUser_requests = in_fk_appUser OR f.fk_appUser_receives = in_fk_appUser)
          AND f.status = 'accepted'
    );
END $$

DELIMITER ;
