USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_inviteCode_update $$

CREATE PROCEDURE sp_inviteCode_update(
    IN in_pk_inviteCode BIGINT,
    IN in_code VARCHAR(255),
    IN in_status ENUM('active', 'expired'),
    IN in_expiresAt DATETIME,
    OUT out_response JSON
)
proc:
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while updating the invite code.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    START TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM InviteCode WHERE pk_inviteCode = in_pk_inviteCode) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Invite code not found.', 'code', 'INVITE_NOT_FOUND');
        LEAVE proc;
    END IF;

    UPDATE InviteCode
    SET code      = COALESCE(in_code, code),
        status    = COALESCE(in_status, status),
        expiresAt = COALESCE(in_expiresAt, expiresAt)
    WHERE pk_inviteCode = in_pk_inviteCode;

    IF ROW_COUNT() = 0 THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Invite code not found or no changes made.', 'code', 'INVITE_NOT_FOUND');
        LEAVE proc;
    END IF;

    COMMIT;

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Invite code updated successfully.', 'code', 'SUCCESS_UPDATED', 'data', JSON_OBJECT('pk_inviteCode', in_pk_inviteCode));
END $$

DELIMITER ;

