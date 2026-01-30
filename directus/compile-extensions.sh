#!/bin/sh
set -eu

echo "=================================================="
echo " Directus Extensions Build Script"
echo "=================================================="
echo "Shell            : $(readlink /proc/$$/exe || echo sh)"
echo "Node version     : $(node -v || echo 'node NOT FOUND')"
echo "NPM version      : $(npm -v || echo 'npm NOT FOUND')"
echo "Working dir      : $(pwd)"
echo "User             : $(whoami)"
echo "=================================================="

EXT_DIR="${EXT_DIR:-/directus/extensions}"

echo "EXT_DIR resolved to: $EXT_DIR"

if [ ! -d "$EXT_DIR" ]; then
  echo "!!! EXTENSIONS DIRECTORY DOES NOT EXIST"
  echo "!!! Nothing to build"
  exit 0
fi

echo "=> Extensions directory exists"
echo "=> Listing contents:"
ls -la "$EXT_DIR"

echo "=================================================="
echo " Starting extensions build loop"
echo "=================================================="

for ext in "$EXT_DIR"/*; do
  echo "--------------------------------------------------"
  echo "Inspecting path: $ext"

  if [ ! -d "$ext" ]; then
    echo "Skipping (not a directory)"
    continue
  fi

  if [ ! -f "$ext/package.json" ]; then
    echo "Skipping (package.json NOT found)"
    continue
  fi

  EXT_NAME="$(basename "$ext")"
  echo ">> FOUND EXTENSION: $EXT_NAME"
  echo ">> Full path: $ext"

  (
    set -eu
    echo "--------------------------------------------------"
    echo "Entering directory: $ext"
    cd "$ext"

    echo "PWD is now: $(pwd)"
    echo "Listing extension files:"
    ls -la

    echo "--------------------------------------------------"
    echo "Checking npm configuration"
    npm config get fund || true
    npm config get audit || true

    echo "Disabling npm fund + audit"
    npm config set fund false || true
    npm config set audit false || true

    echo "--------------------------------------------------"
    echo "Checking existing node_modules"
    if [ -d node_modules ]; then
      echo "node_modules EXISTS"
      echo "node_modules size:"
      du -sh node_modules || true
    else
      echo "node_modules DOES NOT EXIST"
    fi

    echo "--------------------------------------------------"
    if [ -f package-lock.json ]; then
      echo "package-lock.json FOUND"
      echo "Running: npm ci --include=dev"
      npm ci --include=dev
    else
      echo "package-lock.json NOT FOUND"
      echo "Running: npm install --include=dev"
      npm install --include=dev
    fi

    echo "--------------------------------------------------"
    echo "NPM install completed"
    echo "Installed node_modules:"
    ls -la node_modules | head -n 30 || true

    echo "--------------------------------------------------"
    echo "Running build command: npm run build"
    npm run build

    echo "--------------------------------------------------"
    echo "Build finished"
    echo "Listing directory after build:"
    ls -la

    echo "--------------------------------------------------"
    echo "Checking dist/ directory"
    if [ ! -d dist ]; then
      echo "!!! ERROR: dist/ directory NOT FOUND"
      echo "!!! Build failed or output path is incorrect"
      exit 1
    fi

    echo "dist/ directory FOUND"
    echo "dist/ contents:"
    ls -la dist

    echo "--------------------------------------------------"
    echo "Extension $EXT_NAME build SUCCESS"
    echo "--------------------------------------------------"
  )

done

echo "=================================================="
echo " ALL EXTENSIONS PROCESSED"
echo "=================================================="
echo "Build script finished successfully"
