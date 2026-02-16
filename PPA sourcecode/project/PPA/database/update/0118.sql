UPDATE "metric_type" SET "required" = true WHERE "name" in ('Number of Facilities','Care Seeking');

INSERT INTO "_database_version" ("version") VALUES (118);

