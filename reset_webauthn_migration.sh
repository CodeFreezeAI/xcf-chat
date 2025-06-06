#!/bin/bash

# WebAuthn Migration Reset Script
# Use this script to reset migration flags and clean up test data

echo "🔄 WebAuthn Migration Reset Script"
echo "=================================="

# Remove migration flag files
echo "🧹 Removing migration flags..."
rm -f webauthn_migration_v2.flag
rm -f webauthn_swiftdata_migration_v2.flag
rm -f *.migration_v2.flag

# Show JSON credential files that exist
echo ""
echo "📋 Current JSON credential files:"
ls -la webauthn_credentials*.json 2>/dev/null || echo "   No JSON credential files found"

# Show backup files
echo ""
echo "📦 Current backup files:"
ls -la *.migrated_backup_* 2>/dev/null || echo "   No backup files found"

echo ""
echo "✅ Migration flags reset!"
echo "💡 Next server restart will re-run field migration (one time only)"
echo ""
echo "🗑️  To also remove JSON credential files (CAREFUL!):"
echo "   rm -f webauthn_credentials*.json"
echo ""
echo "📦 To restore from backup:"
echo "   cp [backup_file] webauthn_credentials_fido2.json" 