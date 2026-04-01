USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_event_get_by_id $$

CREATE PROCEDURE sp_event_get_by_id(
    IN  in_pk_event   BIGINT,
    OUT out_response  JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while retrieving the event.', 'code', 'INTERNAL_SERVER_ERROR');
    END;

    IF NOT EXISTS (SELECT 1 FROM `Event` WHERE pk_event = in_pk_event) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Event not found.', 'code', 'EVENT_NOT_FOUND');
        LEAVE proc;
    END IF;

    SET out_response = (
        SELECT JSON_OBJECT(
            'success', TRUE,
            'message', 'Event retrieved successfully.',
            'code', 'SUCCESS',
            'data', JSON_OBJECT(
                'pk_event',          e.pk_event,
                'name',              e.name,
                'description',       e.description,
                'createdAt',         e.createdAt,
                'organizerId',       e.fk_appUser_organizes,
                'organizerUsername', au.username,
                'matchCount',        (SELECT COUNT(*) FROM EventMatch em WHERE em.fk_event_contains = e.pk_event)
            )
        )
        FROM `Event` e
        JOIN AppUser au ON e.fk_appUser_organizes = au.pk_appUser
        WHERE e.pk_event = in_pk_event
        LIMIT 1
    );
END $$

DELIMITER ;
