USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_guest_get_by_id $$

CREATE PROCEDURE sp_guest_get_by_id(
    IN in_pk_guest BIGINT,
    OUT out_response JSON
)
proc:
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching the guest.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    IF in_pk_guest IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Guest ID cannot be null.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Guest WHERE pk_guest = in_pk_guest) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Guest not found.', 'code', 'GUEST_NOT_FOUND');
        LEAVE proc;
    END IF;

    SELECT JSON_OBJECT(
                   'success', TRUE,
                   'message', 'Guest fetched successfully.',
                   'code', 'SUCCESS_OK',
                   'data', JSON_OBJECT(
                       'pk_guest', pk_guest,
                       'guestName', guestName,
                       'createdAt', createdAt
                   )
           )
    INTO out_response
    FROM Guest
    WHERE pk_guest = in_pk_guest;
END $$

DELIMITER ;

