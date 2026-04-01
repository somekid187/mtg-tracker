USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_event_update $$

CREATE PROCEDURE sp_event_update(
    IN  in_pk_event     BIGINT,
    IN  in_name         VARCHAR(255),
    IN  in_description  TEXT,
    IN  in_userId       BIGINT,
    OUT out_response    JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while updating the event.', 'code', 'INTERNAL_SERVER_ERROR');
    END;

    IF NOT EXISTS (SELECT 1 FROM `Event` WHERE pk_event = in_pk_event AND fk_appUser_organizes = in_userId) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Event not found or you do not have permission.', 'code', 'EVENT_NOT_FOUND');
        LEAVE proc;
    END IF;

    UPDATE `Event`
    SET
        name        = COALESCE(in_name, name),
        description = COALESCE(in_description, description)
    WHERE pk_event = in_pk_event;

    SET out_response = JSON_OBJECT(
        'success', TRUE,
        'message', 'Event updated successfully.',
        'code', 'SUCCESS',
        'data', JSON_OBJECT('pk_event', in_pk_event)
    );
END $$

DELIMITER ;
