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

