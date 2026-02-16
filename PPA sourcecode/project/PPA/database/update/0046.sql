ALTER TABLE "output" ADD "created" TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

INSERT INTO "_database_version" ("version") VALUES (46);

