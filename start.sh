#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Build Phase ---
echo "--- Building Frontend ---"
cd ./apps/frontend

# INSTALL BUN: Use npm (which is pre-installed) to install bun globally in the container.
npm install -g bun

# Now the 'bun' command will work.
bun install
bun run build

echo "--- Building Backend ---"
cd ../backend
go build -o ./main ./cmd/todo/main.go


# --- Start Phase ---
echo "--- Starting Server ---"
# The `exec` command replaces the shell process with your Go server.
exec ./main