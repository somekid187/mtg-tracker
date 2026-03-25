USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_teams_get $$

CREATE PROCEDURE sp_teams_get(
    IN in_page INT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE offset INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching teams.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    SET offset = (in_page - 1) * 10;

    SELECT JSON_OBJECT(
        'success', TRUE,
        'message', 'Teams fetched successfully.',
        'code', 'SUCCESS_OK',
        'data', IFNULL(JSON_ARRAYAGG(
            JSON_OBJECT(
                'pk_team', pk_team,
                'name', name,
                'startingLife', startingLife,
                'finalLife', finalLife
            )
        ), JSON_ARRAY())
    )
    INTO out_response
    FROM (
        SELECT pk_team, name, startingLife, finalLife
        FROM Team
        ORDER BY name
        LIMIT 10 OFFSET offset
    ) AS teams;


END $$

DELIMITER ;


