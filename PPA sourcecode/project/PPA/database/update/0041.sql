CREATE TABLE "subnational_unit"
(
	"id" SERIAL NOT NULL,
	"user_id" INT NOT NULL,
	"name" VARCHAR(1000) NOT NULL DEFAULT '',
	PRIMARY KEY ("id"),
	FOREIGN KEY ("user_id") REFERENCES "user" ("id") ON DELETE CASCADE,
	UNIQUE ("name")
)
;

INSERT INTO "_database_version" ("version") VALUES (41);

