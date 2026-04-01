USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_invites_get_by_match $$

CREATE PROCEDURE sp_invites_get_by_match(
    IN in_fk_match     BIGINT,
    IN in_fk_inviter   BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching match invites.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    IF NOT EXISTS (SELECT 1 FROM `Match` WHERE pk_match = in_fk_match AND fk_appUser_creates = in_fk_inviter) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Match not found or you are not the host.', 'code', 'UNAUTHORIZED');
        LEAVE proc;
    END IF;

    SET out_response = (
        SELECT JSON_OBJECT(
            'success', TRUE,
            'message', 'Match invites fetched successfully.',
            'code', 'SUCCESS',
            'data', COALESCE(JSON_ARRAYAGG(
                JSON_OBJECT(
                    'pk_invite',       i.pk_invite,
                    'status',          i.status,
                    'createdAt',       i.createdAt,
                    'updatedAt',       i.updatedAt,
                    'inviteeId',       i.fk_player_isInvited,
                    'inviteeUsername', au.username
                )
            ), JSON_ARRAY())
        )
        FROM Invites i
        JOIN AppUser au ON au.pk_appUser = i.fk_player_isInvited
        WHERE i.fk_match_hosts = in_fk_match
    );
END $$

DELIMITER ;
