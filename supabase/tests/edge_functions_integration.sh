#!/usr/bin/env bash
set -euo pipefail

command -v jq >/dev/null
# shellcheck disable=SC2046
eval "$(supabase status -o env)"
: "${API_URL:?missing API_URL}"
: "${ANON_KEY:?missing ANON_KEY}"
: "${SERVICE_ROLE_KEY:?missing SERVICE_ROLE_KEY}"

cat > /tmp/loliexpress-edge-test.env <<'EOF'
BOOTSTRAP_ADMIN_SECRET=phase2-bootstrap-secret
SITE_URL=http://127.0.0.1:3000
INVITE_REDIRECT_URL=http://127.0.0.1:3000
EOF

supabase functions serve \
  --env-file /tmp/loliexpress-edge-test.env \
  --no-verify-jwt > /tmp/loliexpress-edge-functions.log 2>&1 &
functions_pid=$!
trap 'kill "$functions_pid" 2>/dev/null || true; cat /tmp/loliexpress-edge-functions.log' EXIT

for _ in $(seq 1 60); do
  if curl --silent --output /dev/null "${API_URL}/functions/v1/bootstrap_admin"; then
    break
  fi
  sleep 1
done

request() {
  local expected=$1
  local output=$2
  shift 2
  local actual
  actual=$(curl --silent --show-error --output "$output" --write-out '%{http_code}' "$@")
  if [[ "$actual" != "$expected" ]]; then
    echo "Expected HTTP $expected, received $actual" >&2
    cat "$output" >&2
    exit 1
  fi
}

request 401 /tmp/bootstrap-invalid.json \
  -X POST "${API_URL}/functions/v1/bootstrap_admin" \
  -H 'Content-Type: application/json' \
  -H 'x-bootstrap-secret: invalid' \
  --data '{"email":"bootstrap-admin@test.local"}'

request 201 /tmp/bootstrap.json \
  -X POST "${API_URL}/functions/v1/bootstrap_admin" \
  -H 'Content-Type: application/json' \
  -H 'x-bootstrap-secret: phase2-bootstrap-secret' \
  --data '{"email":"bootstrap-admin@test.local"}'
admin_id=$(jq -er '.id' /tmp/bootstrap.json)

request 410 /tmp/bootstrap-disabled.json \
  -X POST "${API_URL}/functions/v1/bootstrap_admin" \
  -H 'Content-Type: application/json' \
  -H 'x-bootstrap-secret: phase2-bootstrap-secret' \
  --data '{"email":"second-admin@test.local"}'

request 200 /tmp/admin-password.json \
  -X PUT "${API_URL}/auth/v1/admin/users/${admin_id}" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H 'Content-Type: application/json' \
  --data '{"password":"Admin-test-password-123","email_confirm":true}'
request 200 /tmp/admin-login.json \
  -X POST "${API_URL}/auth/v1/token?grant_type=password" \
  -H "apikey: ${ANON_KEY}" \
  -H 'Content-Type: application/json' \
  --data '{"email":"bootstrap-admin@test.local","password":"Admin-test-password-123"}'
admin_token=$(jq -er '.access_token' /tmp/admin-login.json)
request 200 /tmp/password-setup.json \
  -X POST "${API_URL}/rest/v1/rpc/complete_password_setup" \
  -H "apikey: ${ANON_KEY}" \
  -H "Authorization: Bearer ${admin_token}" \
  -H 'Content-Type: application/json' \
  --data '{}'

request 400 /tmp/create-password.json \
  -X POST "${API_URL}/functions/v1/create_user" \
  -H "Authorization: Bearer ${admin_token}" \
  -H 'Content-Type: application/json' \
  --data '{"email":"password@test.local","role":"sales_rep","password":"forbidden"}'
request 400 /tmp/create-role.json \
  -X POST "${API_URL}/functions/v1/create_user" \
  -H "Authorization: Bearer ${admin_token}" \
  -H 'Content-Type: application/json' \
  --data '{"email":"role@test.local","role":"admin"}'
request 201 /tmp/create-valid.json \
  -X POST "${API_URL}/functions/v1/create_user" \
  -H "Authorization: Bearer ${admin_token}" \
  -H 'Content-Type: application/json' \
  --data '{"email":"warehouse-invite@test.local","role":"warehouse_staff","full_name":"Warehouse Invite"}'
invited_id=$(jq -er '.id' /tmp/create-valid.json)

request 200 /tmp/invited-password.json \
  -X PUT "${API_URL}/auth/v1/admin/users/${invited_id}" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}" \
  -H 'Content-Type: application/json' \
  --data '{"password":"Warehouse-test-password-123","email_confirm":true}'
request 200 /tmp/invited-login.json \
  -X POST "${API_URL}/auth/v1/token?grant_type=password" \
  -H "apikey: ${ANON_KEY}" \
  -H 'Content-Type: application/json' \
  --data '{"email":"warehouse-invite@test.local","password":"Warehouse-test-password-123"}'
invited_token=$(jq -er '.access_token' /tmp/invited-login.json)
request 403 /tmp/create-non-admin.json \
  -X POST "${API_URL}/functions/v1/create_user" \
  -H "Authorization: Bearer ${invited_token}" \
  -H 'Content-Type: application/json' \
  --data '{"email":"denied@test.local","role":"sales_rep"}'

request 200 /tmp/create-audit.json \
  "${API_URL}/rest/v1/audit_logs?select=id&new_values-%3E%3Eoperation=eq.user_created_by_admin" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}"
[[ $(jq 'length' /tmp/create-audit.json) -eq 1 ]]
request 200 /tmp/bootstrap-events.json \
  "${API_URL}/rest/v1/security_events?select=id,success,metadata&event_type=eq.bootstrap_admin_attempt" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}"
[[ $(jq 'length' /tmp/bootstrap-events.json) -ge 3 ]]

# A duplicate invitation fails without creating a second profile/auth identity.
request 400 /tmp/create-duplicate.json \
  -X POST "${API_URL}/functions/v1/create_user" \
  -H "Authorization: Bearer ${admin_token}" \
  -H 'Content-Type: application/json' \
  --data '{"email":"warehouse-invite@test.local","role":"warehouse_staff"}'
request 200 /tmp/profile-count.json \
  "${API_URL}/rest/v1/user_profiles?select=id&email=eq.warehouse-invite@test.local" \
  -H "apikey: ${SERVICE_ROLE_KEY}" \
  -H "Authorization: Bearer ${SERVICE_ROLE_KEY}"
[[ $(jq 'length' /tmp/profile-count.json) -eq 1 ]]

echo 'Edge Function integration scenarios passed.'
