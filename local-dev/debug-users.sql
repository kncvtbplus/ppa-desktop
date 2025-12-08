SELECT id, username, email, name, selected_account_id, navigation_page
FROM "user"
ORDER BY id;

SELECT id, name, demo
FROM "account"
ORDER BY id;

SELECT id, account_id, user_id, administrator, selected_ppa_id, owner
FROM "account_user"
ORDER BY id
LIMIT 20;


