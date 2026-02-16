UPDATE "metric_type" SET "name" = replace("name", 'Availability ', '') where "name" LIKE '%Availability%';

INSERT INTO "_database_version" ("version") VALUES (123);

