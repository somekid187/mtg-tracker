USE `mtg-tracker`;

DELIMITER $$

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