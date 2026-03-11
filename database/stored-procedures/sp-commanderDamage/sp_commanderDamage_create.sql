USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_commanderDamage_create $$

CREATE PROCEDURE sp_commanderDamage_create(
    IN in_damageAmount INT,
    IN in_isLethal TINYINT,
    IN in_fk_player_deals BIGINT,
    IN in_fk_player_receives BIGINT,
    IN in_fk_match_refersTo BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while creating the commander damage.');
        END;

    IF in_fk_match_refersTo IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Match ID cannot be null.');
        LEAVE proc;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM `Match` WHERE pk_match = in_fk_match_refersTo) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Match not found.');
        LEAVE proc;
    END IF;

    IF in_fk_player_deals IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Player WHERE pk_player = in_fk_player_deals) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Dealing player not found.');
        LEAVE proc;
    END IF;

    IF in_fk_player_receives IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Player WHERE pk_player = in_fk_player_receives) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Receiving player not found.');
        LEAVE proc;
    END IF;

    INSERT INTO CommanderDamage (damageAmount, isLethal, fk_player_deals, fk_player_receives, fk_match_refersTo)
    VALUES (in_damageAmount, in_isLethal, in_fk_player_deals, in_fk_player_receives, in_fk_match_refersTo);

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Commander damage created successfully.', 'commanderDamageId', LAST_INSERT_ID());
END $$

DELIMITER ;

