ALTER TABLE "invitation" DROP CONSTRAINT "invitation_account_id_fkey";

ALTER TABLE "invitation" ADD FOREIGN KEY ("account_id") REFERENCES "account" ("id") ON UPDATE NO ACTION ON DELETE CASCADE;

INSERT INTO "_database_version" ("version") VALUES (170);

