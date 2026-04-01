USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_invite_send $$

CREATE PROCEDURE sp_invite_send(
    IN in_fk_inviter   BIGINT,
    IN in_fk_invitee   BIGINT,
    IN in_fk_match     BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while sending the invite.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    IF in_fk_inviter IS NULL OR in_fk_invitee IS NULL OR in_fk_match IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Inviter, invitee and match IDs are required.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF in_fk_inviter = in_fk_invitee THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'You cannot invite yourself.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM AppUser WHERE pk_appUser = in_fk_invitee) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Invitee user not found.', 'code', 'USER_NOT_FOUND');
        LEAVE proc;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM `Match` WHERE pk_match = in_fk_match) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Match not found.', 'code', 'MATCH_NOT_FOUND');
        LEAVE proc;
    END IF;

    IF EXISTS (
        SELECT 1 FROM Invites
        WHERE fk_player_isInvited = in_fk_invitee
          AND fk_match_hosts = in_fk_match
          AND status = 'pending'
    ) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'A pending invite for this user already exists for this match.', 'code', 'INVITE_EXISTS');
        LEAVE proc;
    END IF;

    INSERT INTO Invites (fk_player_invites, fk_player_isInvited, fk_match_hosts, status)
    VALUES (in_fk_inviter, in_fk_invitee, in_fk_match, 'pending');

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Invite sent.', 'code', 'SUCCESS_CREATED', 'data', JSON_OBJECT('pk_invite', LAST_INSERT_ID()));
END $$

DELIMITER ;
