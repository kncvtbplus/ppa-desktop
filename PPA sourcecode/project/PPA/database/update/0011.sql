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

