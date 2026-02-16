INSERT INTO "user"
	("username", "password", "enabled", "email", "selected_account_id")
SELECT
	"email", '$2a$10$uYul/Qug4OCagnMIOzTBM.KT60fa1FzJB7/uDb66wikpnkvGwOFo.', true, "email", min("selected_account_id")
FROM
	"user"
WHERE
	"username" <> "email"
GROUP BY
	("email")
ON CONFLICT DO NOTHING
;

ALTER TABLE "account_user" ADD "administrator" BOOLEAN NOT NULL DEFAULT false;

INSERT INTO "account_user"
	("account_id", "user_id", "administrator")
SELECT
	"old"."selected_account_id", "new"."id", "user_role"."id" is not null
FROM
	"user" "old"
JOIN
	"user" "new" on "new"."username" = "old"."email"
LEFT JOIN
	"user_role" on "user_role"."user_id" = "old"."id" and "user_role"."role" = 'ROLE_ADMIN'
WHERE
	"old"."username" <> "old"."email"
ON CONFLICT DO NOTHING
;

DELETE FROM "user" WHERE "username" <> "email";

INSERT INTO "_database_version" ("version") VALUES (155);

