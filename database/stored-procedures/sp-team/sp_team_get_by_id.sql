USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_team_get_by_id $$

CREATE PROCEDURE sp_team_get_by_id(
    IN in_pk_team BIGINT,
    OUT out_response JSON
)
proc:
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching the team.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    IF (in_pk_team IS NULL) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Team ID cannot be null.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Team WHERE pk_team = in_pk_team) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Team not found.', 'code', 'TEAM_NOT_FOUND');
        LEAVE proc;
    END IF;

    SELECT JSON_OBJECT(
                   'success', TRUE,
                   'message', 'Team fetched successfully.',
                   'code', 'SUCCESS_OK',
                   'data', JSON_OBJECT(
                           'pk_team', pk_team,
                           'name', name,
                           'startingLife', startingLife,
                           'finalLife', finalLife
                           )
           )
    INTO out_response
    FROM Team
    WHERE pk_team = in_pk_team;
END $$

DELIMITER ;