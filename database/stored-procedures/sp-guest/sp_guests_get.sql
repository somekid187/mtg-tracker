USE `mtg-tracker`;

DELIMITER $$

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
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching guests.');
        END;
    SET offset = (in_page - 1) * 10;

    SELECT JSON_OBJECT(
                   'success', TRUE,
                   'message', 'Guests fetched successfully.',
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

DELIMITER ;

