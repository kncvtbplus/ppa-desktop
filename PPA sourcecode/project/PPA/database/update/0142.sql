ALTER TABLE "user" DROP "token";
ALTER TABLE "user" DROP "token_created";

CREATE TABLE "invitation"
(
"token" VARCHAR NOT NULL DEFAULT '',
"created" TIMESTAMP NOT NULL DEFAULT NOW(),
UNIQUE ("token")
)
;

INSERT INTO "_database_version" ("version") VALUES (142);

