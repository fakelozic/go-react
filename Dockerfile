# --- Stage 1: The Go Builder ---
# Use the official Go image. This guarantees the correct Go version.
FROM golang:1.25.1-bookworm AS builder

# Set the working directory inside the container
WORKDIR /app

# Copy the go.mod and go.sum files to download dependencies efficiently
COPY apps/backend/go.mod apps/backend/go.sum ./
RUN go mod download

# Copy the rest of your backend source code
COPY apps/backend/ .

# Build a fully static Go binary. This is the key.
# It will have zero dependencies in the final image.
RUN CGO_ENABLED=0 go build -o /main ./cmd/todo/main.go


# --- Stage 2: The Final Image ---
# Use a minimal, secure "distroless" base image
FROM gcr.io/distroless/static-debian11

# Set the final working directory
WORKDIR /app

# Copy the compiled Go binary from the 'builder' stage
COPY --from=builder /main .

# Copy your pre-built frontend 'dist' folder
COPY apps/frontend/dist ./apps/frontend/dist

# Expose the port your app will listen on
EXPOSE 8080

# The command to run when the container starts
CMD ["/app/main"]