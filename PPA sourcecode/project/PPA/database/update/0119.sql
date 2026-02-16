ALTER TABLE "metric_type" ADD "columnValueFilter" BOOLEAN NOT NULL DEFAULT true;
UPDATE "metric_type" SET "columnValueFilter" = false where "name" in ('Number of Facilities','Care Seeking');

INSERT INTO "_database_version" ("version") VALUES (119);

