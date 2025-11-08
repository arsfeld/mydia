FROM elixir:1.16-alpine AS builder

# Install build dependencies
RUN apk add --no-cache build-base git

WORKDIR /app

# Install hex and rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy mix files
COPY mix.exs mix.lock ./
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy application files
COPY config ./config
COPY lib ./lib

# Compile the application
RUN MIX_ENV=prod mix compile

# Build release
RUN MIX_ENV=prod mix release

# Start a new stage for the final image
FROM alpine:3.19

# Install runtime dependencies
RUN apk add --no-cache libstdc++ openssl ncurses-libs

WORKDIR /app

# Copy the release from the builder stage
COPY --from=builder /app/_build/prod/rel/metadata_relay ./

# Set environment
ENV MIX_ENV=prod
ENV PORT=4001

# Expose the port
EXPOSE 4001

# Run the application
CMD ["./bin/metadata_relay", "start"]
