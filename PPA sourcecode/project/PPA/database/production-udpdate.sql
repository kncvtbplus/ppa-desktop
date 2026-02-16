ALTER TABLE "ppa_sector_level" ALTER "level" TYPE VARCHAR(1000);
ALTER TABLE "ppa_sector_level" ALTER "level" SET NOT NULL;
ALTER TABLE "ppa_sector_level" ALTER "level" SET DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (72);

ALTER TABLE "data_source" ALTER "weight_multiplier" TYPE NUMERIC;

INSERT INTO "_database_version" ("version") VALUES (73);

ALTER TABLE "ppa" DROP CONSTRAINT "ppa_user_id_name_key";

INSERT INTO "_database_version" ("version") VALUES (74);

ALTER TABLE "data_source" DROP CONSTRAINT "data_source_s3_file_name_key";

INSERT INTO "_database_version" ("version") VALUES (75);

ALTER TABLE "output" DROP CONSTRAINT "output_file_name_key";

INSERT INTO "_database_version" ("version") VALUES (76);

ALTER TABLE "data_source" DROP COLUMN "used";

INSERT INTO "_database_version" ("version") VALUES (77);

ALTER TABLE "user" ADD "selected_ppa_id" INT;

INSERT INTO "_database_version" ("version") VALUES (78);

INSERT INTO "user_role" ("user_id", "role") VALUES (1, 'ROLE_ADMIN');

INSERT INTO "_database_version" ("version") VALUES (79);

DELETE FROM "user_role" WHERE "role" = 'ROLE_ADMIN';
INSERT INTO "user" ("username", "password", "enabled") VALUES ('admin', '$2a$10$LNSNJGavCxJqLnJHCXM54O0HVBOp6l69Sbk2ho7qojo4gmMBh7u5y', true);
INSERT INTO "user_role" ("user_id", "role") VALUES (2, 'ROLE_USER');
INSERT INTO "user_role" ("user_id", "role") VALUES (2, 'ROLE_ADMIN');

INSERT INTO "_database_version" ("version") VALUES (80);

ALTER TABLE "user" ADD COLUMN "email" VARCHAR(1000);

INSERT INTO "_database_version" ("version") VALUES (81);

ALTER TABLE "user" ADD COLUMN "name" VARCHAR(1000);

INSERT INTO "_database_version" ("version") VALUES (82);

ALTER TABLE "user" ALTER "region" SET DEFAULT 'National';

INSERT INTO "_database_version" ("version") VALUES (84);

ALTER TABLE "user" ADD UNIQUE ("username");

INSERT INTO "_database_version" ("version") VALUES (85);

ALTER TABLE "ppa_metric" ADD "selected" BOOLEAN NOT NULL DEFAULT FALSE;

INSERT INTO "_database_version" ("version") VALUES (86);

ALTER TABLE "user" ADD "last_activity" TIMESTAMP NOT NULL DEFAULT NOW();

INSERT INTO "_database_version" ("version") VALUES (87);

ALTER TABLE "user" ADD "session_id" VARCHAR;
ALTER TABLE "user" DROP "last_activity";
ALTER TABLE "user" ADD "last_activity" TIMESTAMP;

INSERT INTO "_database_version" ("version") VALUES (88);

ALTER TABLE "user" ADD "recent_login" INT;

INSERT INTO "_database_version" ("version") VALUES (89);

ALTER TABLE "user" RENAME "session_id" TO "remote_address";

INSERT INTO "_database_version" ("version") VALUES (90);

ALTER TABLE "data_source" ADD "user_id" INT;

UPDATE "data_source" SET "user_id" = "p"."user_id" FROM "ppa" "p" WHERE "p"."id" = "ppa_id";

ALTER TABLE "data_source" ALTER "user_id" SET NOT NULL;

ALTER TABLE "data_source" ADD FOREIGN KEY ("user_id") REFERENCES "user" ("id") ON DELETE CASCADE;

INSERT INTO "_database_version" ("version") VALUES (91);


INSERT INTO "_database_version" ("version") VALUES (92);

CREATE TABLE "file"
(
"id" SERIAL PRIMARY KEY,
"user_id" INT NOT NULL,
"s3_file_name" VARCHAR NOT NULL,
"file_name" VARCHAR NOT NULL,
"column_names" TEXT NOT NULL,
FOREIGN KEY ("user_id") REFERENCES "user" ("id")
)
;

INSERT INTO "_database_version" ("version") VALUES (93);

ALTER TABLE "file" DROP CONSTRAINT "file_user_id_fkey";
ALTER TABLE "file" ADD FOREIGN KEY ("user_id") REFERENCES "user" ("id") ON DELETE CASCADE;

INSERT INTO "_database_version" ("version") VALUES (94);

ALTER TABLE "file" ADD UNIQUE ("user_id", "file_name");

INSERT INTO "_database_version" ("version") VALUES (95);

TRUNCATE TABLE "data_source" CASCADE;
ALTER TABLE "data_source" ADD "file_id" INT NOT NULL;
ALTER TABLE "data_source" DROP "s3_file_name";
ALTER TABLE "data_source" DROP "file_name";
ALTER TABLE "data_source" DROP "column_names";
ALTER TABLE "data_source" ADD FOREIGN KEY ("file_id") REFERENCES "file" ("id") ON DELETE CASCADE;

INSERT INTO "_database_version" ("version") VALUES (96);

ALTER TABLE "data_source" DROP CONSTRAINT "data_source_user_id_fkey";
ALTER TABLE "data_source" ADD UNIQUE ("ppa_id", "file_id");

INSERT INTO "_database_version" ("version") VALUES (97);

ALTER TABLE "metric" RENAME TO "metric_type";

INSERT INTO "_database_version" ("version") VALUES (98);

ALTER TABLE "ppa_metric" RENAME TO "metric";
ALTER TABLE "metric" RENAME "metric_id" TO "metric_typ_id";


INSERT INTO "_database_version" ("version") VALUES (99);

ALTER TABLE "metric" RENAME "metric_typ_id" TO "metric_type_id";


INSERT INTO "_database_version" ("version") VALUES (100);

TRUNCATE "metric" CASCADE;
ALTER TABLE "metric" ADD "data_source_id" INT NOT NULL;
ALTER TABLE "metric" ADD FOREIGN KEY ("data_source_id") REFERENCES "data_source" ("id") ON DELETE CASCADE;

INSERT INTO "_database_version" ("version") VALUES (101);

ALTER TABLE "metric" ADD "data_source_column_name" VARCHAR NOT NULL DEFAULT '';
ALTER TABLE "metric" ADD "column_value_frequencies" TEXT NOT NULL DEFAULT '';
ALTER TABLE "metric" ADD "selected_column_values" TEXT NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (102);

ALTER TABLE "file" RENAME TO "user_file";
ALTER TABLE "data_source" RENAME "file_id" TO "user_file_id";

INSERT INTO "_database_version" ("version") VALUES (103);

ALTER TABLE "data_source" ADD "subnational_unit_column_name" VARCHAR NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (104);

ALTER TABLE "data_source" ADD "facility_type_column_name" VARCHAR NOT NULL DEFAULT '';
ALTER TABLE "data_source" ADD "health_sector_column_name" VARCHAR NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (105);

ALTER TABLE "data_source" ADD "subnational_unit_column_value_frequencies" TEXT NOT NULL DEFAULT '';
ALTER TABLE "data_source" ADD "subnational_unit_column_selected_values" TEXT NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (106);

ALTER TABLE "data_source" RENAME "subnational_unit_column_value_frequencies" TO "subnational_unit_value_frequencies";
ALTER TABLE "data_source" RENAME "subnational_unit_column_selected_values" TO "subnational_unit_selected_values";

INSERT INTO "_database_version" ("version") VALUES (107);

ALTER TABLE "ppa" RENAME "region" TO "aggregation_level";

INSERT INTO "_database_version" ("version") VALUES (108);

ALTER SEQUENCE "file_id_seq" RENAME TO "user_file_id_seq";

INSERT INTO "_database_version" ("version") VALUES (109);

ALTER TABLE "metric" ALTER COLUMN "data_source_id" DROP NOT NULL;

INSERT INTO "_database_version" ("version") VALUES (110);

ALTER SEQUENCE "metric_id_seq" RENAME TO "metric_type_id_seq";
ALTER SEQUENCE "ppa_metric_id_seq" RENAME TO "metric_id_seq";

INSERT INTO "_database_version" ("version") VALUES (111);

DELETE FROM "metric_type" WHERE "name" in ('Facility Type', 'Health Sector', 'Region', 'Subset Column 1', 'Subset Column 2');

INSERT INTO "_database_version" ("version") VALUES (112);

ALTER TABLE "data_source" DROP COLUMN "user_id";

INSERT INTO "_database_version" ("version") VALUES (113);

ALTER TABLE "metric" DROP CONSTRAINT "metric_data_source_id_fkey";
ALTER TABLE "metric" ADD FOREIGN KEY ("data_source_id") REFERENCES "data_source" ("id") ON DELETE SET NULL;

INSERT INTO "_database_version" ("version") VALUES (114);

ALTER TABLE "data_source" ADD "facility_type_value_frequencies" TEXT NOT NULL DEFAULT '';
ALTER TABLE "data_source" ADD "health_sector_value_frequencies" TEXT NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (115);

DROP TABLE "ppa_metric_data_source";

INSERT INTO "_database_version" ("version") VALUES (116);

ALTER TABLE "metric_type" ADD "required" BOOLEAN NOT NULL DEFAULT FALSE;

INSERT INTO "_database_version" ("version") VALUES (117);

UPDATE "metric_type" SET "required" = true WHERE "name" in ('Number of Facilities','Care Seeking');

INSERT INTO "_database_version" ("version") VALUES (118);

ALTER TABLE "metric_type" ADD "columnValueFilter" BOOLEAN NOT NULL DEFAULT true;
UPDATE "metric_type" SET "columnValueFilter" = false where "name" in ('Number of Facilities','Care Seeking');

INSERT INTO "_database_version" ("version") VALUES (119);

ALTER TABLE "metric_type" RENAME "columnValueFilter" TO "column_value_filter";

INSERT INTO "_database_version" ("version") VALUES (120);

ALTER TABLE "output" ADD "chart_file_names" TEXT NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (121);

ALTER TABLE "metric_type" ADD "r_header" VARCHAR NOT NULL DEFAULT '';
ALTER TABLE "metric_type" ADD "r_header_availability" VARCHAR NOT NULL DEFAULT '';
ALTER TABLE "metric_type" ADD "r_header_access" VARCHAR NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (122);

UPDATE "metric_type" SET "name" = replace("name", 'Availability ', '') where "name" LIKE '%Availability%';

INSERT INTO "_database_version" ("version") VALUES (123);

UPDATE "metric_type" SET "r_header" = 'N.Facilities', "r_header_availability" = '', "r_header_access" = '' WHERE "name" = 'Number of Facilities';
UPDATE "metric_type" SET "r_header" = 'Care.Seeking', "r_header_availability" = '', "r_header_access" = '' WHERE "name" = 'Care Seeking';
UPDATE "metric_type" SET "r_header" = '', "r_header_availability" = 'Diagnostic.1.Availability', "r_header_access" = 'Diagnostic.1.Access' WHERE "name" = 'Diagnostic Availability 1';
UPDATE "metric_type" SET "r_header" = '', "r_header_availability" = 'Diagnostic.2.Availability', "r_header_access" = 'Diagnostic.2.Access' WHERE "name" = 'Diagnostic Availability 2';
UPDATE "metric_type" SET "r_header" = '', "r_header_availability" = 'Diagnostic.3.Availability', "r_header_access" = 'Diagnostic.3.Access' WHERE "name" = 'Diagnostic Availability 3';
UPDATE "metric_type" SET "r_header" = '', "r_header_availability" = 'Diagnostic.4.Availability', "r_header_access" = 'Diagnostic.4.Access' WHERE "name" = 'Diagnostic Availability 4';
UPDATE "metric_type" SET "r_header" = '', "r_header_availability" = 'Treatment.1.Availability', "r_header_access" = 'Treatment.1.Access' WHERE "name" = 'Treatment Availability 1';
UPDATE "metric_type" SET "r_header" = '', "r_header_availability" = 'Treatment.2.Availability', "r_header_access" = 'Treatment.2.Access' WHERE "name" = 'Treatment Availability 2';
UPDATE "metric_type" SET "r_header" = '', "r_header_availability" = 'Treatment.3.Availability', "r_header_access" = 'Treatment.3.Access' WHERE "name" = 'Treatment Availability 3';
UPDATE "metric_type" SET "r_header" = '', "r_header_availability" = 'Treatment.4.Availability', "r_header_access" = 'Treatment.4.Access' WHERE "name" = 'Treatment Availability 4';

INSERT INTO "_database_version" ("version") VALUES (124);

UPDATE "metric_type" SET "r_header" = 'N.Facilities', "r_header_availability" = '', "r_header_access" = '' WHERE "id" = 4;
UPDATE "metric_type" SET "r_header" = 'Care.Seeking', "r_header_availability" = '', "r_header_access" = '' WHERE "id" = 5;
UPDATE "metric_type" SET "r_header" = '', "r_header_availability" = 'Diagnostic.1.Availability', "r_header_access" = 'Diagnostic.1.Access' WHERE "id" = 6;
UPDATE "metric_type" SET "r_header" = '', "r_header_availability" = 'Diagnostic.2.Availability', "r_header_access" = 'Diagnostic.2.Access' WHERE "id" = 7;
UPDATE "metric_type" SET "r_header" = '', "r_header_availability" = 'Diagnostic.3.Availability', "r_header_access" = 'Diagnostic.3.Access' WHERE "id" = 8;
UPDATE "metric_type" SET "r_header" = '', "r_header_availability" = 'Diagnostic.4.Availability', "r_header_access" = 'Diagnostic.4.Access' WHERE "id" = 9;
UPDATE "metric_type" SET "r_header" = '', "r_header_availability" = 'Treatment.1.Availability', "r_header_access" = 'Treatment.1.Access' WHERE "id" = 10;
UPDATE "metric_type" SET "r_header" = '', "r_header_availability" = 'Treatment.2.Availability', "r_header_access" = 'Treatment.2.Access' WHERE "id" = 11;
UPDATE "metric_type" SET "r_header" = '', "r_header_availability" = 'Treatment.3.Availability', "r_header_access" = 'Treatment.3.Access' WHERE "id" = 12;
UPDATE "metric_type" SET "r_header" = '', "r_header_availability" = 'Treatment.4.Availability', "r_header_access" = 'Treatment.4.Access' WHERE "id" = 13;

INSERT INTO "_database_version" ("version") VALUES (125);

DELETE FROM "metric_type" WHERE "id" = 15;

INSERT INTO "_database_version" ("version") VALUES (126);

