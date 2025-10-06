# --- Stage 1: The Builder ---
# Use the official Go image that matches your go.mod version.
FROM golang:1.25.1-bookworm AS builder

# Set the working directory
WORKDIR /app

# Install Node.js, npm, and Bun
RUN apt-get update && apt-get install -y curl gnupg
RUN curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
RUN echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_22.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.gpg
RUN apt-get update && apt-get install -y nodejs
RUN npm install -g bun

# Copy over all your project files
COPY . .

# --- Build Frontend ---
RUN cd ./apps/frontend && bun install && bun run build

# --- Build Backend ---
# THIS IS THE ONLY LINE THAT HAS CHANGED.
# CGO_ENABLED=0 tells the Go compiler to create a fully static executable.
RUN cd ./apps/backend && CGO_ENABLED=0 go build -o ./main ./cmd/todo/main.go


# --- Stage 2: The Final Image ---
# This stage is now correct because our binary is static.
FROM gcr.io/distroless/static-debian11

# Set the working directory
WORKDIR /app

# Copy the compiled Go binary from the 'builder' stage
COPY --from=builder /app/apps/backend/main .

# Copy the built frontend assets from the 'builder' stage
COPY --from=builder /app/apps/frontend/dist ./apps/frontend/dist

# The command to run when the container starts
CMD ["/app/main"]