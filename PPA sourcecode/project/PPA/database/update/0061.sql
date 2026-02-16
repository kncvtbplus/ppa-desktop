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

