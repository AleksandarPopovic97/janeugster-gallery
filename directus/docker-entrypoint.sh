#!/bin/sh
set -e

# Control flag (from .env)
BUILD_EXTENSIONS="${BUILD_EXTENSIONS:-false}"
EXT_DIR="/directus/extensions"

echo "BUILD_EXTENSIONS=$BUILD_EXTENSIONS"
echo "EXT_DIR=$EXT_DIR"

# Normalize truthy values
case "$(echo "$BUILD_EXTENSIONS" | tr '[:upper:]' '[:lower:]')" in
  1|true|yes|y|on)
    DO_BUILD=1
    echo "=> Extensions build ENABLED"
    ;;
  *)
    DO_BUILD=0
    echo "=> Extensions build DISABLED (skipping)"
    ;;
esac

if [ "$DO_BUILD" -eq 1 ]; then
  echo "=> Installing + building Directus extensions in: $EXT_DIR"

  if [ -d "$EXT_DIR" ]; then
    for ext in "$EXT_DIR"/*; do
      [ -d "$ext" ] || continue
      [ -f "$ext/package.json" ] || continue

      EXT_NAME="$(basename "$ext")"
      echo "-> Extension: $EXT_NAME"

      (
        cd "$ext"

        # Clean, predictable installs
        npm config set fund false >/dev/null 2>&1 || true
        npm config set audit false >/dev/null 2>&1 || true

        # Install deps
        if [ -d node_modules ]; then
          echo "   deps already installed, skipping"
        else
          if [ -f package-lock.json ]; then
            npm ci --include=dev || npm install --include=dev
          else
            npm install --include=dev
          fi
        fi

        # Build
        npm run build

        echo "   -> Copying runtime files"

        # Ensure dist exists
        if [ ! -d dist ]; then
          echo "!!! dist/ not found for $EXT_NAME"
          continue
        fi

        echo "   -> $EXT_NAME ready"
      )
    done
  else
    echo "=> No extensions directory found, skipping build"
  fi
fi

echo "=> Running Directus core DB migrations..."
npx directus database migrate:latest

# SCHEMA_FILE="/directus/schema/schema.json"
# if [ -f "$SCHEMA_FILE" ]; then
#   echo "=> Applying Directus schema from $SCHEMA_FILE..."
#   npx directus schema apply "$SCHEMA_FILE" --yes || echo "!!! Schema apply failed, continuing"
# fi

echo "=> Starting Directus..."
exec npx directus start
