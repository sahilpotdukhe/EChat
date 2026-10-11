#!/usr/bin/env bash
# Deploys EChat's Firebase security rules (works on the free Spark plan).
# Push notifications are sent by server/ on Vercel, which deploys itself from
# git (see server/vercel.json), not by this script.
#
#   scripts/deploy_firebase.sh                 # tests, then database rules
#   scripts/deploy_firebase.sh --with-storage  # also storage rules (only once the new
#                                              # app build is out: older builds upload to
#                                              # paths these rules block)
#   scripts/deploy_firebase.sh --skip-tests    # deploy without running the tests

set -euo pipefail

PROJECT_ID="echat-888ef"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WITH_STORAGE=false
SKIP_TESTS=false

for arg in "$@"; do
  case "$arg" in
    --with-storage) WITH_STORAGE=true ;;
    --skip-tests) SKIP_TESTS=true ;;
    *) echo "Unknown option: $arg" >&2; exit 2 ;;
  esac
done

step() { printf '\n\033[1m==> %s\033[0m\n' "$1"; }
fail() { printf '\n\033[31mStopped:\033[0m %s\n' "$1" >&2; exit 1; }

cd "$ROOT"

step "Checking tools"
command -v firebase >/dev/null || fail "Firebase CLI not found. Install it with: npm install -g firebase-tools"
command -v node >/dev/null || fail "Node.js not found. Install Node 22."

# The emulators need Java 21+. Fall back to the copy bundled with Android Studio.
java_major() { "$1" -version 2>&1 | awk -F'"' '/version/ {split($2, v, "."); print v[1]}'; }
if ! $SKIP_TESTS; then
  if ! command -v java >/dev/null || [ "$(java_major java)" -lt 21 ]; then
    STUDIO_JAVA="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
    if [ -x "$STUDIO_JAVA/bin/java" ] && [ "$(java_major "$STUDIO_JAVA/bin/java")" -ge 21 ]; then
      export JAVA_HOME="$STUDIO_JAVA" PATH="$STUDIO_JAVA/bin:$PATH"
    else
      fail "The rule tests need Java 21 or newer. Install it (brew install openjdk@21) or rerun with --skip-tests."
    fi
  fi
fi

step "Checking access to $PROJECT_ID"
# In CI the service-account key (GOOGLE_APPLICATION_CREDENTIALS) is used instead.
if [ -z "${GOOGLE_APPLICATION_CREDENTIALS:-}" ]; then
  if ! firebase projects:list --json 2>/dev/null | grep -q "\"projectId\": \"$PROJECT_ID\""; then
    fail "The Firebase account logged in here can't see $PROJECT_ID.
Log in with the Google account that owns the project, then rerun:
    firebase login:add
    firebase login:use <that-email>"
  fi
fi
echo "OK"

if ! $SKIP_TESTS; then
  step "Running security rule tests (local emulator)"
  (cd firebase-tests && npm ci --silent && npm test --silent) || fail "Rule tests failed, nothing was deployed."
  step "Running notification server tests (local emulator)"
  (cd server && npm ci --silent && npm test --silent) || fail "Server tests failed, nothing was deployed."
fi

TARGETS="firestore:rules"
$WITH_STORAGE && TARGETS="$TARGETS,storage"

step "Deploying $TARGETS"
if ! firebase deploy --only "$TARGETS" --project "$PROJECT_ID"; then
  fail "Deploy failed, see the error above."
fi

step "Done"
echo "Deployed: $TARGETS"
if ! $WITH_STORAGE; then
  echo "Storage rules were NOT deployed. Once the new app build is released, run:"
  echo "    scripts/deploy_firebase.sh --with-storage"
fi
