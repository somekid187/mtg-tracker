USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_commanderDamage_update $$

CREATE PROCEDURE sp_commanderDamage_update(
    IN in_pk_commanderDamage BIGINT,
    IN in_damageAmount INT,
    IN in_isLethal TINYINT,
    IN in_fk_player_deals BIGINT,
    IN in_fk_player_receives BIGINT,
    IN in_fk_match_refersTo BIGINT,
    OUT out_response JSON
)
proc:
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while updating the commander damage.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    START TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM CommanderDamage WHERE pk_commanderDamage = in_pk_commanderDamage) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Commander damage not found.', 'code', 'COMMANDER_DAMAGE_NOT_FOUND');
        LEAVE proc;
    END IF;

    UPDATE CommanderDamage
    SET damageAmount       = COALESCE(in_damageAmount, damageAmount),
        isLethal           = COALESCE(in_isLethal, isLethal),
        fk_player_deals    = COALESCE(in_fk_player_deals, fk_player_deals),
        fk_player_receives = COALESCE(in_fk_player_receives, fk_player_receives),
        fk_match_refersTo  = COALESCE(in_fk_match_refersTo, fk_match_refersTo)
    WHERE pk_commanderDamage = in_pk_commanderDamage;

    IF ROW_COUNT() = 0 THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Commander damage not found or no changes made.', 'code', 'COMMANDER_DAMAGE_NOT_FOUND');
        LEAVE proc;
    END IF;

    COMMIT;

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Commander damage updated successfully.', 'code', 'SUCCESS_UPDATED', 'data', JSON_OBJECT('pk_commanderDamage', in_pk_commanderDamage));
END $$

DELIMITER ;

