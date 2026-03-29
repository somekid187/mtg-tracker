USE `mtg-tracker`;

DELIMITER $$

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

DELIMITER ;

