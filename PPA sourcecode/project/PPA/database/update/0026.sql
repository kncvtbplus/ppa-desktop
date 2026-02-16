CREATE TABLE "health_sector"
(
"id" SERIAL NOT NULL,
"user_id" INT NOT NULL,
"name" VARCHAR(1000) NOT NULL DEFAULT '',
"max_level" INT NOT NULL DEFAULT 1,
PRIMARY KEY ("id"),
UNIQUE ("name"),
FOREIGN KEY ("user_id") REFERENCES "user" ("id") ON DELETE CASCADE
)
;

INSERT INTO "_database_version" ("version") VALUES (26);

