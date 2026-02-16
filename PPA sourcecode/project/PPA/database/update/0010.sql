CREATE TABLE "user_metric"
(
	"id" SERIAL NOT NULL,
	"user_id" INT NOT NULL,
	"metric_id" INT NOT NULL,
	"data_point_name" VARCHAR(1000) NOT NULL DEFAULT '',
	PRIMARY KEY ("id"),
	UNIQUE ("user_id", "metric_id"),
	FOREIGN KEY ("user_id") REFERENCES "user" ("id") ON DELETE CASCADE,
	FOREIGN KEY ("metric_id") REFERENCES "metric" ("id") ON DELETE CASCADE
)
;

INSERT INTO "_database_version" ("version") VALUES (10);

