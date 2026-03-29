USE `mtg-tracker`;
DELIMITER $$
DROP PROCEDURE IF EXISTS sp_commanderDamage_create $$

CREATE PROCEDURE sp_commanderDamage_create(
    IN in_damageAmount INT,
    IN in_isLethal TINYINT,
    IN in_fk_player_deals BIGINT,
    IN in_fk_player_receives BIGINT,
    IN in_fk_match_refersTo BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while creating the commander damage.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    IF in_fk_match_refersTo IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Match ID cannot be null.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM `Match` WHERE pk_match = in_fk_match_refersTo) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Match not found.', 'code', 'MATCH_NOT_FOUND');
        LEAVE proc;
    END IF;

    IF in_fk_player_deals IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Player WHERE pk_player = in_fk_player_deals) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Dealing player not found.', 'code', 'PLAYER_NOT_FOUND');
        LEAVE proc;
    END IF;

    IF in_fk_player_receives IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Player WHERE pk_player = in_fk_player_receives) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Receiving player not found.', 'code', 'PLAYER_NOT_FOUND');
        LEAVE proc;
    END IF;

    INSERT INTO CommanderDamage (damageAmount, isLethal, fk_player_deals, fk_player_receives, fk_match_refersTo)
    VALUES (in_damageAmount, in_isLethal, in_fk_player_deals, in_fk_player_receives, in_fk_match_refersTo);

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Commander damage created successfully.', 'code', 'SUCCESS_CREATED', 'data', JSON_OBJECT('pk_commanderDamage', LAST_INSERT_ID()));
END $$

DROP PROCEDURE IF EXISTS sp_commanderDamage_delete $$

CREATE PROCEDURE sp_commanderDamage_delete(
    IN in_pk_commanderDamage BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while deleting the commander damage.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    START TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM CommanderDamage WHERE pk_commanderDamage = in_pk_commanderDamage) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Commander damage not found.', 'code', 'COMMANDER_DAMAGE_NOT_FOUND');
        LEAVE proc;
    END IF;

    DELETE FROM CommanderDamage WHERE pk_commanderDamage = in_pk_commanderDamage;

    COMMIT;
    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Commander damage deleted successfully.', 'code', 'SUCCESS_DELETED', 'data', JSON_OBJECT('pk_commanderDamage', in_pk_commanderDamage));
END $$

DROP PROCEDURE IF EXISTS sp_commanderDamage_get_by_id $$

CREATE PROCEDURE sp_commanderDamage_get_by_id(
    IN in_pk_commanderDamage BIGINT,
    OUT out_response JSON
)
proc:
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching the commander damage.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    IF in_pk_commanderDamage IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Commander damage ID cannot be null.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM CommanderDamage WHERE pk_commanderDamage = in_pk_commanderDamage) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Commander damage not found.', 'code', 'COMMANDER_DAMAGE_NOT_FOUND');
        LEAVE proc;
    END IF;

    SELECT JSON_OBJECT(
                   'success', TRUE,
                   'message', 'Commander damage fetched successfully.',
                   'code', 'SUCCESS_OK',
                   'data', JSON_OBJECT(
                       'pk_commanderDamage', pk_commanderDamage,
                       'damageAmount', damageAmount,
                       'isLethal', isLethal,
                       'fk_player_deals', fk_player_deals,
                       'fk_player_receives', fk_player_receives,
                       'fk_match_refersTo', fk_match_refersTo
                   )
           )
    INTO out_response
    FROM CommanderDamage
    WHERE pk_commanderDamage = in_pk_commanderDamage;
END $$

DROP PROCEDURE IF EXISTS sp_commanderDamage_update $$

CREATE PROCEDURE sp_commanderDamage_update(
    IN in_pk_commanderDamage BIGINT,
    IN in_damageAmount INT,
    IN in_isLethal TINYINT,
    IN in_fk_player_deals BIGINT,
    IN in_fk_player_receives BIGINT,
    IN in_fk_match_refersTo BIGINT,
    OUT out_response JSON
)
proc:
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while updating the commander damage.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    START TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM CommanderDamage WHERE pk_commanderDamage = in_pk_commanderDamage) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Commander damage not found.', 'code', 'COMMANDER_DAMAGE_NOT_FOUND');
        LEAVE proc;
    END IF;

    UPDATE CommanderDamage
    SET damageAmount       = COALESCE(in_damageAmount, damageAmount),
        isLethal           = COALESCE(in_isLethal, isLethal),
        fk_player_deals    = COALESCE(in_fk_player_deals, fk_player_deals),
        fk_player_receives = COALESCE(in_fk_player_receives, fk_player_receives),
        fk_match_refersTo  = COALESCE(in_fk_match_refersTo, fk_match_refersTo)
    WHERE pk_commanderDamage = in_pk_commanderDamage;

    IF ROW_COUNT() = 0 THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Commander damage not found or no changes made.', 'code', 'COMMANDER_DAMAGE_NOT_FOUND');
        LEAVE proc;
    END IF;

    COMMIT;

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Commander damage updated successfully.', 'code', 'SUCCESS_UPDATED', 'data', JSON_OBJECT('pk_commanderDamage', in_pk_commanderDamage));
END $$

DROP PROCEDURE IF EXISTS sp_commanderDamages_get $$

CREATE PROCEDURE sp_commanderDamages_get(
    IN in_page INT,
    OUT out_response JSON
)
proc:
BEGIN
    DECLARE offset INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching commander damages.', 'code', 'INTERNAL_SERVER_ERROR');
        END;
    SET offset = (in_page - 1) * 10;

    SELECT JSON_OBJECT(
                   'success', TRUE,
                   'message', 'Commander damages fetched successfully.',
                   'code', 'SUCCESS_OK',
                   'data', IFNULL(JSON_ARRAYAGG(
                                          JSON_OBJECT(
                                                  'pk_commanderDamage', pk_commanderDamage,
                                                  'damageAmount', damageAmount,
                                                  'isLethal', isLethal,
                                                  'fk_player_deals', fk_player_deals,
                                                  'fk_player_receives', fk_player_receives,
                                                  'fk_match_refersTo', fk_match_refersTo
                                          )
                                  ), JSON_ARRAY())
           )
    FROM (SELECT *
          FROM CommanderDamage
          ORDER BY pk_commanderDamage DESC
          LIMIT 10 OFFSET offset) AS CommanderDamage
    INTO out_response;
END $$

DROP PROCEDURE IF EXISTS sp_friendship_accept $$

CREATE PROCEDURE sp_friendship_accept(
    IN in_pk_friendship BIGINT,
    IN in_fk_receiver   BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE v_status     VARCHAR(20);
    DECLARE v_receiver   BIGINT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while accepting the friend request.', 'code', 'INTERNAL_SERVER_ERROR');
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
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Only the receiver can accept this request.', 'code', 'UNAUTHORIZED');
        LEAVE proc;
    END IF;

    IF v_status <> 'pending' THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'This request has already been responded to.', 'code', 'FRIENDSHIP_EXISTS');
        LEAVE proc;
    END IF;

    UPDATE Friendship
    SET status = 'accepted', updatedAt = NOW()
    WHERE pk_friendship = in_pk_friendship;

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Friend request accepted.', 'code', 'SUCCESS_UPDATED', 'data', JSON_OBJECT('pk_friendship', in_pk_friendship));
END $$

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

DROP PROCEDURE IF EXISTS sp_friendship_requests_get $$

CREATE PROCEDURE sp_friendship_requests_get(
    IN in_fk_appUser BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching friend requests.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    SET out_response = (
        SELECT JSON_OBJECT(
            'success', TRUE,
            'message', 'Friend requests fetched successfully.',
            'code', 'SUCCESS',
            'data', COALESCE(JSON_ARRAYAGG(
                JSON_OBJECT(
                    'pk_friendship',      f.pk_friendship,
                    'createdAt',          f.createdAt,
                    'requesterId',        f.fk_appUser_requests,
                    'requesterUsername',  au.username
                )
            ), JSON_ARRAY())
        )
        FROM Friendship f
        JOIN AppUser au ON au.pk_appUser = f.fk_appUser_requests
        WHERE f.fk_appUser_receives = in_fk_appUser
          AND f.status = 'pending'
    );
END $$

DROP PROCEDURE IF EXISTS sp_friendships_get_by_user $$

CREATE PROCEDURE sp_friendships_get_by_user(
    IN in_fk_appUser BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching friendships.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    SET out_response = (
        SELECT JSON_OBJECT(
            'success', TRUE,
            'message', 'Friendships fetched successfully.',
            'code', 'SUCCESS',
            'data', COALESCE(JSON_ARRAYAGG(
                JSON_OBJECT(
                    'pk_friendship',  f.pk_friendship,
                    'status',         f.status,
                    'createdAt',      f.createdAt,
                    'friendId',       IF(f.fk_appUser_requests = in_fk_appUser, f.fk_appUser_receives, f.fk_appUser_requests),
                    'friendUsername', au.username
                )
            ), JSON_ARRAY())
        )
        FROM Friendship f
        JOIN AppUser au
          ON au.pk_appUser = IF(f.fk_appUser_requests = in_fk_appUser, f.fk_appUser_receives, f.fk_appUser_requests)
        WHERE (f.fk_appUser_requests = in_fk_appUser OR f.fk_appUser_receives = in_fk_appUser)
          AND f.status = 'accepted'
    );
END $$

DROP PROCEDURE IF EXISTS sp_guest_create $$

CREATE PROCEDURE sp_guest_create(
    IN in_guestName VARCHAR(255),
    OUT out_response JSON
)
proc:
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while creating the guest.', 'code', 'INTERNAL_SERVER_ERROR');
        END;
    IF in_guestName IS NULL OR in_guestName = '' THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Guest name cannot be empty.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    INSERT INTO Guest (guestName)
    VALUES (in_guestName);

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Guest created successfully.', 'code', 'SUCCESS_CREATED', 'data', JSON_OBJECT('pk_guest', LAST_INSERT_ID()));
END $$

DROP PROCEDURE IF EXISTS sp_guest_delete $$

CREATE PROCEDURE sp_guest_delete(
    IN in_pk_guest BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            -- Rollback transaction on error
            ROLLBACK;
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while deleting the guest.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    -- Start transaction
    START TRANSACTION;

    -- Check if guest exists
    IF NOT EXISTS (SELECT 1 FROM Guest WHERE pk_guest = in_pk_guest) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Guest not found.', 'code', 'GUEST_NOT_FOUND');
        LEAVE proc;
    END IF;

    -- Delete guest
    DELETE FROM Guest WHERE pk_guest = in_pk_guest;

    -- Commit transaction
    COMMIT;

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Guest deleted successfully.', 'code', 'SUCCESS_DELETED', 'data', JSON_OBJECT('pk_guest', in_pk_guest));
END $$

DROP PROCEDURE IF EXISTS sp_guest_get_by_id $$

CREATE PROCEDURE sp_guest_get_by_id(
    IN in_pk_guest BIGINT,
    OUT out_response JSON
)
proc:
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching the guest.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    IF in_pk_guest IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Guest ID cannot be null.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Guest WHERE pk_guest = in_pk_guest) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Guest not found.', 'code', 'GUEST_NOT_FOUND');
        LEAVE proc;
    END IF;

    SELECT JSON_OBJECT(
                   'success', TRUE,
                   'message', 'Guest fetched successfully.',
                   'code', 'SUCCESS_OK',
                   'data', JSON_OBJECT(
                       'pk_guest', pk_guest,
                       'guestName', guestName,
                       'createdAt', createdAt
                   )
           )
    INTO out_response
    FROM Guest
    WHERE pk_guest = in_pk_guest;
END $$

DROP PROCEDURE IF EXISTS sp_guest_update $$

CREATE PROCEDURE sp_guest_update(
    IN in_pk_guest BIGINT,
    IN in_guestName VARCHAR(255),
    OUT out_response JSON
)
proc:
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while updating the guest.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    START TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM Guest WHERE pk_guest = in_pk_guest) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Guest not found.', 'code', 'GUEST_NOT_FOUND');
        LEAVE proc;
    END IF;

    UPDATE Guest
    SET guestName = COALESCE(in_guestName, guestName)
    WHERE pk_guest = in_pk_guest;

    IF ROW_COUNT() = 0 THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Guest not found or no changes made.', 'code', 'GUEST_NOT_FOUND');
        LEAVE proc;
    END IF;

    COMMIT;

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Guest updated successfully.', 'code', 'SUCCESS_UPDATED', 'data', JSON_OBJECT('pk_guest', in_pk_guest));
END $$

DROP PROCEDURE IF EXISTS sp_guests_get $$

CREATE PROCEDURE sp_guests_get(
    IN in_page INT,
    OUT out_response JSON
)
proc:
BEGIN
    DECLARE offset INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching guests.', 'code', 'INTERNAL_SERVER_ERROR');
        END;
    SET offset = (in_page - 1) * 10;

    SELECT JSON_OBJECT(
                   'success', TRUE,
                   'message', 'Guests fetched successfully.',
                   'code', 'SUCCESS_OK',
                   'data', IFNULL(JSON_ARRAYAGG(
                                          JSON_OBJECT(
                                                  'pk_guest', pk_guest,
                                                  'guestName', guestName,
                                                  'createdAt', createdAt
                                          )
                                  ), JSON_ARRAY())
           )
    FROM (SELECT *
          FROM Guest
          ORDER BY createdAt DESC
          LIMIT 10 OFFSET offset) AS Guest
    INTO out_response;
END $$

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
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while creating the invite code.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    IF in_code IS NULL OR in_code = '' THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Invite code cannot be empty.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF in_expiresAt IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Expiry date cannot be null.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF in_fk_match_connects IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Match ID cannot be null.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM `Match` WHERE pk_match = in_fk_match_connects) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Match not found.', 'code', 'MATCH_NOT_FOUND');
        LEAVE proc;
    END IF;

    INSERT INTO InviteCode (code, expiresAt, fk_match_connects)
    VALUES (in_code, in_expiresAt, in_fk_match_connects);

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Invite code created successfully.', 'code', 'SUCCESS_CREATED', 'data', JSON_OBJECT('pk_inviteCode', LAST_INSERT_ID()));
END $$

DROP PROCEDURE IF EXISTS sp_inviteCode_delete $$

CREATE PROCEDURE sp_inviteCode_delete(
    IN in_pk_inviteCode BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while deleting the invite code.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    START TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM InviteCode WHERE pk_inviteCode = in_pk_inviteCode) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Invite code not found.', 'code', 'INVITE_NOT_FOUND');
        LEAVE proc;
    END IF;

    DELETE FROM InviteCode WHERE pk_inviteCode = in_pk_inviteCode;

    COMMIT;
    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Invite code deleted successfully.', 'code', 'SUCCESS_DELETED', 'data', JSON_OBJECT('pk_inviteCode', in_pk_inviteCode));
END $$

DROP PROCEDURE IF EXISTS sp_inviteCode_get_by_id $$

CREATE PROCEDURE sp_inviteCode_get_by_id(
    IN in_pk_inviteCode BIGINT,
    OUT out_response JSON
)
proc:
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching the invite code.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    IF in_pk_inviteCode IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Invite code ID cannot be null.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM InviteCode WHERE pk_inviteCode = in_pk_inviteCode) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Invite code not found.', 'code', 'INVITE_NOT_FOUND');
        LEAVE proc;
    END IF;

    SELECT JSON_OBJECT(
                   'success', TRUE,
                   'message', 'Invite code fetched successfully.',
                   'code', 'SUCCESS_OK',
                   'data', JSON_OBJECT(
                       'pk_inviteCode', pk_inviteCode,
                       'code', code,
                       'status', status,
                       'createdAt', createdAt,
                       'expiresAt', expiresAt,
                       'fk_match_connects', fk_match_connects
                   )
           )
    INTO out_response
    FROM InviteCode
    WHERE pk_inviteCode = in_pk_inviteCode;
END $$

DROP PROCEDURE IF EXISTS sp_inviteCode_update $$

CREATE PROCEDURE sp_inviteCode_update(
    IN in_pk_inviteCode BIGINT,
    IN in_code VARCHAR(255),
    IN in_status ENUM('active', 'expired'),
    IN in_expiresAt DATETIME,
    OUT out_response JSON
)
proc:
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while updating the invite code.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    START TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM InviteCode WHERE pk_inviteCode = in_pk_inviteCode) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Invite code not found.', 'code', 'INVITE_NOT_FOUND');
        LEAVE proc;
    END IF;

    UPDATE InviteCode
    SET code      = COALESCE(in_code, code),
        status    = COALESCE(in_status, status),
        expiresAt = COALESCE(in_expiresAt, expiresAt)
    WHERE pk_inviteCode = in_pk_inviteCode;

    IF ROW_COUNT() = 0 THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Invite code not found or no changes made.', 'code', 'INVITE_NOT_FOUND');
        LEAVE proc;
    END IF;

    COMMIT;

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Invite code updated successfully.', 'code', 'SUCCESS_UPDATED', 'data', JSON_OBJECT('pk_inviteCode', in_pk_inviteCode));
END $$

DROP PROCEDURE IF EXISTS sp_inviteCodes_get $$

CREATE PROCEDURE sp_inviteCodes_get(
    IN in_page INT,
    OUT out_response JSON
)
proc:
BEGIN
    DECLARE offset INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching invite codes.', 'code', 'INTERNAL_SERVER_ERROR');
        END;
    SET offset = (in_page - 1) * 10;

    SELECT JSON_OBJECT(
                   'success', TRUE,
                   'message', 'Invite codes fetched successfully.',
                   'code', 'SUCCESS_OK',
                   'data', IFNULL(JSON_ARRAYAGG(
                                          JSON_OBJECT(
                                                  'pk_inviteCode', pk_inviteCode,
                                                  'code', code,
                                                  'status', status,
                                                  'createdAt', createdAt,
                                                  'expiresAt', expiresAt,
                                                  'fk_match_connects', fk_match_connects
                                          )
                                  ), JSON_ARRAY())
           )
    FROM (SELECT *
          FROM InviteCode
          ORDER BY createdAt DESC
          LIMIT 10 OFFSET offset) AS InviteCode
    INTO out_response;
END $$

DROP PROCEDURE IF EXISTS sp_match_create $$

CREATE PROCEDURE sp_match_create(
    IN in_name VARCHAR(255),
    IN in_description TEXT,
    IN in_format VARCHAR(255),
    IN in_startingLife INT,
    IN in_startTime TIME,
    IN in_isTeamMatch TINYINT,
    IN in_commanderThreshold INT,
    IN in_counterThreshold INT,
    IN in_fk_appUser_creates BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while creating the match.', 'code', 'INTERNAL_SERVER_ERROR');
        END;
    IF in_format IS NULL OR in_format = '' THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Match format cannot be empty.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF in_startingLife IS NULL OR in_startingLife <= 0 THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Starting life must be a positive integer.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF in_startTime IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Start time cannot be null.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF in_isTeamMatch IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'isTeamMatch cannot be null.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF in_fk_appUser_creates IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Creator user ID cannot be null.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM AppUser WHERE pk_appUser = in_fk_appUser_creates) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Creator user not found.', 'code', 'USER_NOT_FOUND');
        LEAVE proc;
    END IF;

    INSERT INTO `Match` (name, description, format, startingLife, startTime, isTeamMatch, commanderThreshold, counterThreshold, fk_appUser_creates)
    VALUES (in_name, in_description, in_format, in_startingLife, in_startTime,
            in_isTeamMatch, in_commanderThreshold, in_counterThreshold, in_fk_appUser_creates);

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Match created successfully.', 'code', 'SUCCESS_CREATED', 'data', JSON_OBJECT('pk_match', LAST_INSERT_ID()));
END $$

DROP PROCEDURE IF EXISTS sp_match_delete $$

CREATE PROCEDURE sp_match_delete(
    IN in_pk_match BIGINT,
    IN in_fk_appUser BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while deleting the match.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    START TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM `Match` WHERE pk_match = in_pk_match) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Match not found.', 'code', 'MATCH_NOT_FOUND');
        LEAVE proc;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM `Match` WHERE pk_match = in_pk_match AND fk_appUser_creates = in_fk_appUser) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'You are not the creator of this match.', 'code', 'FORBIDDEN');
        LEAVE proc;
    END IF;

    DELETE FROM `Match` WHERE pk_match = in_pk_match;

    COMMIT;
    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Match deleted successfully.', 'code', 'SUCCESS_DELETED', 'data', JSON_OBJECT('pk_match', in_pk_match));
END $$

DROP PROCEDURE IF EXISTS sp_match_get_by_id $$

CREATE PROCEDURE sp_match_get_by_id(
    IN in_pk_match BIGINT,
    OUT out_response JSON
)
proc:
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching the match.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    IF (in_pk_match IS NULL) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Match ID cannot be null.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM `Match` WHERE pk_match = in_pk_match) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Match not found.', 'code', 'MATCH_NOT_FOUND');
        LEAVE proc;
    END IF;

    SELECT JSON_OBJECT(
                   'success', TRUE,
                   'message', 'Match fetched successfully.',
                   'code', 'SUCCESS_OK',
                   'data', JSON_OBJECT(
                           'pk_match', `Match`.pk_match,
                           'name', name,
                           'description', description,
                           'format', format,
                           'startingLife', startingLife,
                           'startTime', startTime,
                           'endTime', endTime,
                           'isTeamMatch', isTeamMatch,
                           'commanderThreshold', commanderThreshold,
                           'counterThreshold', counterThreshold,
                           'fk_appUser_creates', fk_appUser_creates
                           )
           )
    INTO out_response
    FROM `Match`
    WHERE pk_match = in_pk_match;
END $$

DROP PROCEDURE IF EXISTS sp_match_update $$

CREATE PROCEDURE sp_match_update(
    IN in_pk_match BIGINT,
    IN in_name VARCHAR(255),
    IN in_description TEXT,
    IN in_format VARCHAR(255),
    IN in_startingLife INT,
    IN in_startTime TIME,
    IN in_endTime TIME,
    IN in_isTeamMatch TINYINT,
    IN in_commanderThreshold INT,
    IN in_counterThreshold INT,
    OUT out_response JSON
)
proc:
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            -- Rollback transaction on error
            ROLLBACK;
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while updating the user.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    -- Start transaction
    START TRANSACTION;

    UPDATE `Match`
    SET name = COALESCE(in_name, name),
        description = COALESCE(in_description, description),
        format = COALESCE(in_format, format),
        startingLife = COALESCE(in_startingLife, startingLife),
        startTime = COALESCE(in_startTime, startTime),
        endTime = COALESCE(in_endTime, endTime),
        isTeamMatch = COALESCE(in_isTeamMatch, isTeamMatch),
        commanderThreshold = COALESCE(in_commanderThreshold, commanderThreshold),
        counterThreshold = COALESCE(in_counterThreshold, counterThreshold)
    WHERE pk_match = in_pk_match;

    -- Check if any row was updated
    IF ROW_COUNT() = 0 THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Match not found or no changes made.', 'code', 'MATCH_NOT_FOUND');
        LEAVE proc;
    END IF;

    -- Commit transaction
    COMMIT;

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Match updated successfully.', 'code', 'SUCCESS_UPDATED', 'data', JSON_OBJECT('pk_match', in_pk_match));

END $$

DROP PROCEDURE IF EXISTS sp_matchs_get $$

CREATE PROCEDURE sp_matchs_get(
    IN in_page INT,
    OUT out_response JSON
)
proc:
BEGIN
    DECLARE offset INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching matches.', 'code', 'INTERNAL_SERVER_ERROR');
        END;
    SET offset = (in_page - 1) * 10;


    SELECT JSON_OBJECT(
                   'success', TRUE,
                   'message', 'Matches fetched successfully.',
                   'code', 'SUCCESS_OK',
                   'data', IFNULL(JSON_ARRAYAGG(
                                          JSON_OBJECT(
                                                  'pk_match', `Match`.pk_match,
                                                  'name', name,
                                                  'description', description,
                                                  'format', format,
                                                  'startingLife', startingLife,
                                                  'startTime', startTime,
                                                  'endTime', endTime,
                                                  'isTeamMatch', isTeamMatch,
                                                  'commanderThreshold', commanderThreshold,
                                                  'counterThreshold', counterThreshold,
                                                  'fk_appUser_creates', fk_appUser_creates
                                          )
                                  ), JSON_ARRAY())
           )
    FROM (SELECT *
          FROM `Match`
          ORDER BY startTime DESC
          LIMIT 10 OFFSET offset) AS `Match`
    INTO out_response;

END $$

DROP PROCEDURE IF EXISTS sp_player_create $$

CREATE PROCEDURE sp_player_create(
    IN in_startingLife INT,
    IN in_isWinner BOOLEAN,
    IN in_tax INT,
    IN in_placement INT,
    IN in_killCounter INT,
    IN in_poisonCounter INT,
    IN in_minPlayers INT,
    IN in_maxPlayers INT,
    IN in_fk_guest_enters BIGINT,
    IN in_fk_appUser_participates BIGINT,
    IN in_fk_team_isIncluded INT,
    IN in_fk_match_isPlayedIn BIGINT,
    OUT out_response JSON
)
proc:
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while creating the player.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    IF in_startingLife IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Starting life cannot be null.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF in_placement IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Placement cannot be null.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF in_minPlayers IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Minimum players cannot be null.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF in_maxPlayers IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Maximum players cannot be null.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF in_fk_match_isPlayedIn IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Match ID cannot be null.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM `Match` WHERE pk_match = in_fk_match_isPlayedIn) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Match not found.', 'code', 'MATCH_NOT_FOUND');
        LEAVE proc;
    END IF;

    IF in_fk_appUser_participates IS NOT NULL AND
       NOT EXISTS (SELECT 1 FROM AppUser WHERE pk_appUser = in_fk_appUser_participates) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Participating user not found.', 'code', 'USER_NOT_FOUND');
        LEAVE proc;
    END IF;

    IF in_fk_team_isIncluded IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Team WHERE pk_team = in_fk_team_isIncluded) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Team not found.', 'code', 'TEAM_NOT_FOUND');
        LEAVE proc;
    END IF;

    IF in_fk_guest_enters IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Guest WHERE pk_guest = in_fk_guest_enters) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Guest not found.', 'code', 'GUEST_NOT_FOUND');
        LEAVE proc;
    END IF;

    INSERT INTO Player (startingLife, isWinner, tax, placement, killCounter, poisonCounter, minPlayers,
                        maxPlayers, fk_guest_enters, fk_appUser_participates, fk_team_isIncluded, fk_match_isPlayedIn)
    VALUES (in_startingLife, in_isWinner, in_tax, in_placement,
            in_killCounter, in_poisonCounter, in_minPlayers, in_maxPlayers,
            in_fk_guest_enters, in_fk_appUser_participates, in_fk_team_isIncluded,
            in_fk_match_isPlayedIn);

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Player created successfully.', 'code', 'SUCCESS_CREATED', 'data', JSON_OBJECT('pk_player', LAST_INSERT_ID()));

END $$

DROP PROCEDURE IF EXISTS sp_player_delete $$

CREATE PROCEDURE sp_player_delete(
    IN in_pk_player BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            -- Rollback transaction on error
            ROLLBACK;
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while deleting the player.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    -- Start transaction
    START TRANSACTION;

    -- Check if player exists
    IF NOT EXISTS (SELECT 1 FROM Player WHERE pk_player = in_pk_player) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Player not found.', 'code', 'PLAYER_NOT_FOUND');
        LEAVE proc;
    END IF;

    -- Delete player
    DELETE FROM Player WHERE pk_player = in_pk_player;

    -- Commit transaction
    COMMIT;

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Player deleted successfully.', 'code', 'SUCCESS_DELETED', 'data', JSON_OBJECT('pk_player', in_pk_player));
END $$

DROP PROCEDURE IF EXISTS sp_player_get_by_id $$

CREATE PROCEDURE sp_player_get_by_id(
    IN in_pk_player BIGINT,
    OUT out_response JSON
)
proc:
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching the player.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    IF (in_pk_player IS NULL) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Player ID cannot be null.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Player WHERE pk_player = in_pk_player) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Player not found.', 'code', 'PLAYER_NOT_FOUND');
        LEAVE proc;
    END IF;

    SELECT JSON_OBJECT(
                   'success', TRUE,
                   'message', 'Player fetched successfully.',
                   'code', 'SUCCESS_OK',
                   'data', JSON_OBJECT(
                           'pk_player', pk_player,
                           'startingLife', startingLife,
                           'finalLife', finalLife,
                           'isWinner', isWinner,
                           'tax', tax,
                           'placement', placement,
                           'killCounter', killCounter,
                           'poisonCounter', poisonCounter,
                           'minPlayers', minPlayers,
                           'maxPlayers', maxPlayers,
                           'fk_guest_enters', fk_guest_enters,
                           'fk_appUser_participates', fk_appUser_participates,
                           'fk_team_isIncluded', fk_team_isIncluded,
                           'fk_match_isPlayedIn', fk_match_isPlayedIn
                           )
           )
    INTO out_response
    FROM Player
    WHERE pk_player = in_pk_player;
END $$

DROP PROCEDURE IF EXISTS sp_player_update $$

CREATE PROCEDURE sp_player_update(
    IN in_pk_player BIGINT,
    IN in_startingLife INT,
    IN in_finalLife INT,
    IN in_isWinner BOOLEAN,
    IN in_tax INT,
    IN in_placement INT,
    IN in_killCounter INT,
    IN in_poisonCounter INT,
    IN in_minPlayers INT,
    IN in_maxPlayers INT,
    IN in_fk_team_isIncluded INT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            -- Rollback transaction on error
            ROLLBACK;
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while updating the player.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    -- Start transaction
    START TRANSACTION;
    -- Check if player exists
    IF NOT EXISTS (SELECT 1 FROM Player WHERE pk_player = in_pk_player) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Player not found.', 'code', 'PLAYER_NOT_FOUND');
        LEAVE proc;
    END IF;

    IF in_fk_team_isIncluded IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Team WHERE pk_team = in_fk_team_isIncluded) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Team not found for the provided fk_team_isIncluded.', 'code', 'TEAM_NOT_FOUND');
        LEAVE proc;
    END IF;

    -- Update player information
    UPDATE Player
    SET startingLife = COALESCE(in_startingLife, startingLife),
        finalLife = COALESCE(in_finalLife, finalLife),
        isWinner = COALESCE(in_isWinner, isWinner),
        tax = COALESCE(in_tax, tax),
        placement = COALESCE(in_placement, placement),
        killCounter = COALESCE(in_killCounter, killCounter),
        poisonCounter = COALESCE(in_poisonCounter, poisonCounter),
        minPlayers = COALESCE(in_minPlayers, minPlayers),
        maxPlayers = COALESCE(in_maxPlayers, maxPlayers),
        fk_team_isIncluded = COALESCE(in_fk_team_isIncluded, fk_team_isIncluded)
    WHERE pk_player = in_pk_player;

    -- Commit transaction
    COMMIT;

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Player updated successfully.', 'code', 'SUCCESS_UPDATED', 'data', JSON_OBJECT('pk_player', in_pk_player));
END $$

DROP PROCEDURE IF EXISTS sp_players_get $$

CREATE PROCEDURE sp_players_get(
    IN in_page INT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE offset INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching players.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    SET offset = (in_page - 1) * 10;

    SELECT JSON_OBJECT(
        'success', TRUE,
        'message', 'Players fetched successfully.',
        'code', 'SUCCESS_OK',
        'data', IFNULL(JSON_ARRAYAGG(
            JSON_OBJECT(
                'pk_player', pk_player,
                'startingLife', startingLife,
                'finalLife', finalLife,
                'isWinner', isWinner,
                'tax', tax,
                'placement', placement,
                'killCounter', killCounter,
                'poisonCounter', poisonCounter,
                'minPlayers', minPlayers,
                'maxPlayers', maxPlayers,
                'fk_guest_enters', fk_guest_enters,
                'fk_appUser_participates', fk_appUser_participates,
                'fk_team_isIncluded', fk_team_isIncluded,
                'fk_match_isPlayedIn', fk_match_isPlayedIn
            )
        ), JSON_ARRAY())
    )
    INTO out_response
    FROM (
        SELECT pk_player, startingLife, finalLife, isWinner, tax, placement, killCounter, poisonCounter, minPlayers, maxPlayers, fk_guest_enters, fk_appUser_participates, fk_team_isIncluded, fk_match_isPlayedIn
        FROM Player
        ORDER BY pk_player
        LIMIT 10 OFFSET offset
    ) AS players;

END $$

DROP PROCEDURE IF EXISTS sp_refreshToken_create $$

CREATE PROCEDURE sp_refreshToken_create(
    IN  in_fk_appUser           BIGINT,
    IN  in_tokenHash            VARCHAR(255),
    IN  in_ipLastUsed           VARCHAR(255),
    IN  in_ipCreated            VARCHAR(255),
    IN  in_deviceName           VARCHAR(255),
    IN  in_expiresAt            DATETIME,
    IN  in_fk_rotatedFrom       BIGINT,        -- NULL for a brand-new token
    OUT out_response            JSON
)
proc:
BEGIN
    DECLARE v_errno INT DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            GET DIAGNOSTICS CONDITION 1 v_errno = MYSQL_ERRNO;
            ROLLBACK;
            -- errno 1062 = duplicate key: the UNIQUE constraint on fk_refreshToken_rotatedFrom
            -- was violated by a concurrent rotation of the same token
            IF v_errno = 1062 THEN
                SET out_response = JSON_OBJECT(
                    'success', FALSE,
                    'message', 'This token has already been rotated by a concurrent request.',
                    'code',    'TOKEN_ALREADY_ROTATED'
                );
            ELSE
                SET out_response = JSON_OBJECT(
                    'success', FALSE,
                    'message', 'An error occurred while creating the refresh token.',
                    'code',    'INTERNAL_SERVER_ERROR'
                );
            END IF;
        END;

    START TRANSACTION;

    -- Verify the user exists
    IF NOT EXISTS (SELECT 1 FROM AppUser WHERE pk_appUser = in_fk_appUser) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT(
            'success', FALSE,
            'message', 'User not found.',
            'code',    'VALIDATION_USER_NOT_FOUND'
        );
        LEAVE proc;
    END IF;

    -- If this is a rotated token, verify the predecessor exists and belongs to the same user
    IF in_fk_rotatedFrom IS NOT NULL THEN
        IF NOT EXISTS (
            SELECT 1 FROM RefreshToken
            WHERE pk_refreshToken    = in_fk_rotatedFrom
              AND fk_appUser_refreshes = in_fk_appUser
        ) THEN
            ROLLBACK;
            SET out_response = JSON_OBJECT(
                'success', FALSE,
                'message', 'The token being rotated does not exist or does not belong to this user.',
                'code',    'VALIDATION_INVALID_ROTATED_FROM'
            );
            LEAVE proc;
        END IF;

        -- Revoke the old token now that it is being rotated
        UPDATE RefreshToken
        SET revokedAt = NOW()
        WHERE pk_refreshToken = in_fk_rotatedFrom
          AND revokedAt IS NULL;
    END IF;

    -- Guard against concurrent rotation: if this source token was already used, return a clean error
    IF in_fk_rotatedFrom IS NOT NULL THEN
        IF EXISTS (
            SELECT 1 FROM RefreshToken WHERE fk_refreshToken_rotatedFrom = in_fk_rotatedFrom
        ) THEN
            ROLLBACK;
            SET out_response = JSON_OBJECT(
                'success', FALSE,
                'message', 'This token has already been rotated by a concurrent request.',
                'code',    'TOKEN_ALREADY_ROTATED'
            );
            LEAVE proc;
        END IF;
    END IF;

    -- Insert the new token
    INSERT INTO RefreshToken (
        tokenHash,
        ipLastUsed,
        ipCreated,
        deviceName,
        expiresAt,
        createdAt,
        revokedAt,
        fk_refreshToken_rotatedFrom,
        fk_appUser_refreshes
    )
    VALUES (
        in_tokenHash,
        in_ipLastUsed,
        in_ipCreated,
        in_deviceName,
        in_expiresAt,
        NOW(),
        NULL,               -- not revoked yet
        in_fk_rotatedFrom,  -- NULL for first-time tokens
        in_fk_appUser
    );

    COMMIT;

    SET out_response = JSON_OBJECT(
        'success', TRUE,
        'message', 'Refresh token created successfully.',
        'code',    'SUCCESS_CREATED',
        'data',    JSON_OBJECT('pk_refreshToken', LAST_INSERT_ID())
    );
END $$

DROP PROCEDURE IF EXISTS sp_refreshToken_delete $$

CREATE PROCEDURE sp_refreshToken_delete(
    IN in_pk_refreshToken BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            -- Rollback transaction on error
            ROLLBACK;
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while deleting the refresh token.',
            'code', 'INTERNAL_SERVER_ERROR');
        END;

    -- Start transaction
    START TRANSACTION;

    -- Check if refresh token exists
    IF NOT EXISTS (SELECT 1 FROM RefreshToken WHERE pk_refreshToken = in_pk_refreshToken) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Refresh token not found.',
                           'code', 'VALIDATION_REFRESHTOKEN_NOT_FOUND');
        LEAVE proc;
    END IF;

    -- Delete refresh token
    DELETE FROM RefreshToken WHERE pk_refreshToken = in_pk_refreshToken;

    -- Commit transaction
    COMMIT;

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Refresh token deleted successfully.',
    'code', 'REFRESHTOKEN_DELETED');
END $$

DROP PROCEDURE IF EXISTS sp_refreshToken_get_by_id $$

CREATE PROCEDURE sp_refreshToken_get_by_id(
    IN in_pk_refreshToken BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching the refresh token.',
            'code', 'INTERNAL_SERVER_ERROR');
        END;

    SELECT JSON_OBJECT(
        'success', TRUE,
        'message', 'Refresh token fetched successfully.',
        'code', 'SUCCESS_OK',
        'data', JSON_OBJECT(
            'pk_refreshToken', pk_refreshToken,
            'tokenHash', tokenHash,
            'expiresAt', expiresAt,
            'createdAt', createdAt,
            'revokedAt', revokedAt,
            'fk_appUser_refreshes', fk_appUser_refreshes
        )
    )
    INTO out_response
    FROM RefreshToken
    WHERE pk_refreshToken = in_pk_refreshToken;

END $$

DROP PROCEDURE IF EXISTS sp_refreshToken_revoke $$

CREATE PROCEDURE sp_refreshToken_revoke(
    IN  in_tokenHash            VARCHAR(255),
    IN  in_fk_appUser           BIGINT,
    OUT out_response            JSON
)
proc:
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            ROLLBACK;
            SET out_response = JSON_OBJECT(
                'success', FALSE,
                'message', 'An error occurred while revoking the refresh token.',
                'code',    'INTERNAL_SERVER_ERROR'
            );
        END;

    START TRANSACTION;

    -- Verify the token exists, belongs to the user, and is not already revoked
    IF NOT EXISTS (
        SELECT 1 FROM RefreshToken
        WHERE tokenHash = in_tokenHash
          AND fk_appUser_refreshes = in_fk_appUser
    ) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT(
            'success', FALSE,
            'message', 'Refresh token not found or does not belong to the user.',
            'code',    'VALIDATION_TOKEN_NOT_FOUND'
        );
        LEAVE proc;
    END IF;

    IF EXISTS (
        SELECT 1 FROM RefreshToken
        WHERE tokenHash = in_tokenHash
          AND revokedAt IS NOT NULL
    ) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT(
            'success', FALSE,
            'message', 'Refresh token is already revoked.',
            'code',    'VALIDATION_TOKEN_ALREADY_REVOKED'
        );
        LEAVE proc;
    END IF;

    -- Revoke the token
    UPDATE RefreshToken
    SET revokedAt = NOW()
    WHERE tokenHash = in_tokenHash;

    COMMIT;

    SET out_response = JSON_OBJECT(
        'success', TRUE,
        'message', 'Refresh token revoked successfully.',
        'code',    'SUCCESS_OK'
    );
END $$

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
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while creating the team.', 'code', 'INTERNAL_SERVER_ERROR');
        END;
    IF in_teamName IS NULL OR in_teamName = '' THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Team name cannot be empty.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    INSERT INTO Team (name, startingLife, finalLife)
    VALUES (in_teamName, startingLife, finalLife);

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Team created successfully.', 'code', 'SUCCESS_CREATED', 'data', JSON_OBJECT('pk_team', LAST_INSERT_ID()));
END $$

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

DROP PROCEDURE IF EXISTS sp_team_get_by_id $$

CREATE PROCEDURE sp_team_get_by_id(
    IN in_pk_team BIGINT,
    OUT out_response JSON
)
proc:
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching the team.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    IF (in_pk_team IS NULL) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Team ID cannot be null.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM Team WHERE pk_team = in_pk_team) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Team not found.', 'code', 'TEAM_NOT_FOUND');
        LEAVE proc;
    END IF;

    SELECT JSON_OBJECT(
                   'success', TRUE,
                   'message', 'Team fetched successfully.',
                   'code', 'SUCCESS_OK',
                   'data', JSON_OBJECT(
                           'pk_team', pk_team,
                           'name', name,
                           'startingLife', startingLife,
                           'finalLife', finalLife
                           )
           )
    INTO out_response
    FROM Team
    WHERE pk_team = in_pk_team;
END $$

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

DROP PROCEDURE IF EXISTS sp_teams_get $$

CREATE PROCEDURE sp_teams_get(
    IN in_page INT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE offset INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching teams.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    SET offset = (in_page - 1) * 10;

    SELECT JSON_OBJECT(
        'success', TRUE,
        'message', 'Teams fetched successfully.',
        'code', 'SUCCESS_OK',
        'data', IFNULL(JSON_ARRAYAGG(
            JSON_OBJECT(
                'pk_team', pk_team,
                'name', name,
                'startingLife', startingLife,
                'finalLife', finalLife
            )
        ), JSON_ARRAY())
    )
    INTO out_response
    FROM (
        SELECT pk_team, name, startingLife, finalLife
        FROM Team
        ORDER BY name
        LIMIT 10 OFFSET offset
    ) AS teams;


END $$

DROP PROCEDURE IF EXISTS sp_user_activate $$

CREATE PROCEDURE sp_user_activate(
    IN in_verificationToken VARCHAR(255),
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while activating the user.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    UPDATE AppUser
    SET emailVerified = TRUE, verificationToken = NULL
    WHERE verificationToken = in_verificationToken;

    IF ROW_COUNT() = 0 THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Invalid verification token.', 'code', 'INVALID_TOKEN');
        LEAVE proc;
    END IF;

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'User activated successfully.', 'code', 'SUCCESS_OK');
END $$

DROP PROCEDURE IF EXISTS sp_user_change_password$$

CREATE PROCEDURE sp_user_change_password(
    IN in_resetToken VARCHAR(255),
    IN in_newPassword VARCHAR(255),
    OUT out_response JSON
)
proc: BEGIN
    DECLARE currentPasswordHash VARCHAR(255);
    DECLARE storedResetToken VARCHAR(255);
    DECLARE tokenExpiry DATETIME;
    DECLARE userId BIGINT;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET out_response = JSON_OBJECT(
            'success', FALSE,
            'message', 'An error occurred.',
            'code', 'INTERNAL_SERVER_ERROR'
        );
    END;

    -- Fetch user details
    SELECT passwordHash, resetToken, tokenExpiresAt, pk_appUser
    INTO currentPasswordHash, storedResetToken, tokenExpiry, userId
    FROM AppUser;

    IF currentPasswordHash IS NULL THEN
        SET out_response = JSON_OBJECT(
            'success', FALSE,
            'message', 'User not found.',
            'code', 'USER_NOT_FOUND'
        );
        LEAVE proc;
    END IF;

    -- Password change with reset token
    IF in_resetToken IS NOT NULL THEN
        IF storedResetToken IS NULL OR storedResetToken != in_resetToken OR tokenExpiry < NOW() THEN
            SET out_response = JSON_OBJECT(
                'success', FALSE,
                'message', 'Invalid or expired reset token.',
                'code', 'INVALID_RESET_TOKEN'
            );
            LEAVE proc;
        END IF;
    ELSE
        SET out_response = JSON_OBJECT(
            'success', FALSE,
            'message', 'Either a reset token or the old password must be provided.',
            'code', 'MISSING_CREDENTIALS'
        );
        LEAVE proc;
    END IF;

    START TRANSACTION;

    -- Update the password and clear the reset token
    UPDATE AppUser
    SET
        passwordHash = in_newPassword,
        resetToken = NULL,
        tokenExpiresAt = NULL
    WHERE pk_appUser = userId;

    COMMIT;

    SET out_response = JSON_OBJECT(
        'success', TRUE,
        'message', 'Password changed successfully.',
        'code', 'PASSWORD_CHANGED'
    );

END$$

DROP PROCEDURE IF EXISTS sp_user_create $$

CREATE PROCEDURE sp_user_create(
    IN in_username VARCHAR(255),
    IN in_email VARCHAR(255),
    IN in_passwordHash VARCHAR(255),
    IN in_verificationToken VARCHAR(255),
    OUT out_response JSON
)
proc:
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            -- Rollback transaction on error
            ROLLBACK;
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while creating the user.',
                                           'code', 'INTERNAL_SERVER_ERROR');
        END;

    -- Start transaction
    START TRANSACTION;

    -- Check if username already exists
    IF EXISTS (SELECT 1 FROM AppUser WHERE username = in_username) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Username already exists.',
                                       'code', 'VALIDATION_USERNAME_EXISTS');
        LEAVE proc;
    END IF;

    -- Check if email already exists
    IF EXISTS (SELECT 1 FROM AppUser WHERE email = in_email) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Email already exists.',
                                       'code', 'VALIDATION_EMAIL_EXISTS');
        LEAVE proc;
    END IF;

    -- Insert new user
    INSERT INTO AppUser (username, email, passwordHash, verificationToken)
    VALUES (in_username, in_email, in_passwordHash, in_verificationToken);

    -- Commit transaction
    COMMIT;

    SET out_response = JSON_OBJECT('success', TRUE,
                                   'code', '',
                                   'message',
                                   'User created successfully. Please check your email for verification instructions.',
                                   'code', 'SUCCESS_CREATED',
                                   'data', JSON_OBJECT('pk_appUser', LAST_INSERT_ID()));
END $$

DROP PROCEDURE IF EXISTS sp_user_delete $$

CREATE PROCEDURE sp_user_delete(
    IN in_pk_appUser BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            -- Rollback transaction on error
            ROLLBACK;
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while deleting the user.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    -- Start transaction
    START TRANSACTION;

    -- Check if user exists
    IF NOT EXISTS (SELECT 1 FROM AppUser WHERE pk_appUser = in_pk_appUser) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'User not found.', 'code', 'USER_NOT_FOUND');
        LEAVE proc;
    END IF;

    -- Delete user
    DELETE FROM AppUser WHERE pk_appUser = in_pk_appUser;

    -- Commit transaction
    COMMIT;

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'User deleted successfully.', 'code', 'SUCCESS_DELETED', 'data', JSON_OBJECT('pk_appUser', in_pk_appUser));
END $$

DROP PROCEDURE IF EXISTS sp_user_get_by_email $$

CREATE PROCEDURE sp_user_get_by_email(
    IN in_email BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching the user.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    IF(in_email IS NULL OR in_email = "") THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'User ID cannot be null.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM AppUser WHERE email = in_email) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'User not found.', 'code', 'USER_NOT_FOUND');
        LEAVE proc;
    END IF;

    SELECT JSON_OBJECT(
        'success', TRUE,
        'message', 'User fetched successfully.',
        'code', 'SUCCESS_OK',
        'data', JSON_OBJECT(
            'pk_appUser', pk_appUser,
            'username', username,
            'email', email,
            'createdAt', createdAt,
            'lastLogin', lastLogin,
            'isActive', isActive,
            'emailVerified', emailVerified
        )
    )
    INTO out_response
    FROM AppUser
    WHERE pk_appUser = in_pk_appUser;
END $$

DROP PROCEDURE IF EXISTS sp_user_get_by_id $$

CREATE PROCEDURE sp_user_get_by_id(
    IN in_pk_appUser BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching the user.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    IF(in_pk_appUser IS NULL) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'User ID cannot be null.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM AppUser WHERE pk_appUser = in_pk_appUser) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'User not found.', 'code', 'USER_NOT_FOUND');
        LEAVE proc;
    END IF;

    SELECT JSON_OBJECT(
        'success', TRUE,
        'message', 'User fetched successfully.',
        'code', 'SUCCESS_OK',
        'data', JSON_OBJECT(
            'pk_appUser', pk_appUser,
            'username', username,
            'email', email,
            'createdAt', createdAt,
            'lastLogin', lastLogin,
            'isActive', isActive,
            'emailVerified', emailVerified
        )
    )
    INTO out_response
    FROM AppUser
    WHERE pk_appUser = in_pk_appUser;
END $$

DROP PROCEDURE IF EXISTS sp_user_get_by_username $$

CREATE PROCEDURE sp_user_get_by_username(
    IN in_username VARCHAR(255),
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while searching for the user.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    IF (in_username IS NULL OR in_username = '') THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Username cannot be empty.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM AppUser WHERE username = in_username) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'User not found.', 'code', 'USER_NOT_FOUND');
        LEAVE proc;
    END IF;

    SELECT JSON_OBJECT(
        'success', TRUE,
        'message', 'User found.',
        'code', 'SUCCESS_OK',
        'data', JSON_OBJECT(
            'userId', pk_appUser,
            'username', username
        )
    )
    INTO out_response
    FROM AppUser
    WHERE username = in_username;
END $$

DROP PROCEDURE IF EXISTS sp_user_get_password $$

CREATE PROCEDURE sp_user_get_password(
    IN in_email VARCHAR(255),
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching the password.',
            'code', 'INTERNAL_SERVER_ERROR');
        END;

    IF(in_email IS NULL OR in_email = '') THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Email cannot be null or empty.',
                           'code', 'INVALID_EMAIL');
        LEAVE proc;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM AppUser WHERE email = in_email) THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Invalid email or password.',
                           'code', 'INVALID_CREDENTIALS');
        LEAVE proc;
    END IF;

    SELECT JSON_OBJECT(
        'success', TRUE,
        'message', 'Password fetched successfully.',
        'code', 'SUCCESS_OK',
        'data', JSON_OBJECT(
            'passwordHash', passwordHash
        )
    )
    INTO out_response
    FROM AppUser
    WHERE email = in_email;
END $$

DROP PROCEDURE IF EXISTS sp_user_stats_get $$

CREATE PROCEDURE sp_user_stats_get(
    IN in_fk_appUser BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE v_totalGames      INT DEFAULT 0;
    DECLARE v_finishedGames   INT DEFAULT 0;
    DECLARE v_wins            INT DEFAULT 0;
    DECLARE v_losses          INT DEFAULT 0;
    DECLARE v_winRate         DECIMAL(5,2) DEFAULT 0;
    DECLARE v_avgPlacement    DECIMAL(5,2) DEFAULT 0;
    DECLARE v_avgFinalLife    DECIMAL(5,2) DEFAULT 0;
    DECLARE v_avgStartLife    DECIMAL(5,2) DEFAULT 0;

    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching stats.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    IF in_fk_appUser IS NULL THEN
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'User ID is required.', 'code', 'VALIDATION_ERROR');
        LEAVE proc;
    END IF;

    SELECT
        COUNT(*),
        SUM(finalLife IS NOT NULL)
    INTO v_totalGames, v_finishedGames
    FROM Player
    WHERE fk_appUser_participates = in_fk_appUser;

    SELECT
        SUM(isWinner = 1 AND finalLife IS NOT NULL),
        SUM(isWinner = 0 AND finalLife IS NOT NULL),
        ROUND(AVG(placement), 2),
        ROUND(AVG(finalLife), 2),
        ROUND(AVG(startingLife), 2)
    INTO
        v_wins, v_losses, v_avgPlacement, v_avgFinalLife, v_avgStartLife
    FROM Player
    WHERE fk_appUser_participates = in_fk_appUser;

    IF v_finishedGames > 0 THEN
        SET v_winRate = ROUND((v_wins / v_finishedGames) * 100, 2);
    END IF;

    SET out_response = JSON_OBJECT(
        'success', TRUE,
        'message', 'Stats fetched successfully.',
        'code', 'SUCCESS_OK',
        'data', JSON_OBJECT(
            'totalGames',   v_totalGames,
            'wins',         COALESCE(v_wins, 0),
            'losses',       COALESCE(v_losses, 0),
            'winRate',      v_winRate,
            'avgPlacement', COALESCE(v_avgPlacement, 0),
            'avgFinalLife', v_avgFinalLife,
            'avgStartLife', v_avgStartLife,
            'recentMatches', (
                SELECT COALESCE(JSON_ARRAYAGG(
                    JSON_OBJECT(
                        'matchId',      m.pk_match,
                        'matchName',    COALESCE(m.name, CONCAT('Match #', m.pk_match)),
                        'format',       m.format,
                        'startTime',    m.startTime,
                        'endTime',      m.endTime,
                        'placement',    p.placement,
                        'isWinner',     p.isWinner,
                        'finalLife',    p.finalLife,
                        'startingLife', p.startingLife
                    )
                ), JSON_ARRAY())
                FROM Player p
                JOIN `Match` m ON m.pk_match = p.fk_match_isPlayedIn
                WHERE p.fk_appUser_participates = in_fk_appUser
                ORDER BY m.startTime DESC
                LIMIT 10
            )
        )
    );
END $$

DROP PROCEDURE IF EXISTS sp_user_update $$

CREATE PROCEDURE sp_user_update(
    IN in_pk_appUser BIGINT,
    IN in_username VARCHAR(255),
    IN in_email VARCHAR(255),
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            -- Rollback transaction on error
            ROLLBACK;
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while updating the user.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    -- Start transaction
    START TRANSACTION;

    -- Check if user exists
    IF NOT EXISTS (SELECT 1 FROM AppUser WHERE pk_appUser = in_pk_appUser) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'User not found.', 'code', 'USER_NOT_FOUND');
        LEAVE proc;
    END IF;

    -- Update user information
    UPDATE AppUser
    SET username = COALESCE(in_username, username),
        email = COALESCE(in_email, email)
    WHERE pk_appUser = in_pk_appUser;

    -- Commit transaction
    COMMIT;

    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'User updated successfully.', 'code', 'SUCCESS_UPDATED', 'data', JSON_OBJECT('pk_appUser', in_pk_appUser));
END $$

DROP PROCEDURE IF EXISTS sp_users_get $$

CREATE PROCEDURE sp_users_get(
    IN in_page INT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE offset INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching users.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    SET offset = (in_page - 1) * 10;

    SELECT JSON_OBJECT(
        'success', TRUE,
        'message', 'Users fetched successfully.',
        'code', 'SUCCESS_OK',
        'data', IFNULL(JSON_ARRAYAGG(
            JSON_OBJECT(
                'pk_appUser', pk_appUser,
                'username', username,
                'email', email,
                'createdAt', createdAt,
                'lastLogin', lastLogin,
                'isActive', isActive,
                'emailVerified', emailVerified
            )
        ), JSON_ARRAY())
    )
    INTO out_response
    FROM (
        SELECT pk_appUser, username, email, createdAt, lastLogin, isActive, emailVerified
        FROM AppUser
        ORDER BY createdAt DESC
        LIMIT 10 OFFSET offset
    ) AS users;
END $$

DELIMITER ;
