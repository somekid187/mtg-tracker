USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_commanderDamage_get_by_id $$

CREATE PROCEDURE sp_commanderDamage_get_by_id(
    IN in_pk_commanderDamage BIGINT,
    OUT out_response JSON
)
proc:
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching the commander damage.');
        END;

    IF in_pk_commanderDamage IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Commander damage ID cannot be null.');
        LEAVE proc;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM CommanderDamage WHERE pk_commanderDamage = in_pk_commanderDamage) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Commander damage not found.');
        LEAVE proc;
    END IF;

    SELECT JSON_OBJECT(
                   'pk_commanderDamage', pk_commanderDamage,
                   'damageAmount', damageAmount,
                   'isLethal', isLethal,
                   'fk_player_deals', fk_player_deals,
                   'fk_player_receives', fk_player_receives,
                   'fk_match_refersTo', fk_match_refersTo
           )
    INTO out_response
    FROM CommanderDamage
    WHERE pk_commanderDamage = in_pk_commanderDamage;
END $$

DELIMITER ;

