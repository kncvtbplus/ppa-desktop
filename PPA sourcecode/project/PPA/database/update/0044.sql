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

