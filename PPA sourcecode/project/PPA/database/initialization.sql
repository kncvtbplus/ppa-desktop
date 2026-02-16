CREATE TABLE "_database_version" ("version" INT NOT NULL, "created" TIMESTAMP NOT NULL DEFAULT NOW());

CREATE  TABLE "user"
(
	"username" VARCHAR(100) NOT NULL,
	"password" VARCHAR(100) NOT NULL,
	"enabled" BOOLEAN NOT NULL DEFAULT FALSE,
	PRIMARY KEY ("username")
)
;

CREATE TABLE "user_role"
(
	"username" varchar(100) NOT NULL,
	"role" varchar(100) NOT NULL,
	PRIMARY KEY ("username", "role"),
	FOREIGN KEY ("username") REFERENCES "user" ("username") ON DELETE CASCADE
)
;

INSERT INTO "user" ("username", "password", "enabled") VALUES
('test', 'test', true)
;

INSERT INTO "user_role" ("username", "role") VALUES
('test', 'ROLE_USER')
;

INSERT INTO "_database_version" ("version") VALUES (1);

DROP TABLE "user_role";
DROP TABLE "user";

CREATE TABLE "user"
(
	"id" SERIAL NOT NULL,
	"username" VARCHAR(100) NOT NULL,
	"password" VARCHAR(100) NOT NULL,
	"enabled" BOOLEAN NOT NULL DEFAULT FALSE,
	PRIMARY KEY ("id"),
	UNIQUE ("username")
)
;

CREATE TABLE "user_role"
(
	"id" SERIAL NOT NULL,
	"user_id" INT NOT NULL,
	"role" varchar(100) NOT NULL,
	PRIMARY KEY ("id"),
	UNIQUE ("user_id", "role"),
	FOREIGN KEY ("user_id") REFERENCES "user" ("id") ON DELETE CASCADE
)
;

INSERT INTO "user" ("username", "password", "enabled") VALUES
('test', 'test', true)
;

INSERT INTO "user_role" ("user_id", "role") VALUES
(1, 'ROLE_USER')
;

INSERT INTO "_database_version" ("version") VALUES (2);

UPDATE "user" SET "password" = 'test' WHERE "username" = 'test';

INSERT INTO "_database_version" ("version") VALUES (3);

ALTER TABLE "user" ADD "ppa_name" VARCHAR(1000);

INSERT INTO "_database_version" ("version") VALUES (4);

ALTER TABLE "user" ADD "region" VARCHAR(1000) NOT NULL DEFAULT 'National';

INSERT INTO "_database_version" ("version") VALUES (5);

CREATE TABLE "data_source"
(
	"id" SERIAL NOT NULL,
	"user_id" INT NOT NULL,
	"s3_file_name" VARCHAR(1000) NOT NULL,
	"file_name" VARCHAR(1000) NOT NULL,
	PRIMARY KEY ("id"),
	FOREIGN KEY ("user_id") REFERENCES "user" ("id") ON DELETE CASCADE,
	UNIQUE ("s3_file_name")
)
;

INSERT INTO "_database_version" ("version") VALUES (6);

ALTER TABLE "user" ALTER "ppa_name" SET DEFAULT '';
UPDATE "user" SET "ppa_name" = '' WHERE "ppa_name" IS NULL;
ALTER TABLE "user" ALTER "ppa_name" SET NOT NULL;

INSERT INTO "_database_version" ("version") VALUES (7);

ALTER TABLE "data_source" ADD "type" VARCHAR(1000) NOT NULL DEFAULT 'Raw';

INSERT INTO "_database_version" ("version") VALUES (8);

CREATE TABLE "metric"
(
	"id" SERIAL NOT NULL,
	"name" VARCHAR(1000) NOT NULL,
	PRIMARY KEY ("id"),
	UNIQUE ("name")
)
;

INSERT INTO "metric" ("name") VALUES
('Number of Facilities'),
('Care Seeking'),
('Diagnostic Availability 1'),
('Diagnostic Availability 2'),
('Diagnostic Availability 3'),
('Diagnostic Availability 4'),
('Treatment Availability 1'),
('Treatment Availability 2'),
('Treatment Availability 3'),
('Treatment Availability 4'),
('Notification Location'),
('Treatment Location'),
('Treatment Outcome')
;

INSERT INTO "_database_version" ("version") VALUES (9);

CREATE TABLE "user_metric"
(
	"id" SERIAL NOT NULL,
	"user_id" INT NOT NULL,
	"metric_id" INT NOT NULL,
	"data_point_name" VARCHAR(1000) NOT NULL DEFAULT '',
	PRIMARY KEY ("id"),
	UNIQUE ("user_id", "metric_id"),
	FOREIGN KEY ("user_id") REFERENCES "user" ("id") ON DELETE CASCADE,
	FOREIGN KEY ("metric_id") REFERENCES "metric" ("id") ON DELETE CASCADE
)
;

INSERT INTO "_database_version" ("version") VALUES (10);

CREATE TABLE "user_metric_data_source"
(
	"id" SERIAL NOT NULL,
	"user_metric_id" INT NOT NULL,
	"data_source_id" INT NOT NULL,
	PRIMARY KEY ("id"),
	UNIQUE ("user_metric_id", "data_source_id"),
	FOREIGN KEY ("user_metric_id") REFERENCES "user_metric" ("id") ON DELETE CASCADE,
	FOREIGN KEY ("data_source_id") REFERENCES "data_source" ("id") ON DELETE CASCADE
)
;

INSERT INTO "_database_version" ("version") VALUES (11);

DROP TABLE "user_metric_data_source";

CREATE TABLE "user_metric_data_source"
(
	"user_metric_id" INT NOT NULL,
	"data_source_id" INT NOT NULL,
	FOREIGN KEY ("user_metric_id") REFERENCES "user_metric" ("id") ON DELETE CASCADE,
	FOREIGN KEY ("data_source_id") REFERENCES "data_source" ("id") ON DELETE CASCADE
)
;

INSERT INTO "_database_version" ("version") VALUES (12);

DROP TABLE "user_metric_data_source";

CREATE TABLE "user_metric_data_source"
(
	"id" SERIAL NOT NULL,
	"user_metric_id" INT NOT NULL,
	"data_source_id" INT NOT NULL,
	"data_source_column" VARCHAR(1000),
	PRIMARY KEY ("id"),
	UNIQUE ("user_metric_id", "data_source_id"),
	FOREIGN KEY ("user_metric_id") REFERENCES "user_metric" ("id") ON DELETE CASCADE,
	FOREIGN KEY ("data_source_id") REFERENCES "data_source" ("id") ON DELETE CASCADE
)
;

INSERT INTO "_database_version" ("version") VALUES (13);

ALTER TABLE "user_metric_data_source" RENAME COLUMN "data_source_column" TO "data_source_column_name";

INSERT INTO "_database_version" ("version") VALUES (14);

ALTER TABLE "user_metric_data_source" ALTER "data_source_column_name" TYPE VARCHAR(1000); 

CREATE TABLE "data_source_column"
(
	"id" SERIAL NOT NULL,
	"data_source_id" INT NOT NULL,
	"name" VARCHAR(1000),
	PRIMARY KEY ("id"),
	FOREIGN KEY ("data_source_id") REFERENCES "data_source" ("id") ON DELETE CASCADE
)
;

INSERT INTO "_database_version" ("version") VALUES (15);

DROP TABLE "data_source_column";

ALTER TABLE "data_source" ADD "column_names" VARCHAR(1000); 

INSERT INTO "_database_version" ("version") VALUES (16);

UPDATE "data_source" SET "column_names" = '';
ALTER TABLE "data_source" ALTER "column_names" SET DEFAULT ''; 
ALTER TABLE "data_source" ALTER "column_names" SET NOT NULL; 

INSERT INTO "_database_version" ("version") VALUES (17);

ALTER TABLE "metric" ADD "type" VARCHAR(1000) NOT NULL DEFAULT 'domain';
UPDATE "metric" SET "type" = 'variable';

INSERT INTO "metric" ("name", "type") VALUES
('Facility Type', 'domain'),
('Health Sector', 'domain'),
('Region', 'region')
;

INSERT INTO "_database_version" ("version") VALUES (18);

UPDATE "user_metric_data_source" SET "data_source_column_name" = '';
ALTER TABLE "user_metric_data_source" ALTER "data_source_column_name" SET NOT NULL;
ALTER TABLE "user_metric_data_source" ALTER "data_source_column_name" SET DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (19);

ALTER TABLE "data_source" ADD "used" BOOLEAN NOT NULL DEFAULT false;

INSERT INTO "_database_version" ("version") VALUES (20);

ALTER TABLE "data_source" ALTER "used" SET DEFAULT true;

INSERT INTO "_database_version" ("version") VALUES (21);

ALTER TABLE "data_source" ADD "info" TEXT NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (22);

ALTER TABLE "data_source" DROP "column_names";

INSERT INTO "_database_version" ("version") VALUES (23);

ALTER TABLE "data_source" ALTER "used" SET DEFAULT true;

INSERT INTO "_database_version" ("version") VALUES (24);

ALTER TABLE "user_metric_data_source" ADD "selected_column_values" TEXT NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (25);

CREATE TABLE "health_sector"
(
"id" SERIAL NOT NULL,
"user_id" INT NOT NULL,
"name" VARCHAR(1000) NOT NULL DEFAULT '',
"max_level" INT NOT NULL DEFAULT 1,
PRIMARY KEY ("id"),
UNIQUE ("name"),
FOREIGN KEY ("user_id") REFERENCES "user" ("id") ON DELETE CASCADE
)
;

INSERT INTO "_database_version" ("version") VALUES (26);

DELETE FROM "metric";

ALTER SEQUENCE "metric_id_seq" RESTART WITH 1;

INSERT INTO "metric" ("name", "type") VALUES
('Facility Type', 'domain'),
('Health Sector', 'domain'),
('Region', 'region')
;

INSERT INTO "metric" ("name") VALUES
('Number of Facilities'),
('Care Seeking'),
('Diagnostic Availability 1'),
('Diagnostic Availability 2'),
('Diagnostic Availability 3'),
('Diagnostic Availability 4'),
('Treatment Availability 1'),
('Treatment Availability 2'),
('Treatment Availability 3'),
('Treatment Availability 4'),
('Notification Location'),
('Treatment Location'),
('Treatment Outcome')
;

INSERT INTO "_database_version" ("version") VALUES (27);

DELETE FROM "metric";

ALTER TABLE "metric" ALTER "type" SET DEFAULT 'variable';

ALTER SEQUENCE "metric_id_seq" RESTART WITH 1;

INSERT INTO "metric" ("name", "type") VALUES
('Facility Type', 'domain'),
('Health Sector', 'domain'),
('Region', 'region')
;

INSERT INTO "metric" ("name") VALUES
('Number of Facilities'),
('Care Seeking'),
('Diagnostic Availability 1'),
('Diagnostic Availability 2'),
('Diagnostic Availability 3'),
('Diagnostic Availability 4'),
('Treatment Availability 1'),
('Treatment Availability 2'),
('Treatment Availability 3'),
('Treatment Availability 4'),
('Notification Location'),
('Treatment Location'),
('Treatment Outcome')
;

INSERT INTO "_database_version" ("version") VALUES (28);

DROP TABLE "health_sector";

CREATE TABLE "ppa_sector"
(
"id" SERIAL NOT NULL,
"user_id" INT NOT NULL,
"name" VARCHAR(1000) NOT NULL DEFAULT '',
"levels" VARCHAR(1000) NOT NULL DEFAULT '',
PRIMARY KEY ("id"),
UNIQUE ("name"),
FOREIGN KEY ("user_id") REFERENCES "user" ("id") ON DELETE CASCADE
)
;

INSERT INTO "_database_version" ("version") VALUES (29);

ALTER TABLE "data_source" DROP "info";

ALTER TABLE "user_metric_data_source" DROP "selected_column_values";

ALTER TABLE "user_metric_data_source" ADD "available_column_value_frequencies" TEXT NOT NULL DEFAULT '';
ALTER TABLE "user_metric_data_source" ADD "selected_column_values" TEXT NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (30);

ALTER TABLE "data_source" ADD "column_names" TEXT NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (31);

CREATE TABLE "ppa_sector_mapping"
(
	"id" INT NOT NULL,
	"data_source_id" INT NOT NULL,
	"ppa_sector_id" INT NOT NULL,
	"value_combinations" TEXT NOT NULL DEFAULT '',
	PRIMARY KEY ("id"),
	UNIQUE ("data_source_id", "ppa_sector_id"),
	FOREIGN KEY ("data_source_id") REFERENCES "data_source" ("id") ON DELETE CASCADE,
	FOREIGN KEY ("ppa_sector_id") REFERENCES "ppa_sector" ("id") ON DELETE CASCADE
)
;

INSERT INTO "_database_version" ("version") VALUES (32);

ALTER TABLE "data_source" ADD "available_ppa_sector_mapping_value_combinations" TEXT NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (33);

ALTER TABLE "data_source" RENAME "available_ppa_sector_mapping_value_combinations" TO "available_ppa_sector_mapping_value_combination_frequencies";

INSERT INTO "_database_version" ("version") VALUES (34);

ALTER TABLE "ppa_sector" DROP "levels";

CREATE TABLE "ppa_sector_level"
(
	"id" SERIAL NOT NULL,
	"ppa_sector_id" INT NOT NULL,
	"level" INT NOT NULL DEFAULT 0,
	PRIMARY KEY ("id"),
	FOREIGN KEY ("ppa_sector_id") REFERENCES "ppa_sector" ("id") ON DELETE CASCADE,
	UNIQUE ("ppa_sector_id", "level")
)
;

DROP TABLE "ppa_sector_mapping";

CREATE TABLE "ppa_sector_mapping"
(
	"id" INT NOT NULL,
	"data_source_id" INT NOT NULL,
	"ppa_sector_level_id" INT NOT NULL,
	"value_combination" VARCHAR NOT NULL DEFAULT '',
	PRIMARY KEY ("id"),
	FOREIGN KEY ("data_source_id") REFERENCES "data_source" ("id") ON DELETE CASCADE,
	FOREIGN KEY ("ppa_sector_level_id") REFERENCES "ppa_sector_level" ("id") ON DELETE CASCADE,
	UNIQUE ("data_source_id", "ppa_sector_level_id", "value_combination")
)
;

INSERT INTO "_database_version" ("version") VALUES (35);

DROP TABLE "ppa_sector_mapping";
DROP TABLE "ppa_sector_level";

CREATE TABLE "ppa_sector_level"
(
	"id" SERIAL NOT NULL,
	"ppa_sector_id" INT NOT NULL,
	"level" INT NOT NULL DEFAULT 0,
	PRIMARY KEY ("id"),
	FOREIGN KEY ("ppa_sector_id") REFERENCES "ppa_sector" ("id") ON DELETE CASCADE,
	UNIQUE ("ppa_sector_id", "level")
)
;

CREATE TABLE "ppa_sector_mapping"
(
	"id" SERIAL NOT NULL,
	"data_source_id" INT NOT NULL,
	"ppa_sector_level_id" INT NOT NULL,
	"value_combination" VARCHAR NOT NULL DEFAULT '',
	PRIMARY KEY ("id"),
	FOREIGN KEY ("data_source_id") REFERENCES "data_source" ("id") ON DELETE CASCADE,
	FOREIGN KEY ("ppa_sector_level_id") REFERENCES "ppa_sector_level" ("id") ON DELETE CASCADE,
	UNIQUE ("data_source_id", "ppa_sector_level_id", "value_combination")
)
;

INSERT INTO "_database_version" ("version") VALUES (36);

ALTER TABLE "user_metric_data_source" ADD "available_column_values" TEXT NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (37);

ALTER TABLE "metric" ADD "subtype" VARCHAR(1000);

UPDATE "metric" SET "subtype" = 'healthSector' where "name" = 'Health Sector';
UPDATE "metric" SET "subtype" = 'facilityType' where "name" = 'Facility Type';

INSERT INTO "_database_version" ("version") VALUES (38);

ALTER TABLE "user_metric_data_source" DROP "available_column_values";

ALTER TABLE "data_source" ADD "health_sector_column_values" TEXT;
ALTER TABLE "data_source" ADD "facility_type_column_values" TEXT;

INSERT INTO "_database_version" ("version") VALUES (39);

UPDATE "data_source" SET "health_sector_column_values" = '';
ALTER TABLE "data_source" ALTER "health_sector_column_values" SET NOT NULL;
ALTER TABLE "data_source" ALTER "health_sector_column_values" SET DEFAULT '';

UPDATE "data_source" SET "facility_type_column_values" = '';
ALTER TABLE "data_source" ALTER "facility_type_column_values" SET NOT NULL;
ALTER TABLE "data_source" ALTER "facility_type_column_values" SET DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (40);

CREATE TABLE "subnational_unit"
(
	"id" SERIAL NOT NULL,
	"user_id" INT NOT NULL,
	"name" VARCHAR(1000) NOT NULL DEFAULT '',
	PRIMARY KEY ("id"),
	FOREIGN KEY ("user_id") REFERENCES "user" ("id") ON DELETE CASCADE,
	UNIQUE ("name")
)
;

INSERT INTO "_database_version" ("version") VALUES (41);

ALTER TABLE "ppa_sector_mapping" ALTER "value_combination" TYPE VARCHAR(1000);

CREATE TABLE "subnational_unit_mapping"
(
	"id" SERIAL NOT NULL,
	"data_source_id" INT NOT NULL,
	"subnational_unit_id" INT NOT NULL,
	"value" VARCHAR(1000) NOT NULL DEFAULT '',
	PRIMARY KEY ("id"),
	FOREIGN KEY ("data_source_id") REFERENCES "data_source" ("id") ON DELETE CASCADE,
	FOREIGN KEY ("subnational_unit_id") REFERENCES "subnational_unit" ("id") ON DELETE CASCADE,
	UNIQUE ("data_source_id", "subnational_unit_id", "value")
)
;

INSERT INTO "_database_version" ("version") VALUES (42);

DROP TABLE "subnational_unit_mapping";

CREATE TABLE "subnational_unit_mapping"
(
	"id" SERIAL NOT NULL,
	"data_source_id" INT NOT NULL,
	"subnational_unit_id" INT NOT NULL,
	"region_column_value" VARCHAR(1000) NOT NULL DEFAULT '',
	PRIMARY KEY ("id"),
	FOREIGN KEY ("data_source_id") REFERENCES "data_source" ("id") ON DELETE CASCADE,
	FOREIGN KEY ("subnational_unit_id") REFERENCES "subnational_unit" ("id") ON DELETE CASCADE,
	UNIQUE ("data_source_id", "region_column_value")
)
;

INSERT INTO "_database_version" ("version") VALUES (43);

DROP TABLE "ppa_sector_mapping";

CREATE TABLE "ppa_sector_mapping"
(
	"id" SERIAL NOT NULL,
	"data_source_id" INT NOT NULL,
	"ppa_sector_level_id" INT NOT NULL,
	"value_combination" VARCHAR NOT NULL DEFAULT '',
	PRIMARY KEY ("id"),
	FOREIGN KEY ("data_source_id") REFERENCES "data_source" ("id") ON DELETE CASCADE,
	FOREIGN KEY ("ppa_sector_level_id") REFERENCES "ppa_sector_level" ("id") ON DELETE CASCADE,
	UNIQUE ("data_source_id", "value_combination")
)
;

INSERT INTO "_database_version" ("version") VALUES (44);

CREATE TABLE "output"
(
	"id" SERIAL NOT NULL,
	"user_id" INT NOT NULL,
	"file_name" VARCHAR(1000) NOT NULL,
	PRIMARY KEY ("id"),
	FOREIGN KEY ("user_id") REFERENCES "user" ("id") ON DELETE CASCADE,
	UNIQUE ("file_name")
)
;

INSERT INTO "_database_version" ("version") VALUES (45);

ALTER TABLE "output" ADD "created" TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

INSERT INTO "_database_version" ("version") VALUES (46);

ALTER TABLE "metric" ADD "r_name" VARCHAR(1000) NOT NULL DEFAULT '';

UPDATE "metric" SET "r_name" = 'Facility.Type' WHERE "id" = 1;
UPDATE "metric" SET "r_name" = 'Facility.Sector' WHERE "id" = 2;
UPDATE "metric" SET "r_name" = 'Region' WHERE "id" = 3;
UPDATE "metric" SET "r_name" = 'N.Facilities' WHERE "id" = 4;
UPDATE "metric" SET "r_name" = 'Care.Seeking' WHERE "id" = 5;
UPDATE "metric" SET "r_name" = 'Dx.Availability.1' WHERE "id" = 6;
UPDATE "metric" SET "r_name" = 'Dx.Availability.2' WHERE "id" = 7;
UPDATE "metric" SET "r_name" = 'Dx.Availability.3' WHERE "id" = 8;
UPDATE "metric" SET "r_name" = 'Dx.Availability.4' WHERE "id" = 9;
UPDATE "metric" SET "r_name" = 'Tx.Availability.1' WHERE "id" = 10;
UPDATE "metric" SET "r_name" = 'Tx.Availability.2' WHERE "id" = 11;
UPDATE "metric" SET "r_name" = 'Tx.Availability.3' WHERE "id" = 12;
UPDATE "metric" SET "r_name" = 'Tx.Availability.4' WHERE "id" = 13;
UPDATE "metric" SET "r_name" = 'Notification.Location' WHERE "id" = 14;
UPDATE "metric" SET "r_name" = 'Tx.Location' WHERE "id" = 15;
UPDATE "metric" SET "r_name" = 'Tx.Outcome' WHERE "id" = 16;

INSERT INTO "_database_version" ("version") VALUES (47);

ALTER TABLE "data_source" ADD "subset_column_1" VARCHAR(1000) NOT NULL DEFAULT '';
ALTER TABLE "data_source" ADD "subset_column_2" VARCHAR(1000) NOT NULL DEFAULT '';
ALTER TABLE "data_source" ADD "subset_column_1_values" TEXT NOT NULL DEFAULT '';
ALTER TABLE "data_source" ADD "subset_column_2_values" TEXT NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (48);

ALTER TABLE "data_source" ADD "subset_column_1_selected_values" TEXT NOT NULL DEFAULT '';
ALTER TABLE "data_source" ADD "subset_column_2_selected_values" TEXT NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (49);

INSERT INTO "metric" ("name", "type", "subtype", "r_name") VALUES ('Subset Column 1', 'subset', 'column1', '');
INSERT INTO "metric" ("name", "type", "subtype", "r_name") VALUES ('Subset Column 2', 'subset', 'column2', '');

INSERT INTO "_database_version" ("version") VALUES (50);

ALTER TABLE "data_source" DROP "subset_column_1";
ALTER TABLE "data_source" DROP "subset_column_1_values";
ALTER TABLE "data_source" DROP "subset_column_1_selected_values";
ALTER TABLE "data_source" DROP "subset_column_2";
ALTER TABLE "data_source" DROP "subset_column_2_values";
ALTER TABLE "data_source" DROP "subset_column_2_selected_values";

INSERT INTO "_database_version" ("version") VALUES (51);

CREATE TABLE "ppa"
(
"id" SERIAL NOT NULL,
"user_id" INT NOT NULL,
"name" VARCHAR(1000) NOT NULL DEFAULT '',
PRIMARY KEY ("id"),
FOREIGN KEY ("user_id") REFERENCES "user" ("id") ON DELETE CASCADE,
UNIQUE ("user_id", "name")
)
;

INSERT INTO "_database_version" ("version") VALUES (52);

DELETE FROM "data_source";
ALTER TABLE "data_source" RENAME "user_id" TO "ppa_id";
ALTER TABLE "data_source" DROP CONSTRAINT "data_source_user_id_fkey";
ALTER TABLE "data_source" ADD FOREIGN KEY ("ppa_id") REFERENCES "ppa" ("id") ON DELETE CASCADE;

INSERT INTO "_database_version" ("version") VALUES (53);

DELETE FROM "user_metric";

ALTER TABLE "user_metric" RENAME TO "ppa_metric";
ALTER TABLE "ppa_metric" RENAME "user_id" TO "ppa_id";
ALTER TABLE "ppa_metric" DROP CONSTRAINT "user_metric_user_id_fkey";
ALTER TABLE "ppa_metric" ADD FOREIGN KEY ("ppa_id") REFERENCES "ppa" ("id") ON DELETE CASCADE;

INSERT INTO "_database_version" ("version") VALUES (54);

DELETE FROM "ppa_sector";

ALTER TABLE "ppa_sector" RENAME "user_id" TO "ppa_id";
ALTER TABLE "ppa_sector" DROP CONSTRAINT "ppa_sector_user_id_fkey";
ALTER TABLE "ppa_sector" ADD FOREIGN KEY ("ppa_id") REFERENCES "ppa" ("id") ON DELETE CASCADE;

INSERT INTO "_database_version" ("version") VALUES (55);

DELETE FROM "subnational_unit";

ALTER TABLE "subnational_unit" RENAME "user_id" TO "ppa_id";
ALTER TABLE "subnational_unit" DROP CONSTRAINT "subnational_unit_user_id_fkey";
ALTER TABLE "subnational_unit" ADD FOREIGN KEY ("ppa_id") REFERENCES "ppa" ("id") ON DELETE CASCADE;

INSERT INTO "_database_version" ("version") VALUES (56);

DELETE FROM "output";

ALTER TABLE "output" RENAME "user_id" TO "ppa_id";
ALTER TABLE "output" DROP CONSTRAINT "output_user_id_fkey";
ALTER TABLE "output" ADD FOREIGN KEY ("ppa_id") REFERENCES "ppa" ("id") ON DELETE CASCADE;

INSERT INTO "_database_version" ("version") VALUES (57);

ALTER TABLE "ppa" ADD "region" VARCHAR(1000) NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (58);

ALTER TABLE "ppa" ALTER "region" SET DEFAULT 'National';

INSERT INTO "_database_version" ("version") VALUES (59);

ALTER TABLE "user_metric_data_source" RENAME TO "ppa_metric_data_source";

ALTER TABLE "ppa_metric_data_source" RENAME "user_metric_id" TO "ppa_metric_id";

INSERT INTO "_database_version" ("version") VALUES (60);

ALTER TABLE "ppa_metric_data_source" DROP CONSTRAINT "user_metric_data_source_user_metric_id_fkey";

DELETE FROM "ppa_metric";
DROP TABLE "ppa_metric";
CREATE TABLE "ppa_metric"
(
    "id" SERIAL NOT NULL,
    "ppa_id" integer NOT NULL,
    "metric_id" integer NOT NULL,
    "data_point_name" character varying(1000) NOT NULL DEFAULT ''::character varying,
    PRIMARY KEY ("id"),
    UNIQUE ("ppa_id", "metric_id"),
    FOREIGN KEY ("ppa_id")
        REFERENCES "ppa" ("id")
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    FOREIGN KEY ("metric_id")
        REFERENCES "metric" ("id")
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)
;

ALTER TABLE "ppa_metric_data_source" ADD FOREIGN KEY ("ppa_metric_id") REFERENCES "ppa_metric" ("id") ON DELETE CASCADE;

INSERT INTO "_database_version" ("version") VALUES (61);

DROP TABLE public.ppa_metric_data_source;

CREATE TABLE public.ppa_metric_data_source
(
    "id" SERIAL NOT NULL,
    ppa_metric_id integer NOT NULL,
    data_source_id integer NOT NULL,
    data_source_column_name character varying(1000) COLLATE pg_catalog."default" NOT NULL DEFAULT ''::character varying,
    available_column_value_frequencies text COLLATE pg_catalog."default" NOT NULL DEFAULT ''::text,
    selected_column_values text COLLATE pg_catalog."default" NOT NULL DEFAULT ''::text,
    CONSTRAINT user_metric_data_source_pkey PRIMARY KEY (id),
    CONSTRAINT user_metric_data_source_user_metric_id_data_source_id_key UNIQUE (ppa_metric_id, data_source_id),
    CONSTRAINT ppa_metric_data_source_ppa_metric_id_fkey FOREIGN KEY (ppa_metric_id)
        REFERENCES public.ppa_metric (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    CONSTRAINT user_metric_data_source_data_source_id_fkey FOREIGN KEY (data_source_id)
        REFERENCES public.data_source (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)
;

INSERT INTO "_database_version" ("version") VALUES (62);

DELETE FROM "data_source";
DELETE FROM "subnational_unit";
DELETE FROM "ppa_metric_data_source";
DELETE FROM "ppa_sector_mapping";
DELETE FROM "subnational_unit_mapping";

ALTER TABLE "ppa_metric_data_source" DROP CONSTRAINT "user_metric_data_source_data_source_id_fkey";
ALTER TABLE "ppa_sector_mapping" DROP CONSTRAINT "ppa_sector_mapping_data_source_id_fkey";
ALTER TABLE "subnational_unit_mapping" DROP CONSTRAINT "subnational_unit_mapping_data_source_id_fkey";

DROP TABLE public.data_source;

CREATE TABLE public.data_source
(
    id SERIAL NOT NULL,
    ppa_id integer NOT NULL,
    s3_file_name character varying(1000) COLLATE pg_catalog."default" NOT NULL,
    file_name character varying(1000) COLLATE pg_catalog."default" NOT NULL,
    type character varying(1000) COLLATE pg_catalog."default" NOT NULL DEFAULT 'Raw'::character varying,
    used boolean NOT NULL DEFAULT true,
    column_names text COLLATE pg_catalog."default" NOT NULL DEFAULT ''::text,
    available_ppa_sector_mapping_value_combination_frequencies text COLLATE pg_catalog."default" NOT NULL DEFAULT ''::text,
    health_sector_column_values text COLLATE pg_catalog."default" NOT NULL DEFAULT ''::text,
    facility_type_column_values text COLLATE pg_catalog."default" NOT NULL DEFAULT ''::text,
    CONSTRAINT data_source_pkey PRIMARY KEY (id),
    CONSTRAINT data_source_s3_file_name_key UNIQUE (s3_file_name),
    CONSTRAINT data_source_ppa_id_fkey FOREIGN KEY (ppa_id)
        REFERENCES public.ppa (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)
;

ALTER TABLE "ppa_metric_data_source" ADD FOREIGN KEY ("data_source_id") REFERENCES "data_source" ("id") ON DELETE CASCADE;
ALTER TABLE "ppa_sector_mapping" ADD FOREIGN KEY ("data_source_id") REFERENCES "data_source" ("id") ON DELETE CASCADE;
ALTER TABLE "subnational_unit_mapping" ADD FOREIGN KEY ("data_source_id") REFERENCES "data_source" ("id") ON DELETE CASCADE;

-- Table: public.subnational_unit

ALTER TABLE "subnational_unit_mapping" DROP CONSTRAINT "subnational_unit_mapping_subnational_unit_id_fkey";

DROP TABLE public.subnational_unit;

CREATE TABLE public.subnational_unit
(
    id SERIAL NOT NULL,
    ppa_id integer NOT NULL,
    name character varying(1000) COLLATE pg_catalog."default" NOT NULL DEFAULT ''::character varying,
    CONSTRAINT subnational_unit_pkey PRIMARY KEY (id),
    CONSTRAINT subnational_unit_name_key UNIQUE (ppa_id, name),
    CONSTRAINT subnational_unit_ppa_id_fkey FOREIGN KEY (ppa_id)
        REFERENCES public.ppa (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)
;

ALTER TABLE "subnational_unit_mapping" ADD FOREIGN KEY ("subnational_unit_id") REFERENCES "subnational_unit" ("id") ON DELETE CASCADE;

-- Table: public.subnational_unit_mapping

DROP TABLE public.subnational_unit_mapping;

CREATE TABLE public.subnational_unit_mapping
(
    id SERIAL NOT NULL,
    data_source_id integer NOT NULL,
    subnational_unit_id integer NOT NULL,
    region_column_value character varying(1000) COLLATE pg_catalog."default" NOT NULL DEFAULT ''::character varying,
    CONSTRAINT subnational_unit_mapping_pkey PRIMARY KEY (id),
    CONSTRAINT subnational_unit_mapping_data_source_id_region_column_value_key UNIQUE (data_source_id, region_column_value),
    CONSTRAINT subnational_unit_mapping_data_source_id_fkey FOREIGN KEY (data_source_id)
        REFERENCES public.data_source (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    CONSTRAINT subnational_unit_mapping_subnational_unit_id_fkey FOREIGN KEY (subnational_unit_id)
        REFERENCES public.subnational_unit (id) MATCH SIMPLE
        ON UPDATE NO ACTION
        ON DELETE CASCADE
)
;

INSERT INTO "_database_version" ("version") VALUES (63);

ALTER TABLE "ppa_sector" DROP CONSTRAINT "ppa_sector_name_key";
ALTER TABLE "ppa_sector" ADD UNIQUE ("ppa_id", "name");

INSERT INTO "_database_version" ("version") VALUES (64);

ALTER TABLE "data_source" ADD "subset_column1_name" VARCHAR(1000) NOT NULL DEFAULT '';
ALTER TABLE "data_source" ADD "subset_column1_values" TEXT NOT NULL DEFAULT '';
ALTER TABLE "data_source" ADD "subset_column1_selected_values" TEXT NOT NULL DEFAULT '';
ALTER TABLE "data_source" ADD "subset_column2_name" VARCHAR(1000) NOT NULL DEFAULT '';
ALTER TABLE "data_source" ADD "subset_column2_values" TEXT NOT NULL DEFAULT '';
ALTER TABLE "data_source" ADD "subset_column2_selected_values" TEXT NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (65);

ALTER TABLE "data_source" ADD "subset_column1_value_frequencies" TEXT NOT NULL DEFAULT '';
ALTER TABLE "data_source" ADD "subset_column2_value_frequencies" TEXT NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (66);

ALTER TABLE "data_source" ADD "selected_row_count" INT NOT NULL DEFAULT 0;

INSERT INTO "_database_version" ("version") VALUES (67);

UPDATE "metric" SET "type" = 'facilityType' WHERE "subtype" = 'facilityType';
UPDATE "metric" SET "type" = 'healthSector' WHERE "subtype" = 'healthSector';

INSERT INTO "_database_version" ("version") VALUES (68);

UPDATE "metric" SET "subtype" = 'service' WHERE "name" in ('Diagnostic Availability 1', 'Diagnostic Availability 2', 'Diagnostic Availability 3', 'Diagnostic Availability 4', 'Treatment Availability 1', 'Treatment Availability 2', 'Treatment Availability 3', 'Treatment Availability 4');

INSERT INTO "_database_version" ("version") VALUES (69);

ALTER TABLE "data_source" ADD "weight_multiplier" INT NOT NULL DEFAULT 1;

INSERT INTO "_database_version" ("version") VALUES (70);

ALTER TABLE "data_source" ADD "weight_column_name" VARCHAR(1000) NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (71);

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

CREATE TABLE "account"
(
"id" SERIAL NOT NULL,
"name" VARCHAR,
PRIMARY KEY ("id")
)
;

INSERT INTO "account"
SELECT "id", "username"
FROM "user"
;

ALTER TABLE "user" ADD "account_id" INT;
UPDATE "user" SET "account_id" = "id";
ALTER TABLE "user" ALTER "account_id" SET NOT NULL;
ALTER TABLE "user" ADD FOREIGN KEY ("account_id") REFERENCES "account" ("id");

ALTER TABLE "ppa" ADD "account_id" INT;
UPDATE "ppa" SET "account_id" = "user_id";
ALTER TABLE "ppa" ALTER "account_id" SET NOT NULL;
ALTER TABLE "ppa" ADD FOREIGN KEY ("account_id") REFERENCES "account" ("id");
ALTER TABLE "ppa" DROP CONSTRAINT "ppa_user_id_fkey";
ALTER TABLE "ppa" DROP "user_id";

INSERT INTO "_database_version" ("version") VALUES (127);

ALTER TABLE "user_file" ADD "account_id" INT;
UPDATE "user_file" SET "account_id" = "user_id";
ALTER TABLE "user_file" ALTER "account_id" SET NOT NULL;
ALTER TABLE "user_file" ADD FOREIGN KEY ("account_id") REFERENCES "account" ("id");
ALTER TABLE "user_file" DROP CONSTRAINT "file_user_id_fkey";
ALTER TABLE "user_file" DROP "user_id";

INSERT INTO "_database_version" ("version") VALUES (128);

ALTER TABLE "user_file" ADD UNIQUE ("account_id", "file_name");

INSERT INTO "_database_version" ("version") VALUES (129);

ALTER TABLE "account" ADD UNIQUE ("name");

INSERT INTO "_database_version" ("version") VALUES (130);

ALTER SEQUENCE "account_id_seq" RESTART WITH 20;

INSERT INTO "_database_version" ("version") VALUES (131);

ALTER SEQUENCE "account_id_seq" RESTART WITH 1000;

INSERT INTO "_database_version" ("version") VALUES (132);

CREATE TABLE "user_file_content"
(
"id" SERIAL,
"user_file_id" INT NOT NULL,
"row_number" INT NOT NULL,
"column_name" VARCHAR NOT NULL,
"value" VARCHAR NOT NULL,
PRIMARY KEY ("id"),
FOREIGN KEY ("user_file_id") REFERENCES "user_file" ("id"),
UNIQUE ("user_file_id", "row_number", "column_name")
)
; 

INSERT INTO "_database_version" ("version") VALUES (133);

ALTER TABLE "user_file_content" RENAME TO "user_file_value";

INSERT INTO "_database_version" ("version") VALUES (134);

ALTER SEQUENCE "user_file_content_id_seq" RENAME TO "user_file_value_id_seq";

INSERT INTO "_database_version" ("version") VALUES (135);

ALTER TABLE "user_file_value" DROP CONSTRAINT "user_file_content_user_file_id_fkey";
ALTER TABLE "user_file_value" ADD FOREIGN KEY ("user_file_id") REFERENCES "user_file" ("id") ON DELETE CASCADE;

INSERT INTO "_database_version" ("version") VALUES (136);

ALTER TABLE "user_file_value" DROP CONSTRAINT "user_file_value_user_file_id_fkey";

INSERT INTO "_database_version" ("version") VALUES (137);

ALTER TABLE "user" ADD "logged" BOOLEAN NOT NULL DEFAULT FALSE;

INSERT INTO "_database_version" ("version") VALUES (138);

ALTER TABLE "ppa_sector" ADD "editable" BOOLEAN NOT NULL DEFAULT FALSE;

INSERT INTO "_database_version" ("version") VALUES (139);

ALTER TABLE "ppa_sector" ADD "selected" BOOLEAN NOT NULL DEFAULT FALSE;

INSERT INTO "_database_version" ("version") VALUES (140);

ALTER TABLE "user" ADD "token" VARCHAR;
ALTER TABLE "user" ADD "token_created" TIMESTAMP;

INSERT INTO "_database_version" ("version") VALUES (141);

ALTER TABLE "user" DROP "token";
ALTER TABLE "user" DROP "token_created";

CREATE TABLE "invitation"
(
"token" VARCHAR NOT NULL DEFAULT '',
"created" TIMESTAMP NOT NULL DEFAULT NOW(),
UNIQUE ("token")
)
;

INSERT INTO "_database_version" ("version") VALUES (142);

DROP TABLE "invitation";

CREATE TABLE "invitation"
(
	"id" SERIAL NOT NULL,
	"token" VARCHAR NOT NULL DEFAULT '',
	"created" TIMESTAMP NOT NULL DEFAULT NOW(),
	PRIMARY KEY ("id"),
	UNIQUE ("token")
)
;

INSERT INTO "_database_version" ("version") VALUES (143);

DROP TABLE "invitation";

CREATE TABLE "invitation"
(
	"id" SERIAL NOT NULL,
	"token" VARCHAR NOT NULL DEFAULT '',
	"created" TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
	PRIMARY KEY ("id"),
	UNIQUE ("token")
)
;

INSERT INTO "_database_version" ("version") VALUES (144);

ALTER TABLE "invitation" ADD "email" VARCHAR NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (145);

ALTER TABLE "invitation" ADD "administrator" BOOLEAN NOT NULL DEFAULT FALSE;

INSERT INTO "_database_version" ("version") VALUES (146);

ALTER TABLE "invitation" ADD "account" VARCHAR NOT NULL DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (147);

TRUNCATE TABLE "invitation";

ALTER TABLE "invitation" DROP "account";
ALTER TABLE "invitation" ADD "account_id" INT NOT NULL;

ALTER TABLE "invitation" ADD FOREIGN KEY ("account_id") REFERENCES "account" ("id");

INSERT INTO "_database_version" ("version") VALUES (148);

ALTER TABLE "user" ADD "password_reset_token" VARCHAR;

INSERT INTO "_database_version" ("version") VALUES (149);

ALTER TABLE "user" ADD "password_reset_token_created" TIMESTAMP WITH TIME ZONE;

INSERT INTO "_database_version" ("version") VALUES (150);

CREATE TABLE "account_user"
(
"account_id" INT NOT NULL,
"user_id" INT NOT NULL,
PRIMARY KEY ("account_id", "user_id")
)
;

INSERT INTO "account_user"
SELECT "account"."id", "user"."id"
FROM "user"
JOIN "account" on "account"."id" = "user"."account_id"
;

ALTER TABLE "user" DROP CONSTRAINT "user_account_id_fkey";
ALTER TABLE "user" DROP COLUMN "account_id";

INSERT INTO "_database_version" ("version") VALUES (151);

ALTER TABLE "user" ADD "selected_account_id" INT;

INSERT INTO "_database_version" ("version") VALUES (152);

UPDATE "user"
SET "selected_account_id" = "account_user"."account_id"
FROM "account_user"
WHERE "account_user"."user_id" = "user"."id"
;


ALTER TABLE "user" ALTER COLUMN "selected_account_id" SET NOT NULL;

INSERT INTO "_database_version" ("version") VALUES (153);

ALTER TABLE "user" ADD FOREIGN KEY ("selected_account_id") REFERENCES "account" ("id");

INSERT INTO "_database_version" ("version") VALUES (154);

INSERT INTO "user"
	("username", "password", "enabled", "email", "selected_account_id")
SELECT
	"email", '$2a$10$uYul/Qug4OCagnMIOzTBM.KT60fa1FzJB7/uDb66wikpnkvGwOFo.', true, "email", min("selected_account_id")
FROM
	"user"
WHERE
	"username" <> "email"
GROUP BY
	("email")
ON CONFLICT DO NOTHING
;

ALTER TABLE "account_user" ADD "administrator" BOOLEAN NOT NULL DEFAULT false;

INSERT INTO "account_user"
	("account_id", "user_id", "administrator")
SELECT
	"old"."selected_account_id", "new"."id", "user_role"."id" is not null
FROM
	"user" "old"
JOIN
	"user" "new" on "new"."username" = "old"."email"
LEFT JOIN
	"user_role" on "user_role"."user_id" = "old"."id" and "user_role"."role" = 'ROLE_ADMIN'
WHERE
	"old"."username" <> "old"."email"
ON CONFLICT DO NOTHING
;

DELETE FROM "user" WHERE "username" <> "email";

INSERT INTO "_database_version" ("version") VALUES (155);

ALTER TABLE "account_user" ADD "selected_ppa" INT;

INSERT INTO "_database_version" ("version") VALUES (156);

ALTER TABLE "account_user" DROP CONSTRAINT account_user_pkey;

ALTER TABLE "account_user" ADD "id" SERIAL NOT NULL;

ALTER TABLE "account_user" ADD PRIMARY KEY ("id");

ALTER TABLE "account_user" ADD UNIQUE ("account_id", "user_id");

INSERT INTO "_database_version" ("version") VALUES (157);

ALTER TABLE "account_user" RENAME TO "account_user_old";
ALTER SEQUENCE "account_user_id_seq" RENAME TO "account_user_old_id_seq";

CREATE TABLE "account_user"
(
    "id" SERIAL,
    "account_id" integer NOT NULL,
    "user_id" integer NOT NULL,
    "administrator" boolean NOT NULL DEFAULT false,
    "selected_ppa" integer,
    PRIMARY KEY ("id"),
    UNIQUE (account_id, user_id),
    FOREIGN KEY ("account_id") REFERENCES "account" ("id"),
	FOREIGN KEY ("user_id") REFERENCES "user" ("id")
)
;

DELETE FROM "account_user_old"
WHERE "user_id" not in (SELECT "id" FROM "user")
; 

DELETE FROM "account_user_old"
WHERE "account_id" not in (SELECT "id" FROM "account")
; 

INSERT INTO "account_user"
("id", "account_id", "user_id", "administrator")
SELECT
"id", "account_id", "user_id", "administrator"
FROM "account_user_old"
;

INSERT INTO "_database_version" ("version") VALUES (158);

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

ALTER SEQUENCE "account_user_id_seq" RESTART WITH 1000;
 
INSERT INTO "_database_version" ("version") VALUES (160);

ALTER TABLE "account_user" RENAME "selected_ppa" TO "selected_ppa_id";
 
INSERT INTO "_database_version" ("version") VALUES (161);

ALTER TABLE "account_user" ADD FOREIGN KEY ("selected_ppa_id") REFERENCES "ppa" ("id");
 
INSERT INTO "_database_version" ("version") VALUES (162);

ALTER TABLE "user" ALTER "selected_account_id" DROP NOT NULL;
 
INSERT INTO "_database_version" ("version") VALUES (163);

ALTER TABLE "account_user" ADD "owner" BOOLEAN NOT NULL DEFAULT false;
 
INSERT INTO "_database_version" ("version") VALUES (164);

ALTER TABLE "account_user" DROP CONSTRAINT "account_user_account_id_fkey";
ALTER TABLE "account_user" DROP CONSTRAINT "account_user_user_id_fkey";
ALTER TABLE "account_user" DROP CONSTRAINT "account_user_selected_ppa_id_fkey";
 
ALTER TABLE "account_user" ADD FOREIGN KEY ("account_id") REFERENCES "account" ("id") ON DELETE CASCADE;
ALTER TABLE "account_user" ADD FOREIGN KEY ("user_id") REFERENCES "user" ("id") ON DELETE CASCADE;
ALTER TABLE "account_user" ADD FOREIGN KEY ("selected_ppa_id") REFERENCES "ppa" ("id") ON DELETE SET NULL;

INSERT INTO "_database_version" ("version") VALUES (165);

ALTER TABLE "user" DROP CONSTRAINT "user_selected_account_id_fkey";
ALTER TABLE "user" ADD FOREIGN KEY ("selected_account_id") REFERENCES "account" ("id") ON DELETE SET NULL;

INSERT INTO "_database_version" ("version") VALUES (166);

ALTER TABLE "user" ADD "navigation_page" VARCHAR;

INSERT INTO "_database_version" ("version") VALUES (167);

UPDATE "user" SET "navigation_page" = '';
ALTER TABLE "user" ALTER "navigation_page" SET NOT NULL;
ALTER TABLE "user" ALTER "navigation_page" SET DEFAULT '';

INSERT INTO "_database_version" ("version") VALUES (168);

ALTER TABLE "account" ADD "demo" BOOLEAN NOT NULL DEFAULT false;

INSERT INTO "_database_version" ("version") VALUES (169);

ALTER TABLE "invitation" DROP CONSTRAINT "invitation_account_id_fkey";

ALTER TABLE "invitation" ADD FOREIGN KEY ("account_id") REFERENCES "account" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;

INSERT INTO "_database_version" ("version") VALUES (170);

ALTER TABLE "ppa" DROP CONSTRAINT "ppa_account_id_fkey";

ALTER TABLE "ppa" ADD FOREIGN KEY ("account_id") REFERENCES "account" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;

INSERT INTO "_database_version" ("version") VALUES (171);

ALTER TABLE "user_file" DROP CONSTRAINT "user_file_account_id_fkey";

ALTER TABLE "user_file" ADD FOREIGN KEY ("account_id") REFERENCES "account" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;

INSERT INTO "_database_version" ("version") VALUES (172);

ALTER TABLE "user" ADD "registration_token" VARCHAR;
ALTER TABLE "user" ADD "registration_token_created" TIMESTAMP WITH TIME ZONE;

INSERT INTO "_database_version" ("version") VALUES (173);

ALTER TABLE "ppa_sector" ADD "order" INTEGER;

INSERT INTO "_database_version" ("version") VALUES (174);

CREATE TABLE "ppa_sector_default_values"
(
    "order" INTEGER NOT NULL,
    "name" VARCHAR NOT NULL,
    "editable" BOOLEAN NOT NULL
)
;

INSERT INTO "_database_version" ("version") VALUES (175);

ALTER TABLE "ppa_sector_default_values" ADD UNIQUE ("order");

INSERT INTO "_database_version" ("version") VALUES (176);

DROP TABLE "ppa_sector_default_values";

CREATE TABLE "ppa_sector_default_values"
(
	"id" SERIAL,
    "order" INTEGER NOT NULL,
    "name" VARCHAR NOT NULL,
    "editable" BOOLEAN NOT NULL,
    PRIMARY KEY ("id"),
    UNIQUE ("order")
)
;

INSERT INTO "ppa_sector_default_values"
("order", "name", "editable")
VALUES
(1, 'Public', false),
(2, 'Private', false),
(3, 'Informal Private', false),
(4, 'CUSTOM SECTOR - ENTER TEXT HERE', true)
;

INSERT INTO "_database_version" ("version") VALUES (177);

ALTER TABLE "ppa_sector_default_values" RENAME TO "ppa_sector_default_value";

INSERT INTO "_database_version" ("version") VALUES (178);

ALTER TABLE "ppa_sector_default_value" RENAME "order" TO "position";

INSERT INTO "_database_version" ("version") VALUES (179);

ALTER TABLE "ppa_sector" RENAME "order" TO "position";

INSERT INTO "_database_version" ("version") VALUES (180);

DELETE FROM "metric_type" WHERE "id" in (14, 16);

INSERT INTO "_database_version" ("version") VALUES (181);

UPDATE "ppa_sector_default_value"
SET
"name" = 'Enter Custom Sector'
WHERE
"name" = 'CUSTOM SECTOR - ENTER TEXT HERE'
;


INSERT INTO "_database_version" ("version") VALUES (182);


