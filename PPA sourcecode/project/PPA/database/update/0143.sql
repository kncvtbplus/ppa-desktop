DROP TABLE "invitation";

CREATE TABLE "invitation"
(
	"id" SERIAL NOT NULL,
	"token" VARCHAR NOT NULL DEFAULT '',
	"created" TIMESTAMP NOT NULL DEFAULT NOW(),
	PRIMARY KEY ("id"),
	UNIQUE ("token")
)
;

INSERT INTO "_database_version" ("version") VALUES (143);

