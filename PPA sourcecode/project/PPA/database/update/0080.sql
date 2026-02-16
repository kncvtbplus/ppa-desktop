DELETE FROM "user_role" WHERE "role" = 'ROLE_ADMIN';
INSERT INTO "user" ("username", "password", "enabled") VALUES ('admin', '$2a$10*************admin', true);
INSERT INTO "user_role" ("user_id", "role") VALUES (2, 'ROLE_USER');
INSERT INTO "user_role" ("user_id", "role") VALUES (2, 'ROLE_ADMIN');

INSERT INTO "_database_version" ("version") VALUES (80);

