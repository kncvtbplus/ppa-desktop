ALTER TABLE "user_metric_data_source" DROP "available_column_values";

ALTER TABLE "data_source" ADD "health_sector_column_values" TEXT;
ALTER TABLE "data_source" ADD "facility_type_column_values" TEXT;

INSERT INTO "_database_version" ("version") VALUES (39);

