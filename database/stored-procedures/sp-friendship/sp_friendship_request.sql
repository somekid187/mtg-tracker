USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_friendship_request $$

CREATE PROCEDURE sp_friendship_request(
    IN in_fk_requester BIGINT,
    IN in_fk_receiver  BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while sending the friend request.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    IF in_fk_requester IS NULL OR in_fk_receiver IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Requester and receiver IDs are required.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM AppUser WHERE pk_appUser = in_fk_receiver) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Receiver user not found.', 'code', 'USER_NOT_FOUND');
        LEAVE proc;
    END IF;

    -- Check no existing friendship in either direction
    IF EXISTS (
        SELECT 1 FROM Friendship
        WHERE (fk_appUser_requests = in_fk_requester AND fk_appUser_receives = in_fk_receiver)
           OR (fk_appUser_requests = in_fk_receiver  AND fk_appUser_receives = in_fk_requester)
    ) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'A friendship or request already exists between these users.', 'code', 'FRIENDSHIP_EXISTS');
        LEAVE proc;
    END IF;

    INSERT INTO Friendship (fk_appUser_requests, fk_appUser_receives, status)
    VALUES (in_fk_requester, in_fk_receiver, 'pending');

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Friend request sent.', 'code', 'SUCCESS_CREATED', 'data', JSON_OBJECT('pk_friendship', LAST_INSERT_ID()));
END $$

DELIMITER ;
