USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_match_create $$

CREATE PROCEDURE sp_match_create(
    IN in_name VARCHAR(255),
    IN in_description TEXT,
    IN in_format VARCHAR(255),
    IN in_startingLife INT,
    IN in_startTime TIME,
    IN in_isTeamMatch TINYINT,
    IN in_commanderThreshold INT,
    IN in_counterThreshold INT,
    IN in_fk_appUser_creates BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while creating the match.', 'code', 'INTERNAL_SERVER_ERROR');
        END;
    IF in_format IS NULL OR in_format = '' THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Match format cannot be empty.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF in_startingLife IS NULL OR in_startingLife <= 0 THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Starting life must be a positive integer.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF in_startTime IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Start time cannot be null.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF in_isTeamMatch IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'isTeamMatch cannot be null.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF in_fk_appUser_creates IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Creator user ID cannot be null.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM AppUser WHERE pk_appUser = in_fk_appUser_creates) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Creator user not found.', 'code', 'USER_NOT_FOUND');
        LEAVE proc;
    END IF;

    INSERT INTO `Match` (name, description, format, startingLife, startTime, isTeamMatch, commanderThreshold, counterThreshold, fk_appUser_creates)
    VALUES (in_name, in_description, in_format, in_startingLife, in_startTime,
            in_isTeamMatch, in_commanderThreshold, in_counterThreshold, in_fk_appUser_creates);

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Match created successfully.', 'code', 'SUCCESS_CREATED', 'data', JSON_OBJECT('pk_match', LAST_INSERT_ID()));
END $$

DELIMITER ;