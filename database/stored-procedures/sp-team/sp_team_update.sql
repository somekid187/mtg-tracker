USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_team_update $$

CREATE PROCEDURE sp_team_update(
    IN in_pk_team BIGINT,
    IN in_teamName VARCHAR(255),
    IN in_startingLife INT,
    IN in_finalLife INT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            -- Rollback transaction on error
            ROLLBACK;
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while updating the team.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    -- Start transaction
    START TRANSACTION;

    -- Check if team exists
    IF NOT EXISTS (SELECT 1 FROM Team WHERE pk_team = in_pk_team) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Team not found.', 'code', 'TEAM_NOT_FOUND');
        LEAVE proc;
    END IF;

    -- Update team information
    UPDATE Team
    SET name = COALESCE(in_teamName, name),
        startingLife = COALESCE(in_startingLife, startingLife),
        finalLife = COALESCE(in_finalLife, finalLife)
    WHERE pk_team = in_pk_team;

    -- Commit transaction
    COMMIT;

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Team updated successfully.', 'code', 'SUCCESS_UPDATED', 'data', JSON_OBJECT('pk_team', in_pk_team));
END $$

DELIMITER ;

