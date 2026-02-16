ALTER TABLE "data_source" ADD "user_id" INT;

UPDATE "data_source" SET "user_id" = "p"."user_id" FROM "ppa" "p" WHERE "p"."id" = "ppa_id";

ALTER TABLE "data_source" ALTER "user_id" SET NOT NULL;

ALTER TABLE "data_source" ADD FOREIGN KEY ("user_id") REFERENCES "user" ("id") ON DELETE CASCADE;

INSERT INTO "_database_version" ("version") VALUES (91);

