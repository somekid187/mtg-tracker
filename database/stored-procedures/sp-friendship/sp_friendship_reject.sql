USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_friendship_reject $$

CREATE PROCEDURE sp_friendship_reject(
    IN in_pk_friendship BIGINT,
    IN in_fk_receiver   BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE v_status     VARCHAR(20);
    DECLARE v_receiver   BIGINT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while rejecting the friend request.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    SELECT status, fk_appUser_receives
    INTO v_status, v_receiver
    FROM Friendship
    WHERE pk_friendship = in_pk_friendship;

    IF v_status IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Friend request not found.', 'code', 'FRIENDSHIP_NOT_FOUND');
        LEAVE proc;
    END IF;

    IF v_receiver <> in_fk_receiver THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Only the receiver can reject this request.', 'code', 'UNAUTHORIZED');
        LEAVE proc;
    END IF;

    IF v_status <> 'pending' THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'This request has already been responded to.', 'code', 'FRIENDSHIP_EXISTS');
        LEAVE proc;
    END IF;

    UPDATE Friendship
    SET status = 'rejected', updatedAt = NOW()
    WHERE pk_friendship = in_pk_friendship;

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Friend request rejected.', 'code', 'SUCCESS_UPDATED', 'data', JSON_OBJECT('pk_friendship', in_pk_friendship));
END $$

DELIMITER ;
