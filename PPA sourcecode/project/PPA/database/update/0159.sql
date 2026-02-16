INSERT INTO "user_role"
("user_id", "role")
SELECT
"id", 'ROLE_USER'
FROM
"user"
WHERE
"id" NOT IN (SELECT "user_id" FROM "user_role")
;
 
INSERT INTO "_database_version" ("version") VALUES (159);

