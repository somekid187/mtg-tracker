USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_inviteCode_get_by_id $$

CREATE PROCEDURE sp_inviteCode_get_by_id(
    IN in_pk_inviteCode BIGINT,
    OUT out_response JSON
)
proc:
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching the invite code.');
        END;

    IF in_pk_inviteCode IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Invite code ID cannot be null.');
        LEAVE proc;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM InviteCode WHERE pk_inviteCode = in_pk_inviteCode) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Invite code not found.');
        LEAVE proc;
    END IF;

    SELECT JSON_OBJECT(
                   'pk_inviteCode', pk_inviteCode,
                   'code', code,
                   'status', status,
                   'createdAt', createdAt,
                   'expiresAt', expiresAt,
                   'fk_match_connects', fk_match_connects
           )
    INTO out_response
    FROM InviteCode
    WHERE pk_inviteCode = in_pk_inviteCode;
END $$

DELIMITER ;

