USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_player_get_by_id $$

CREATE PROCEDURE sp_player_get_by_id(
    IN in_pk_player BIGINT,
    OUT out_response JSON
)
proc:
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching the player.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    IF (in_pk_player IS NULL) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Player ID cannot be null.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Player WHERE pk_player = in_pk_player) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Player not found.', 'code', 'PLAYER_NOT_FOUND');
        LEAVE proc;
    END IF;

    SELECT JSON_OBJECT(
                   'success', TRUE,
                   'message', 'Player fetched successfully.',
                   'code', 'SUCCESS_OK',
                   'data', JSON_OBJECT(
                           'pk_player', pk_player,
                           'startingLife', startingLife,
                           'finalLife', finalLife,
                           'isWinner', isWinner,
                           'tax', tax,
                           'placement', placement,
                           'killCounter', killCounter,
                           'poisonCounter', poisonCounter,
                           'minPlayers', minPlayers,
                           'maxPlayers', maxPlayers,
                           'fk_guest_enters', fk_guest_enters,
                           'fk_appUser_participates', fk_appUser_participates,
                           'fk_team_isIncluded', fk_team_isIncluded,
                           'fk_match_isPlayedIn', fk_match_isPlayedIn
                           )
           )
    INTO out_response
    FROM Player
    WHERE pk_player = in_pk_player;
END $$

DELIMITER ;