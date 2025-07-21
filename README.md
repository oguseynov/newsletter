## What
Code in this repo is a result of following [Zero To Production In Rust](https://github.com/LukeMathWalker/zero-to-production)
book that builds newsletter app, with my certain additions to the code of it like:
1) incrementing on what is already provided in book,
2) doing certain things differently.

## Why
1. Showcasing my ways working with code and infra, and leaving place for questions like 'Why can be improved here?'
2. Place for me to explore new technologies, for example Rust or [Fly](https://fly.io)

## Already added
1. [Otel layer](src/telemetry.rs) for sending traces to [ClickStack](https://clickhouse.com/use-cases/observability) (example of stack will be added later).
2. Deploy to [Fly](https://fly.io), please [fly.toml](fly.toml) file.
