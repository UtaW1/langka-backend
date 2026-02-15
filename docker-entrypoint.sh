#!/bin/sh
set -e

echo "Waiting for database..."

while ! nc -z "$DB_HOST" 5432; do
  sleep 1
done

echo "Database is up!"

echo "Running migrations..."
bin/langka_order_management eval "LangkaOrderManagement.Release.migrate"

echo "Starting Phoenix server..."
exec bin/langka_order_management start
