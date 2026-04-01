USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_invites_get_pending $$

CREATE PROCEDURE sp_invites_get_pending(
    IN in_fk_invitee   BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching pending invites.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    SET out_response = (
        SELECT JSON_OBJECT(
            'success', TRUE,
            'message', 'Pending invites fetched successfully.',
            'code', 'SUCCESS',
            'data', COALESCE(JSON_ARRAYAGG(
                JSON_OBJECT(
                    'pk_invite',      i.pk_invite,
                    'status',         i.status,
                    'createdAt',      i.createdAt,
                    'matchId',        i.fk_match_hosts,
                    'matchName',      m.name,
                    'matchFormat',    m.format,
                    'startingLife',   m.startingLife,
                    'inviterId',      i.fk_player_invites,
                    'inviterUsername', au.username
                )
            ), JSON_ARRAY())
        )
        FROM Invites i
        JOIN `Match`  m  ON m.pk_match    = i.fk_match_hosts
        JOIN AppUser  au ON au.pk_appUser  = i.fk_player_invites
        WHERE i.fk_player_isInvited = in_fk_invitee
          AND i.status = 'pending'
    );
END $$

DELIMITER ;
