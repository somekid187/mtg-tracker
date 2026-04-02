USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_event_match_add $$

CREATE PROCEDURE sp_event_match_add(
    IN  in_eventId    BIGINT,
    IN  in_matchId    BIGINT,
    IN  in_userId     BIGINT,
    OUT out_response  JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while adding the match to the event.', 'code', 'INTERNAL_SERVER_ERROR');
    END;

    IF NOT EXISTS (SELECT 1 FROM `Event` WHERE pk_event = in_eventId AND fk_appUser_organizes = in_userId) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Event not found or you do not have permission.', 'code', 'EVENT_NOT_FOUND');
        LEAVE proc;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM `Match` WHERE pk_match = in_matchId) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Match not found.', 'code', 'MATCH_NOT_FOUND');
        LEAVE proc;
    END IF;

    IF EXISTS (SELECT 1 FROM Organizes WHERE pkfk_event = in_eventId AND pkfk_match = in_matchId) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Match is already in this event.', 'code', 'ALREADY_IN_EVENT');
        LEAVE proc;
    END IF;

    INSERT INTO Organizes (pkfk_event, pkfk_match)
    VALUES (in_eventId, in_matchId);

    SET out_response = JSON_OBJECT(
        'success', TRUE,
        'message', 'Match added to event successfully.',
        'code', 'SUCCESS_CREATED',
        'data', JSON_OBJECT('eventId', in_eventId, 'matchId', in_matchId)
    );
END $$

DELIMITER ;
