ALTER TABLE "account_user" RENAME TO "account_user_old";
ALTER SEQUENCE "account_user_id_seq" RENAME TO "account_user_old_id_seq";

CREATE TABLE "account_user"
(
    "id" SERIAL,
    "account_id" integer NOT NULL,
    "user_id" integer NOT NULL,
    "administrator" boolean NOT NULL DEFAULT false,
    "selected_ppa" integer,
    PRIMARY KEY ("id"),
    UNIQUE (account_id, user_id),
    FOREIGN KEY ("account_id") REFERENCES "account" ("id"),
	FOREIGN KEY ("user_id") REFERENCES "user" ("id")
)
;

DELETE FROM "account_user_old"
WHERE "user_id" not in (SELECT "id" FROM "user")
; 

DELETE FROM "account_user_old"
WHERE "account_id" not in (SELECT "id" FROM "account")
; 

INSERT INTO "account_user"
("id", "account_id", "user_id", "administrator")
SELECT
"id", "account_id", "user_id", "administrator"
FROM "account_user_old"
;

INSERT INTO "_database_version" ("version") VALUES (158);

