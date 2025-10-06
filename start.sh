#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Build Phase ---
echo "--- Building Frontend ---"
cd ./apps/frontend
curl -fsSL https://bun.sh/install | bash
bun install
bun run build

echo "--- Building Backend ---"
cd ../backend
go build -o ./main ./cmd/todo/main.go


# --- Start Phase ---
echo "--- Starting Server ---"
# The `exec` command replaces the shell process with your Go server,
# which is a best practice for containerized environments.
exec ./main