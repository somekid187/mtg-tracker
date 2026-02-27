USE `mtg-tracker`;

DELIMITER $$

DROP PROCEDURE IF EXISTS sp_users_get $$

CREATE PROCEDURE sp_users_get(
    IN in_page INT,
    OUT out_response JSON
)
proc:BEGIN
    DECLARE offset INT;
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
        BEGIN
            SET out_response = JSON_OBJECT('success', FALSE, 'message', 'An error occurred while fetching users.');
        END;

    SET offset = (in_page - 1) * 10;

    SELECT JSON_OBJECT(
        'success', TRUE,
        'message', 'Users fetched successfully.',
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