DROP TABLE "user_role";
DROP TABLE "user";

CREATE TABLE "user"
(
	"id" SERIAL NOT NULL,
	"username" VARCHAR(100) NOT NULL,
	"password" VARCHAR(100) NOT NULL,
	"enabled" BOOLEAN NOT NULL DEFAULT FALSE,
	PRIMARY KEY ("id"),
	UNIQUE ("username")
)
;

CREATE TABLE "user_role"
(
	"id" SERIAL NOT NULL,
	"user_id" INT NOT NULL,
	"role" varchar(100) NOT NULL,
	PRIMARY KEY ("id"),
	UNIQUE ("user_id", "role"),
	FOREIGN KEY ("user_id") REFERENCES "user" ("id") ON DELETE CASCADE
)
;

INSERT INTO "user" ("username", "password", "enabled") VALUES
('test', 'test', true)
;

INSERT INTO "user_role" ("user_id", "role") VALUES
(1, 'ROLE_USER')
;

INSERT INTO "_database_version" ("version") VALUES (2);

