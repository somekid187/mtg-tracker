USE `mtg-tracker`;

DELIMITER $$

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

DELIMITER ;
