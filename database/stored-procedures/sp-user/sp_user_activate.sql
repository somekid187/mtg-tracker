USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_user_activate $$

CREATE PROCEDURE sp_user_activate(
    IN in_verificationToken VARCHAR(255),
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while activating the user.');
        END;

    UPDATE AppUser
    SET emailVerified = TRUE, verificationToken = NULL
    WHERE verificationToken = in_verificationToken;

    IF ROW_COUNT() = 0 THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Invalid verification token.');
        LEAVE proc;
    END IF;

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'User activated successfully.');
END $$