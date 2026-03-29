USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_team_delete $$

CREATE PROCEDURE sp_team_delete(
    IN in_pk_team BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            -- Rollback transaction on error
            ROLLBACK;
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while deleting the team.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    -- Start transaction
    START TRANSACTION;

    -- Check if team exists
    IF NOT EXISTS (SELECT 1 FROM Team WHERE pk_team = in_pk_team) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Team not found.', 'code', 'TEAM_NOT_FOUND');
        LEAVE proc;
    END IF;

    -- Delete team
    DELETE FROM Team WHERE pk_team = in_pk_team;

    -- Commit transaction
    COMMIT;

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Team deleted successfully.', 'code', 'SUCCESS_DELETED', 'data', JSON_OBJECT('pk_team', in_pk_team));

END $$

DELIMITER ;