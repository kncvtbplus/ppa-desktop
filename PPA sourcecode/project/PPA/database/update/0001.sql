CREATE TABLE "_database_version" ("version" INT NOT NULL, "created" TIMESTAMP NOT NULL DEFAULT NOW());

CREATE  TABLE "user"
(
	"username" VARCHAR(100) NOT NULL,
	"password" VARCHAR(100) NOT NULL,
	"enabled" BOOLEAN NOT NULL DEFAULT FALSE,
	PRIMARY KEY ("username")
)
;

CREATE TABLE "user_role"
(
	"username" varchar(100) NOT NULL,
	"role" varchar(100) NOT NULL,
	PRIMARY KEY ("username", "role"),
	FOREIGN KEY ("username") REFERENCES "user" ("username") ON DELETE CASCADE
)
;

INSERT INTO "user" ("username", "password", "enabled") VALUES
('test', 'test', true)
;

INSERT INTO "user_role" ("username", "role") VALUES
('test', 'ROLE_USER')
;

INSERT INTO "_database_version" ("version") VALUES (1);

