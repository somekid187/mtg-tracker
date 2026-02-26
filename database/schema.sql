DROP DATABASE IF EXISTS `mtg-tracker`;
CREATE DATABASE `mtg-tracker`;

USE `mtg-tracker`;

CREATE TABLE AppUser
(
    pk_appUser        BIGINT AUTO_INCREMENT PRIMARY KEY,
    username          VARCHAR(255) UNIQUE                  NOT NULL,
    email             VARCHAR(255) UNIQUE                  NOT NULL,
    passwordHash      VARCHAR(255)                         NOT NULL,
    createdAt         DATETIME DEFAULT CURRENT_TIMESTAMP() NOT NULL,
    lastLogin         DATETIME,
    isActive          TINYINT  DEFAULT 1                   NOT NULL,
    emailVerified     TINYINT  DEFAULT 0                   NOT NULL,
    verificationToken VARCHAR(255),
    resetToken        VARCHAR(255),
    tokenExpiresAt    DATETIME
);

CREATE TABLE Guest
(
    pk_guest  BIGINT AUTO_INCREMENT PRIMARY KEY,
    guestName VARCHAR(255)                         NOT NULL,
    createdAt DATETIME DEFAULT CURRENT_TIMESTAMP() NOT NULL
);

CREATE TABLE Team
(
    pk_team      INT AUTO_INCREMENT PRIMARY KEY,
    name         VARCHAR(255) NOT NULL,
    startingLife INT          NOT NULL,
    finalLife    INT          NOT NULL
);

CREATE TABLE `Match`
(
    pk_match           BIGINT AUTO_INCREMENT PRIMARY KEY,
    name               VARCHAR(255),
    description        TEXT,
    format             ENUM (
        'Standard','Modern','Legacy','Vintage',
        'Pioneer','Pauper','Draft','Sealed',
        'Brawl','Two-Headed Giant','Commander'
        )                      NOT NULL,
    startingLife       INT     NOT NULL,
    startTime          TIME    NOT NULL,
    endTime            TIME,
    isTeamMatch        TINYINT NOT NULL DEFAULT 0,
    fk_appUser_creates BIGINT  NOT NULL,
    CONSTRAINT fkc_appUser_creates_match
        FOREIGN KEY (fk_appUser_creates)
            REFERENCES AppUser (pk_appUser)
            ON DELETE CASCADE
);

CREATE TABLE Player
(
    pk_player               BIGINT AUTO_INCREMENT PRIMARY KEY,
    startingLife            INT    NOT NULL,
    finalLife               INT    NOT NULL,
    isWinner                TINYINT,
    tax                     INT,
    placement               INT    NOT NULL,
    killCounter             INT,
    poisonCounter           INT,
    minPlayers              INT    NOT NULL DEFAULT 2,
    maxPlayers              INT    NOT NULL DEFAULT 6,
    fk_guest_enters         BIGINT,
    fk_appUser_participates BIGINT,
    fk_team_isIncluded      INT,
    fk_match_isPlayedIn     BIGINT NOT NULL,
    CONSTRAINT fkc_guest_enters_player
        FOREIGN KEY (fk_guest_enters)
            REFERENCES Guest (pk_guest)
            ON DELETE SET NULL,
    CONSTRAINT fkc_appUser_participates_player
        FOREIGN KEY (fk_appUser_participates)
            REFERENCES AppUser (pk_appUser)
            ON DELETE SET NULL,
    CONSTRAINT fkc_team_isIncluded_player
        FOREIGN KEY (fk_team_isIncluded)
            REFERENCES Team (pk_team)
            ON DELETE SET NULL,
    CONSTRAINT fkc_match_isPlayedIn_player
        FOREIGN KEY (fk_match_isPlayedIn)
            REFERENCES `Match` (pk_match)
            ON DELETE CASCADE
);

CREATE TABLE CommanderDamage
(
    pk_commanderDamage BIGINT AUTO_INCREMENT PRIMARY KEY,
    damageAmount       INT     NOT NULL DEFAULT 0,
    isLethal           TINYINT NOT NULL DEFAULT 0,
    fk_player_deals    BIGINT,
    fk_player_receives BIGINT,
    fk_match_refersTo  BIGINT  NOT NULL,
    CONSTRAINT fkc_player_deals_commanderDamage
        FOREIGN KEY (fk_player_deals)
            REFERENCES Player (pk_player)
            ON DELETE SET NULL,
    CONSTRAINT fkc_player_receives_commanderDamage
        FOREIGN KEY (fk_player_receives)
            REFERENCES Player (pk_player)
            ON DELETE SET NULL,
    CONSTRAINT fkc_match_refersTo_commanderDamage
        FOREIGN KEY (fk_match_refersTo)
            REFERENCES `Match` (pk_match)
            ON DELETE CASCADE
);

CREATE TABLE InviteCode
(
    pk_inviteCode     BIGINT AUTO_INCREMENT PRIMARY KEY,
    code              VARCHAR(255)               NOT NULL,
    status            ENUM ('active', 'expired') NOT NULL DEFAULT 'active',
    createdAt         DATETIME                            DEFAULT CURRENT_TIMESTAMP() NOT NULL,
    expiresAt         DATETIME                   NOT NULL,
    fk_match_connects BIGINT                     NOT NULL,
    CONSTRAINT fkc_match_connects_inviteCode
        FOREIGN KEY (fk_match_connects)
            REFERENCES `Match` (pk_match)
            ON DELETE CASCADE
);



