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

