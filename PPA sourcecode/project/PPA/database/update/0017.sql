UPDATE "data_source" SET "column_names" = '';
ALTER TABLE "data_source" ALTER "column_names" SET DEFAULT ''; 
ALTER TABLE "data_source" ALTER "column_names" SET NOT NULL; 

INSERT INTO "_database_version" ("version") VALUES (17);

