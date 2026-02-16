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

