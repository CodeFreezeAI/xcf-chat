#!/bin/bash

# WebAuthn Database Cleanup Script
# Use this script when you encounter CoreData migration errors

echo "🧹 Cleaning up WebAuthn databases..."

# Default locations for WebAuthn databases
DEFAULT_DB_PATH="$HOME/webauthn/credentials.sqlite"
BACKUP_DIR="$HOME/webauthn/backups"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Check for existing database files
if [ -f "$DEFAULT_DB_PATH" ]; then
    echo "📦 Found existing database at: $DEFAULT_DB_PATH"
    
    # Create backup with timestamp
    TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
    BACKUP_PATH="$BACKUP_DIR/credentials_backup_$TIMESTAMP.sqlite"
    
    echo "💾 Creating backup: $BACKUP_PATH"
    cp "$DEFAULT_DB_PATH" "$BACKUP_PATH"
    
    # Remove the original database files
    echo "🗑️  Removing database files..."
    rm -f "$DEFAULT_DB_PATH"
    rm -f "${DEFAULT_DB_PATH}-shm"
    rm -f "${DEFAULT_DB_PATH}-wal"
    
    echo "✅ Database cleanup completed!"
    echo "📂 Backup saved to: $BACKUP_PATH"
else
    echo "ℹ️  No existing database found at: $DEFAULT_DB_PATH"
fi

# Also clean up JSON credential files if they exist
JSON_FILES=("webauthn_credentials_fido2.json" "webauthn_credentials_u2f.json")

for file in "${JSON_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "📦 Found JSON credential file: $file"
        BACKUP_JSON="$BACKUP_DIR/${file%.*}_backup_$TIMESTAMP.json"
        cp "$file" "$BACKUP_JSON"
        echo "💾 JSON backup saved to: $BACKUP_JSON"
        rm -f "$file"
        echo "🗑️  Removed: $file"
    fi
done

echo ""
echo "🎉 Cleanup completed! You can now restart your WebAuthn server."
echo "📁 All backups are stored in: $BACKUP_DIR"
echo ""
echo "💡 To restore from backup if needed:"
echo "   cp $BACKUP_DIR/credentials_backup_$TIMESTAMP.sqlite $DEFAULT_DB_PATH" 