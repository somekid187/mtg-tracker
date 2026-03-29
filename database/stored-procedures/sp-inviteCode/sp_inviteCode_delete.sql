USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_inviteCode_delete $$

CREATE PROCEDURE sp_inviteCode_delete(
    IN in_pk_inviteCode BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while deleting the invite code.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    START TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM InviteCode WHERE pk_inviteCode = in_pk_inviteCode) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Invite code not found.', 'code', 'INVITE_NOT_FOUND');
        LEAVE proc;
    END IF;

    DELETE FROM InviteCode WHERE pk_inviteCode = in_pk_inviteCode;

    COMMIT;
    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Invite code deleted successfully.', 'code', 'SUCCESS_DELETED', 'data', JSON_OBJECT('pk_inviteCode', in_pk_inviteCode));
END $$

DELIMITER ;

