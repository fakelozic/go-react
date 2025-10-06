#!/bin/bash

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Build Phase ---
echo "--- Building Frontend ---"
cd ./apps/frontend

# INSTALL BUN FROM SCRATCH: This uses curl (which is available) to download
# the official Bun installer and runs it. It has no other dependencies.
curl -fsSL https://bun.sh/install | bash

# IMPORTANT: The line above installs bun to ~/.bun/bin
# We need to add this directory to our PATH so we can use the 'bun' command.
export PATH="$HOME/.bun/bin:$PATH"

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