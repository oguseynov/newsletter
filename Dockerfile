ARG RUST_VERSION=1.88.0

FROM lukemathwalker/cargo-chef:latest-rust-${RUST_VERSION} AS chef
WORKDIR /app
RUN apt update && apt install lld clang -y

FROM chef AS planner
COPY Cargo.toml Cargo.lock ./
COPY src ./src
# This is needed for `sqlx::query!` to work in offline mode.
COPY ./.sqlx ./.sqlx
# Compute a lock-like file for our project
RUN cargo chef prepare --recipe-path recipe.json

FROM chef AS builder
COPY --from=planner /app/recipe.json recipe.json
# Build our project dependencies, not our application!
RUN cargo chef cook --release --recipe-path recipe.json
# Up to this point, if our dependency tree stays the same,
# all layers should be cached.
COPY . .
ENV SQLX_OFFLINE=true
# Build our project
RUN cargo build --release --bin newsletter

FROM rust:${RUST_VERSION}-slim-bookworm AS runtime
WORKDIR /app
RUN apt-get update -y \
  # Clean up
  && apt-get autoremove -y \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/*
COPY --from=builder /app/target/release/newsletter newsletter
COPY configuration configuration
RUN useradd --system --uid 1001 appuser
USER appuser
ENV APP_ENVIRONMENT=production
EXPOSE 8000
ENTRYPOINT ["./newsletter"]
