USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_guest_update $$

CREATE PROCEDURE sp_guest_update(
    IN in_pk_guest BIGINT,
    IN in_guestName VARCHAR(255),
    OUT out_response JSON
)
proc:
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while updating the guest.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    START TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM Guest WHERE pk_guest = in_pk_guest) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Guest not found.', 'code', 'GUEST_NOT_FOUND');
        LEAVE proc;
    END IF;

    UPDATE Guest
    SET guestName = COALESCE(in_guestName, guestName)
    WHERE pk_guest = in_pk_guest;

    IF ROW_COUNT() = 0 THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Guest not found or no changes made.', 'code', 'GUEST_NOT_FOUND');
        LEAVE proc;
    END IF;

    COMMIT;

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Guest updated successfully.', 'code', 'SUCCESS_UPDATED', 'data', JSON_OBJECT('pk_guest', in_pk_guest));
END $$

DELIMITER ;

