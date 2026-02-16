ALTER TABLE "metric_type" ADD "r_header" VARCHAR NOT NULL DEFAULT '';
ALTER TABLE "metric_type" ADD "r_header_availability" VARCHAR NOT NULL DEFAULT '';
ALTER TABLE "metric_type" ADD "r_header_access" VARCHAR NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (122);

