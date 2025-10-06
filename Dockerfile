# --- Stage 1: The Builder ---
# Use the official Go image that matches your go.mod version.
# This guarantees you have the correct Go toolchain.
FROM golang:1.25.1-bookworm AS builder

# Set the working directory
WORKDIR /app

# Install Node.js, npm, and Bun
# We need curl and gnupg to add the NodeSource repository for a modern Node.js version.
RUN apt-get update && apt-get install -y curl gnupg
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list
RUN apt-get update && apt-get install -y nodejs
RUN npm install -g bun

# Copy over all your project files
COPY . .

# --- Build Frontend ---
# This command is now guaranteed to work because we installed Bun correctly.
RUN cd ./apps/frontend && bun install && bun run build

# --- Build Backend ---
# This command is now guaranteed to work because we are in the correct Go version environment.
RUN cd ./apps/backend && go build -o ./main ./cmd/todo/main.go


# --- Stage 2: The Final Image ---
# Use a minimal, secure base image for the final container
FROM gcr.io/distroless/static-debian11

# Set the working directory
WORKDIR /app

# Copy the compiled Go binary from the 'builder' stage
COPY --from=builder /app/apps/backend/main .

# Copy the built frontend assets from the 'builder' stage
COPY --from=builder /app/apps/frontend/dist ./apps/frontend/dist

# The command to run when the container starts
CMD ["/app/main"]