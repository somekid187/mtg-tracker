USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_match_delete $$

CREATE PROCEDURE sp_match_delete(
    IN in_pk_match BIGINT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            -- Rollback transaction on error
            ROLLBACK;
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while deleting the match.', 'code', 'INTERNAL_SERVER_ERROR');
        END;

    -- Start transaction
    START TRANSACTION;
    -- Check if match exists
    IF NOT EXISTS (SELECT 1 FROM `Match` WHERE pk_match = in_pk_match) THEN
        ROLLBACK;
        SET out_response = JSON_OBJECT('success', FALSE, 'message', 'Match not found.', 'code', 'MATCH_NOT_FOUND');
        LEAVE proc;
    END IF;

    -- Delete match
    DELETE FROM `Match` WHERE pk_match = in_pk_match;

    -- Commit transaction
    COMMIT;
    SET out_response = JSON_OBJECT('success', TRUE, 'message', 'Match deleted successfully.', 'code', 'SUCCESS_DELETED', 'data', JSON_OBJECT('pk_match', in_pk_match));
END $$

DELIMITER ;