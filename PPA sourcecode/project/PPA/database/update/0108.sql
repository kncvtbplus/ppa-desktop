ALTER TABLE "ppa" RENAME "region" TO "aggregation_level";

INSERT INTO "_database_version" ("version") VALUES (108);

