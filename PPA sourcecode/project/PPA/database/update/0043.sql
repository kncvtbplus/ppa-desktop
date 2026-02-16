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

