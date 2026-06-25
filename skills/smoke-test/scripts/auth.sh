#!/usr/bin/env bash
#
# Browser-session auth guard — reuse a live authenticated browser session, else
# log in ONCE. Holds one persistent session so the app refreshes its own token
# within it, keeping interactive IdP/SSO logins to a minimum.
#
#   - Session alive & still on the app host    -> REUSED     (no login)
#   - Redirected to the IdP, login form shown   -> LOGGED_IN  (one interactive login)
#   - Redirected to the IdP, silent refresh      -> REUSED     (app refreshed its token)
#
# App-specific values come from the environment — the invoker supplies them; this
# script hard-codes nothing about any app:
#   SMOKE_BASE_URL      app root that triggers the auth redirect (required; or pass as arg 2)
#   SMOKE_USERNAME      login username (only needed if a login form appears)
#   SMOKE_PASSWORD      login password (   "   )
#   SMOKE_LOGIN_USER    username-field selector (default: #username   — stock Keycloak)
#   SMOKE_LOGIN_PASS    password-field selector (default: #password   — stock Keycloak)
#   SMOKE_LOGIN_SUBMIT  submit-button selector  (default: #kc-login   — stock Keycloak)
#
# Source your project's git-ignored env file first, e.g.:
#   set -a && . <your-project>/.claude/smoke/.env.local && set +a
#
# Usage: auth.sh [session] [base_url]
# Prints REUSED | LOGGED_IN | FAILED and exits 0/1. Never prints the password.

SESSION="${1:-smoke}"
BASE_URL="${2:-${SMOKE_BASE_URL:?SMOKE_BASE_URL not set (or pass the base URL as arg 2)}}"
USER_SEL="${SMOKE_LOGIN_USER:-#username}"
PASS_SEL="${SMOKE_LOGIN_PASS:-#password}"
SUBMIT_SEL="${SMOKE_LOGIN_SUBMIT:-#kc-login}"

url_host() { printf '%s' "$1" | sed -E 's#^[a-z]+://##; s#[:/].*$##'; }
APP_HOST="$(url_host "$BASE_URL")"

pc()   { playwright-cli -s="$SESSION" "$@"; }
host() { pc --raw eval '() => location.hostname' 2>/dev/null | tr -d '"' | tail -1; }
path() { pc --raw eval '() => location.pathname' 2>/dev/null | tr -d '"' | tail -1; }
has_login_form() { pc --raw eval '() => !!document.querySelector("input[type=password]")' 2>/dev/null | tr -d '"' | tail -1; }

# On the app host but parked on an OIDC callback (…/login/callback) = a failed
# silent re-auth (stale state/nonce), NOT authenticated — the callback URL is on
# the app host, so a hostname-only check would read this stranded state as success.
not_callback() { case "$(path)" in *callback*) return 1 ;; *) return 0 ;; esac; }

# wait until the hostname stabilises (an SPA redirect is client-side, ~2-3s)
settle() {
  local prev="" cur=""
  for _ in 1 2 3 4 5 6 7 8; do
    sleep 1; cur="$(host)"
    [ -n "$cur" ] && [ "$cur" = "$prev" ] && { echo "$cur"; return; }
    prev="$cur"
  done
  echo "$cur"
}

# one-shot self-recovery from a stranded callback (stale state/nonce): clear THIS
# origin's web storage (app-agnostic — current origin only), then ONE clean
# re-navigation = a single fresh OIDC flow. Echoes the settled hostname.
recover() {
  pc eval '() => { localStorage.clear(); sessionStorage.clear(); }' >/dev/null 2>&1
  pc goto "$BASE_URL" >/dev/null 2>&1   # ONE clean flow — never root-then-route
  settle
}

# 1. ensure the session exists; land on the app root
if playwright-cli list 2>/dev/null | grep -q -- "- ${SESSION}:"; then
  pc goto "$BASE_URL" >/dev/null 2>&1
else
  pc open "$BASE_URL" >/dev/null 2>&1
fi
h="$(settle)"

# 2. on the app host AND not stranded on a callback -> token valid -> reuse
if [ "$h" = "$APP_HOST" ] && not_callback; then
  echo "REUSED  session=$SESSION host=$h"; exit 0
fi

# 2b. on the app host but parked on …/callback (failed silent re-auth) -> recover once
if [ "$h" = "$APP_HOST" ]; then
  h="$(recover)"
  [ "$h" = "$APP_HOST" ] && not_callback && { echo "REUSED  session=$SESSION host=$h (recovered)"; exit 0; }
  # recovery launched a fresh OIDC flow (or is still stranded) -> fall through to login
fi

# 3. redirected off the app host (to whatever IdP) -> form, or silent refresh
if [ "$(has_login_form)" = "true" ]; then
  : "${SMOKE_USERNAME:?SMOKE_USERNAME not set — source your env file}"
  : "${SMOKE_PASSWORD:?SMOKE_PASSWORD not set — source your env file}"
  pc fill "$USER_SEL" "$SMOKE_USERNAME" >/dev/null 2>&1
  pc fill "$PASS_SEL" "$SMOKE_PASSWORD" >/dev/null 2>&1
  pc click "$SUBMIT_SEL" >/dev/null 2>&1
  h="$(settle)"
  [ "$h" = "$APP_HOST" ] && not_callback && { echo "LOGGED_IN  session=$SESSION host=$h"; exit 0; }
else
  h="$(settle)"   # silent refresh in flight — wait it out
  [ "$h" = "$APP_HOST" ] && not_callback && { echo "REUSED  session=$SESSION host=$h (silent refresh)"; exit 0; }
fi

echo "FAILED  session=$SESSION host=${h:-unknown}"; exit 1
