USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_commanderDamages_get $$

CREATE PROCEDURE sp_commanderDamages_get(
    IN in_page INT,
    OUT out_response JSON
)
proc:
BEGIN
    DECLARE offset INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching commander damages.', 'code', 'INTERNAL_SERVER_ERROR');
        END;
    SET offset = (in_page - 1) * 10;

    SELECT JSON_OBJECT(
                   'success', TRUE,
                   'message', 'Commander damages fetched successfully.',
                   'code', 'SUCCESS_OK',
                   'data', IFNULL(JSON_ARRAYAGG(
                                          JSON_OBJECT(
                                                  'pk_commanderDamage', pk_commanderDamage,
                                                  'damageAmount', damageAmount,
                                                  'isLethal', isLethal,
                                                  'fk_player_deals', fk_player_deals,
                                                  'fk_player_receives', fk_player_receives,
                                                  'fk_match_refersTo', fk_match_refersTo
                                          )
                                  ), JSON_ARRAY())
           )
    FROM (SELECT *
          FROM CommanderDamage
          ORDER BY pk_commanderDamage DESC
          LIMIT 10 OFFSET offset) AS CommanderDamage
    INTO out_response;
END $$

DELIMITER ;

