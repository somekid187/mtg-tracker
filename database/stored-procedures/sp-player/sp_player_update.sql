USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_player_update $$

CREATE PROCEDURE sp_player_update(
    IN in_pk_player BIGINT,
    IN in_startingLife INT,
    IN in_finalLife INT,
    IN in_isWinner BOOLEAN,
    IN in_tax INT,
    IN in_placement INT,
    IN in_killCounter INT,
    IN in_poisonCounter INT,
    IN in_minPlayers INT,
    IN in_maxPlayers INT,
    IN in_fk_team_isIncluded INT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            -- Rollback transaction on error
            ROLLBACK;
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while updating the player.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    -- Start transaction
    START TRANSACTION;
    -- Check if player exists
    IF NOT EXISTS (SELECT 1 FROM Player WHERE pk_player = in_pk_player) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Player not found.', 'code', 'PLAYER_NOT_FOUND');
        LEAVE proc;
    END IF;

    IF in_fk_team_isIncluded IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Team WHERE pk_team = in_fk_team_isIncluded) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Team not found for the provided fk_team_isIncluded.', 'code', 'TEAM_NOT_FOUND');
        LEAVE proc;
    END IF;

    -- Update player information
    UPDATE Player
    SET startingLife = COALESCE(in_startingLife, startingLife),
        finalLife = COALESCE(in_finalLife, finalLife),
        isWinner = COALESCE(in_isWinner, isWinner),
        tax = COALESCE(in_tax, tax),
        placement = COALESCE(in_placement, placement),
        killCounter = COALESCE(in_killCounter, killCounter),
        poisonCounter = COALESCE(in_poisonCounter, poisonCounter),
        minPlayers = COALESCE(in_minPlayers, minPlayers),
        maxPlayers = COALESCE(in_maxPlayers, maxPlayers),
        fk_team_isIncluded = COALESCE(in_fk_team_isIncluded, fk_team_isIncluded)
    WHERE pk_player = in_pk_player;

    -- Commit transaction
    COMMIT;

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Player updated successfully.', 'code', 'SUCCESS_UPDATED', 'data', JSON_OBJECT('pk_player', in_pk_player));
END $$

DELIMITER ;