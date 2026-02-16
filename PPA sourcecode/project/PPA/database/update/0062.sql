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

