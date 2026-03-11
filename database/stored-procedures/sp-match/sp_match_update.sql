USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_match_update $$

CREATE PROCEDURE sp_match_update(
    IN in_pk_match BIGINT,
    IN in_name VARCHAR(255),
    IN in_description TEXT,
    IN in_format VARCHAR(255),
    IN in_startingLife INT,
    IN in_startTime TIME,
    IN in_isTeamMatch TINYINT,
    IN in_commanderThreshold INT,
    IN in_counterThreshold INT,
    OUT out_response JSON
)
proc:
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            -- Rollback transaction on error
            ROLLBACK;
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while updating the user.');
        END;

    -- Start transaction
    START TRANSACTION;

    UPDATE `Match`
    SET name = COALESCE(in_name, name),
        description = COALESCE(in_description, description),
        format = COALESCE(in_format, format),
        startingLife = COALESCE(in_startingLife, startingLife),
        startTime = COALESCE(in_startTime, startTime),
        isTeamMatch = COALESCE(in_isTeamMatch, isTeamMatch),
        commanderThreshold = COALESCE(in_commanderThreshold, commanderThreshold),
        counterThreshold = COALESCE(in_counterThreshold, counterThreshold)
    WHERE pk_match = in_pk_match;

    -- Check if any row was updated
    IF ROW_COUNT() = 0 THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Match not found or no changes made.');
        LEAVE proc;
    END IF;

    -- Commit transaction
    COMMIT;

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Match updated successfully.');

END $$

DELIMITER ;
