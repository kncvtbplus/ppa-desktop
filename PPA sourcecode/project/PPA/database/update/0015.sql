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

