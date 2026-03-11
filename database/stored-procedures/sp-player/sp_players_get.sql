USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_players_get $$

CREATE PROCEDURE sp_players_get(
    IN in_page INT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE offset INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching players.');
        END;

    SET offset = (in_page - 1) * 10;

    SELECT JSON_OBJECT(
        'success', TRUE,
        'message', 'Players fetched successfully.',
        'data', IFNULL(JSON_ARRAYAGG(
            JSON_OBJECT(
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
        ), JSON_ARRAY())
    )
    INTO out_response
    FROM (
        SELECT pk_player, startingLife, finalLife, isWinner, tax, placement, killCounter, poisonCounter, minPlayers, maxPlayers, fk_guest_enters, fk_appUser_participates, fk_team_isIncluded, fk_match_isPlayedIn
        FROM Player
        ORDER BY pk_player
        LIMIT 10 OFFSET offset
    ) AS players;

END $$

DELIMITER ;