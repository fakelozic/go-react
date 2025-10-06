# --- Stage 1: The Builder ---
# Use an official Node.js image which has all the tools we need (npm, curl, etc.)
FROM node:22-slim AS builder

# Set the working directory for the entire build process
WORKDIR /app

# Install Go and Bun
RUN npm install -g bun
RUN apt-get update && apt-get install -y golang-go

# Copy over all your project files
COPY . .

# --- Build Frontend ---
RUN cd ./apps/frontend && bun install && bun run build

# --- Build Backend ---
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

# Expose the port your app will listen on.
# This is good practice but Railway handles port mapping automatically.
EXPOSE 8080

# The command to run when the container starts
CMD ["/app/main"]