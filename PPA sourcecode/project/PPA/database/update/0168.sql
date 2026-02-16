UPDATE "user" SET "navigation_page" = '';
ALTER TABLE "user" ALTER "navigation_page" SET NOT NULL;
ALTER TABLE "user" ALTER "navigation_page" SET DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (168);

