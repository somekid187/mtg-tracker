USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_matchs_get $$

CREATE PROCEDURE sp_matchs_get(
    IN in_page INT,
    OUT out_response JSON
)
proc:
BEGIN
    DECLARE offset INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching matches.');
        END;
    SET offset = (in_page - 1) * 10;


    SELECT JSON_OBJECT(
                   'success', TRUE,
                   'message', 'Matches fetched successfully.',
                   'data', IFNULL(JSON_ARRAYAGG(
                                          JSON_OBJECT(
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
                                  ), JSON_ARRAY())
           )
    FROM (SELECT *
          FROM `Match`
          ORDER BY startTime DESC
          LIMIT 10 OFFSET offset) AS `Match`
    INTO out_response;

END $$

DELIMITER ;
