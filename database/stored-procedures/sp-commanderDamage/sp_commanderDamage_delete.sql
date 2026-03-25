USE `mtg-tracker`;

DELIMITER $$

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

DELIMITER ;

