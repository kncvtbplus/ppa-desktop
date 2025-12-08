-- Create or update account and user for Job van Rest
CREATE EXTENSION IF NOT EXISTS pgcrypto;

DO $$
DECLARE
    v_account_id INT;
    v_user_id    INT;
BEGIN
    -- Ensure account exists
    INSERT INTO "account" ("name", "demo")
    VALUES ('Job van Rest', FALSE)
    ON CONFLICT ("name") DO UPDATE
        SET demo = EXCLUDED.demo
    RETURNING id INTO v_account_id;

    -- If account already existed, fetch its id
    IF v_account_id IS NULL THEN
        SELECT id INTO v_account_id
        FROM "account"
        WHERE name = 'Job van Rest';
    END IF;

    -- Ensure user exists (username = email)
    INSERT INTO "user" ("username", "password", "enabled", "email", "name", "selected_account_id", "navigation_page")
    VALUES (
        'job.vanrest@kncvtbc.org',
        crypt('Super2051@', gen_salt('bf')),
        TRUE,
        'job.vanrest@kncvtbc.org',
        'Job van Rest',
        v_account_id,
        ''
    )
    ON CONFLICT ("username") DO UPDATE
        SET
            "password"            = EXCLUDED."password",
            "enabled"             = EXCLUDED."enabled",
            "email"               = EXCLUDED."email",
            "name"                = EXCLUDED."name",
            "selected_account_id" = EXCLUDED."selected_account_id"
    RETURNING id INTO v_user_id;

    -- If user already existed, fetch its id
    IF v_user_id IS NULL THEN
        SELECT id INTO v_user_id
        FROM "user"
        WHERE username = 'job.vanrest@kncvtbc.org';
    END IF;

    -- Ensure account_user association exists, with administrator privileges
    INSERT INTO "account_user" ("account_id", "user_id", "administrator", "owner")
    VALUES (v_account_id, v_user_id, TRUE, TRUE)
    ON CONFLICT ("account_id", "user_id") DO UPDATE
        SET
            administrator = TRUE,
            owner         = TRUE;

    -- Ensure roles ROLE_USER and ROLE_ADMIN exist for this user
    INSERT INTO "user_role" ("user_id", "role")
    VALUES
        (v_user_id, 'ROLE_USER'),
        (v_user_id, 'ROLE_ADMIN')
    ON CONFLICT DO NOTHING;
END
$$;


