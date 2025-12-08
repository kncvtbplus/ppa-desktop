-- Ensure all users have non-null email, name and navigation_page
UPDATE "user"
SET
    email = COALESCE(email, username),
    name  = COALESCE(name, username),
    navigation_page = COALESCE(navigation_page, '')
WHERE email IS NULL
   OR name IS NULL
   OR navigation_page IS NULL;


