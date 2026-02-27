USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_guest_create $$

CREATE PROCEDURE sp_guest_create(
    IN in_guestName VARCHAR(255),
    OUT out_response JSON
)
proc:
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while creating the guest.');
        END;
    IF in_guestName IS NULL OR in_guestName = '' THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Guest name cannot be empty.');
        LEAVE proc;
    END IF;

    INSERT INTO Guest (guestName)
    VALUES (in_guestName);

    SET out_response =
            JSON_OBJECT('success', TRUE, 'message', 'Guest created successfully.', 'guestId', LAST_INSERT_ID());
END $$