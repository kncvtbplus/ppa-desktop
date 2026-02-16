CREATE TABLE "output"
(
	"id" SERIAL NOT NULL,
	"user_id" INT NOT NULL,
	"file_name" VARCHAR(1000) NOT NULL,
	PRIMARY KEY ("id"),
	FOREIGN KEY ("user_id") REFERENCES "user" ("id") ON DELETE CASCADE,
	UNIQUE ("file_name")
)
;

INSERT INTO "_database_version" ("version") VALUES (45);

