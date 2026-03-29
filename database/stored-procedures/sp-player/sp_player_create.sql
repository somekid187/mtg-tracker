USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_player_create $$

CREATE PROCEDURE sp_player_create(
    IN in_startingLife INT,
    IN in_isWinner BOOLEAN,
    IN in_tax INT,
    IN in_placement INT,
    IN in_killCounter INT,
    IN in_poisonCounter INT,
    IN in_minPlayers INT,
    IN in_maxPlayers INT,
    IN in_fk_guest_enters BIGINT,
    IN in_fk_appUser_participates BIGINT,
    IN in_fk_team_isIncluded INT,
    IN in_fk_match_isPlayedIn BIGINT,
    OUT out_response JSON
)
proc:
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while creating the player.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    IF in_startingLife IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Starting life cannot be null.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF in_placement IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Placement cannot be null.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF in_minPlayers IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Minimum players cannot be null.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF in_maxPlayers IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Maximum players cannot be null.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF in_fk_match_isPlayedIn IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Match ID cannot be null.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM `Match` WHERE pk_match = in_fk_match_isPlayedIn) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Match not found.', 'code', 'MATCH_NOT_FOUND');
        LEAVE proc;
    END IF;

    IF in_fk_appUser_participates IS NOT NULL AND
       NOT EXISTS (SELECT 1 FROM AppUser WHERE pk_appUser = in_fk_appUser_participates) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Participating user not found.', 'code', 'USER_NOT_FOUND');
        LEAVE proc;
    END IF;

    IF in_fk_team_isIncluded IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Team WHERE pk_team = in_fk_team_isIncluded) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Team not found.', 'code', 'TEAM_NOT_FOUND');
        LEAVE proc;
    END IF;

    IF in_fk_guest_enters IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Guest WHERE pk_guest = in_fk_guest_enters) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Guest not found.', 'code', 'GUEST_NOT_FOUND');
        LEAVE proc;
    END IF;

    INSERT INTO Player (startingLife, isWinner, tax, placement, killCounter, poisonCounter, minPlayers,
                        maxPlayers, fk_guest_enters, fk_appUser_participates, fk_team_isIncluded, fk_match_isPlayedIn)
    VALUES (in_startingLife, in_isWinner, in_tax, in_placement,
            in_killCounter, in_poisonCounter, in_minPlayers, in_maxPlayers,
            in_fk_guest_enters, in_fk_appUser_participates, in_fk_team_isIncluded,
            in_fk_match_isPlayedIn);

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Player created successfully.', 'code', 'SUCCESS_CREATED', 'data', JSON_OBJECT('pk_player', LAST_INSERT_ID()));

END $$

DELIMITER ;