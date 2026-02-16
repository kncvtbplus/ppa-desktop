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

