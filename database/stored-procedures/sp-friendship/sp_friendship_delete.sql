USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_friendship_delete $$

CREATE PROCEDURE sp_friendship_delete(
    IN in_pk_friendship BIGINT,
    IN in_fk_appUser    BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE v_requester BIGINT;
    DECLARE v_receiver  BIGINT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while removing the friend.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    SELECT fk_appUser_requests, fk_appUser_receives
    INTO v_requester, v_receiver
    FROM Friendship
    WHERE pk_friendship = in_pk_friendship;

    IF v_requester IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Friendship not found.', 'code', 'FRIENDSHIP_NOT_FOUND');
        LEAVE proc;
    END IF;

    IF v_requester <> in_fk_appUser AND v_receiver <> in_fk_appUser THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'You are not part of this friendship.', 'code', 'UNAUTHORIZED');
        LEAVE proc;
    END IF;

    DELETE FROM Friendship WHERE pk_friendship = in_pk_friendship;

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Friendship removed.', 'code', 'SUCCESS_DELETED', 'data', JSON_OBJECT('pk_friendship', in_pk_friendship));
END $$

DELIMITER ;
