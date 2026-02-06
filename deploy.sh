#!/bin/bash
#
# deploy.sh - Build and run xcf-chat server
#
# Usage:
#   ./deploy.sh                        # localhost development (port 8080)
#   ./deploy.sh -c                     # clean database + start fresh
#   ./deploy.sh 8081                   # localhost on custom port
#   ./deploy.sh 8080 chat.xcf.ai      # production with domain
#   ./deploy.sh -c 8080 chat.xcf.ai   # clean db + production
#
# Flags:
#   -c          Clean WebAuthn database (fresh start)
#   -r          Release build
#
# Environment:
#   BUILD_MODE=release ./deploy.sh     # alternate way to do release build
#

set -e

CLEAN_DB=false
BUILD_MODE="${BUILD_MODE:-debug}"

# Parse flags
while getopts "cr" opt; do
    case $opt in
        c) CLEAN_DB=true ;;
        r) BUILD_MODE="release" ;;
        *) ;;
    esac
done
shift $((OPTIND - 1))

PORT="${1:-8080}"
RP_ID="${2:-localhost}"
ADMIN="${3:-XCF Admin}"
DB_DIR="$HOME/webauthn"

echo ""
echo "  xcf-chat deploy"
echo "  =========================="
echo "  Port:    $PORT"
echo "  RP ID:   $RP_ID"
echo "  Admin:   $ADMIN"
echo "  Build:   $BUILD_MODE"
echo "  Clean:   $CLEAN_DB"
echo ""

# Kill any existing process on the port
EXISTING_PID=$(lsof -ti:"$PORT" 2>/dev/null || true)
if [ -n "$EXISTING_PID" ]; then
    echo "  Stopping existing process on port $PORT (PID: $EXISTING_PID)..."
    kill -9 $EXISTING_PID 2>/dev/null || true
    sleep 1
fi

# Clean database if requested
if [ "$CLEAN_DB" = true ]; then
    echo "  Cleaning WebAuthn database..."
    rm -f "$DB_DIR"/credentials.sqlite*
    rm -f "$DB_DIR"/credentials.sqlite.migration_v2.flag
    echo "  Database cleaned."
    echo ""
fi

# Build
echo "  Building ($BUILD_MODE)..."
if [ "$BUILD_MODE" = "release" ]; then
    swift build -c release 2>&1 | tail -5
    BINARY=".build/release/ChatServer"
else
    swift build 2>&1 | tail -5
    BINARY=".build/debug/ChatServer"
fi

if [ ! -f "$BINARY" ]; then
    echo "  Build failed - binary not found"
    exit 1
fi

echo "  Build complete."
echo ""

# Run
echo "  Starting server..."
echo "  $BINARY $PORT --rp-id $RP_ID --admin \"$ADMIN\""
echo ""

if [ "$RP_ID" = "localhost" ]; then
    echo "  Open: http://localhost:$PORT"
else
    echo "  Open: https://$RP_ID"
fi
echo ""

exec "$BINARY" "$PORT" --rp-id "$RP_ID" --admin "$ADMIN"
