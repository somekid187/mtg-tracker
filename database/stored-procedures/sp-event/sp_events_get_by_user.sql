USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_events_get_by_user $$

CREATE PROCEDURE sp_events_get_by_user(
    IN  in_userId     BIGINT,
    OUT out_response  JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while retrieving events.', 'code', 'INTERNAL_SERVER_ERROR');
    END;

    SET out_response = JSON_OBJECT(
        'success', TRUE,
        'message', 'Events retrieved successfully.',
        'code', 'SUCCESS',
        'data', IFNULL(
            (SELECT JSON_ARRAYAGG(obj) FROM (
                SELECT JSON_OBJECT(
                    'pk_event',    e.pk_event,
                    'name',        e.name,
                    'description', e.description,
                    'createdAt',   e.createdAt,
                    'matchCount',  (SELECT COUNT(*) FROM EventMatch em WHERE em.fk_event_contains = e.pk_event)
                ) AS obj
                FROM `Event` e
                WHERE e.fk_appUser_organizes = in_userId
                ORDER BY e.createdAt DESC
            ) subq),
            JSON_ARRAY()
        )
    );
END $$

DELIMITER ;
