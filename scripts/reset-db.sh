#!/bin/bash

echo "🗑️  Resetting database..."

# Remove the database file
rm -f prisma/dev.db

# Recreate the database with schema
echo "📊 Recreating database schema..."
bunx prisma db push

# Seed with fresh data
echo "🌱 Seeding database..."
bun seed

echo "✅ Database reset complete!"
echo ""
echo "Available test users:"
echo "- admin@test.com (ADMIN role)"
echo "- user@test.com (USER role)"