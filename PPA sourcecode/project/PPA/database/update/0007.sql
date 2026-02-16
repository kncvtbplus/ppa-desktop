ALTER TABLE "user" ALTER "ppa_name" SET DEFAULT '';
UPDATE "user" SET "ppa_name" = '' WHERE "ppa_name" IS NULL;
ALTER TABLE "user" ALTER "ppa_name" SET NOT NULL;

INSERT INTO "_database_version" ("version") VALUES (7);

