USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_match_get_by_id $$

CREATE PROCEDURE sp_match_get_by_id(
    IN in_pk_match BIGINT,
    OUT out_response JSON
)
proc:
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching the match.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    IF (in_pk_match IS NULL) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Match ID cannot be null.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM `Match` WHERE pk_match = in_pk_match) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Match not found.', 'code', 'MATCH_NOT_FOUND');
        LEAVE proc;
    END IF;

    SELECT JSON_OBJECT(
                   'success', TRUE,
                   'message', 'Match fetched successfully.',
                   'code', 'SUCCESS_OK',
                   'data', JSON_OBJECT(
                           'pk_match', `Match`.pk_match,
                           'name', name,
                           'description', description,
                           'format', format,
                           'startingLife', startingLife,
                           'startTime', startTime,
                           'endTime', endTime,
                           'isTeamMatch', isTeamMatch,
                           'commanderThreshold', commanderThreshold,
                           'counterThreshold', counterThreshold,
                           'fk_appUser_creates', fk_appUser_creates
                           )
           )
    INTO out_response
    FROM `Match`
    WHERE pk_match = in_pk_match;
END $$

DELIMITER ;