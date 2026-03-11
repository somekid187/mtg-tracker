USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_inviteCode_create $$

CREATE PROCEDURE sp_inviteCode_create(
    IN in_code VARCHAR(255),
    IN in_expiresAt DATETIME,
    IN in_fk_match_connects BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while creating the invite code.');
        END;

    IF in_code IS NULL OR in_code = '' THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Invite code cannot be empty.');
        LEAVE proc;
    END IF;

    IF in_expiresAt IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Expiry date cannot be null.');
        LEAVE proc;
    END IF;

    IF in_fk_match_connects IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Match ID cannot be null.');
        LEAVE proc;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM `Match` WHERE pk_match = in_fk_match_connects) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Match not found.');
        LEAVE proc;
    END IF;

    INSERT INTO InviteCode (code, expiresAt, fk_match_connects)
    VALUES (in_code, in_expiresAt, in_fk_match_connects);

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Invite code created successfully.', 'inviteCodeId', LAST_INSERT_ID());
END $$

DELIMITER ;

