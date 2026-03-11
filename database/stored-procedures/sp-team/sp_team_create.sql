USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_team_create $$

CREATE PROCEDURE sp_team_create(
    IN in_teamName VARCHAR(255),
    IN in_startingLife INT,
    IN in_finalLife INT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while creating the team.');
        END;
    IF in_teamName IS NULL OR in_teamName = '' THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Team name cannot be empty.');
        LEAVE proc;
    END IF;

    INSERT INTO Team (name, startingLife, finalLife)
    VALUES (in_teamName, startingLife, finalLife);

    SET out_response =
            JSON_OBJECT('success', TRUE, 'message', 'Team created successfully.', 'teamId', LAST_INSERT_ID());
END $$

DELIMITER ;


