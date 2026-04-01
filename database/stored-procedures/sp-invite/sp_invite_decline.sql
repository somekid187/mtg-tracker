USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_invite_decline $$

CREATE PROCEDURE sp_invite_decline(
    IN in_pk_invite    BIGINT,
    IN in_fk_invitee   BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE v_status    VARCHAR(20);
    DECLARE v_invitee   BIGINT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while declining the invite.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    SELECT status, fk_player_isInvited
    INTO v_status, v_invitee
    FROM Invites
    WHERE pk_invite = in_pk_invite;

    IF v_status IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Invite not found.', 'code', 'INVITE_NOT_FOUND');
        LEAVE proc;
    END IF;

    IF v_invitee <> in_fk_invitee THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Only the invited user can decline this invite.', 'code', 'UNAUTHORIZED');
        LEAVE proc;
    END IF;

    IF v_status <> 'pending' THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'This invite has already been responded to.', 'code', 'INVITE_ALREADY_RESPONDED');
        LEAVE proc;
    END IF;

    UPDATE Invites
    SET status = 'declined', updatedAt = NOW()
    WHERE pk_invite = in_pk_invite;

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Invite declined.', 'code', 'SUCCESS_UPDATED', 'data', JSON_OBJECT('pk_invite', in_pk_invite));
END $$

DELIMITER ;
