USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_event_create $$

CREATE PROCEDURE sp_event_create(
    IN  in_name          VARCHAR(255),
    IN  in_description   TEXT,
    IN  in_fk_appUser    BIGINT,
    OUT out_response     JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while creating the event.', 'code', 'INTERNAL_SERVER_ERROR');
    END;

    IF in_name IS NULL OR TRIM(in_name) = '' THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Event name cannot be empty.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM AppUser WHERE pk_appUser = in_fk_appUser) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'User not found.', 'code', 'USER_NOT_FOUND');
        LEAVE proc;
    END IF;

    INSERT INTO `Event` (name, description, fk_appUser_organizes)
    VALUES (in_name, in_description, in_fk_appUser);

    SET out_response = JSON_OBJECT(
        'success', TRUE,
        'message', 'Event created successfully.',
        'code', 'SUCCESS_CREATED',
        'data', JSON_OBJECT('pk_event', LAST_INSERT_ID())
    );
END $$

DELIMITER ;
