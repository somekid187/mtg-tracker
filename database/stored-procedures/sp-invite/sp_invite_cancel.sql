USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_invite_cancel $$

CREATE PROCEDURE sp_invite_cancel(
    IN in_pk_invite    BIGINT,
    IN in_fk_inviter   BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE v_inviter   BIGINT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while cancelling the invite.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    SELECT fk_player_invites
    INTO v_inviter
    FROM Invites
    WHERE pk_invite = in_pk_invite;

    IF v_inviter IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Invite not found.', 'code', 'INVITE_NOT_FOUND');
        LEAVE proc;
    END IF;

    IF v_inviter <> in_fk_inviter THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Only the inviter can cancel this invite.', 'code', 'UNAUTHORIZED');
        LEAVE proc;
    END IF;

    DELETE FROM Invites WHERE pk_invite = in_pk_invite;

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Invite cancelled.', 'code', 'SUCCESS_DELETED', 'data', JSON_OBJECT('pk_invite', in_pk_invite));
END $$

DELIMITER ;
