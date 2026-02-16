TRUNCATE TABLE "invitation";

ALTER TABLE "invitation" DROP "account";
ALTER TABLE "invitation" ADD "account_id" INT NOT NULL;

ALTER TABLE "invitation" ADD FOREIGN KEY ("account_id") REFERENCES "account" ("id");

INSERT INTO "_database_version" ("version") VALUES (148);

