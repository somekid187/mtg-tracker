USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_guest_delete $$

CREATE PROCEDURE sp_guest_delete(
    IN in_pk_guest BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            -- Rollback transaction on error
            ROLLBACK;
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while deleting the guest.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    -- Start transaction
    START TRANSACTION;

    -- Check if guest exists
    IF NOT EXISTS (SELECT 1 FROM Guest WHERE pk_guest = in_pk_guest) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Guest not found.', 'code', 'GUEST_NOT_FOUND');
        LEAVE proc;
    END IF;

    -- Delete guest
    DELETE FROM Guest WHERE pk_guest = in_pk_guest;

    -- Commit transaction
    COMMIT;

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Guest deleted successfully.', 'code', 'SUCCESS_DELETED', 'data', JSON_OBJECT('pk_guest', in_pk_guest));
END $$

DELIMITER ;

