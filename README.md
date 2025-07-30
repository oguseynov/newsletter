## What
Code in this repo is a result of following [Zero To Production In Rust](https://github.com/LukeMathWalker/zero-to-production)
book that builds newsletter app, with my certain additions to the code of it like:
1) incrementing on what is already provided in book,
2) doing certain things differently.

## Why
1. Showcasing my ways working with code and infra, and leaving place for questions like 'What can be improved here?'
2. Place for me to explore new technologies, for example Rust or [Fly](https://fly.io)

## Already added
1. [Otel layer](src/telemetry.rs) for sending traces to [ClickStack](https://clickhouse.com/use-cases/observability).
2. Deploy to [Fly](https://fly.io), please [fly.toml](fly.toml) file.
3. Sending traces to [ClickStack](https://clickhouse.com/use-cases/observability) and [docker-compose](docker-compose.yml) 
file to see it all work together.

## How to explore

### Local run of newsletter service with db through cargo run
```shell
./scripts/init_db.sh
APP_ENVIRONMENT=local cargo run
```

### Run with docker-compose with ClickStack accepting traces
For initial run you need first do
```shell
docker-compose up -d hyperdx
```
then http://localhost:8080 -> create user not already -> click on username -> Team Settings -> API Keys ->
Ingestion API Key -> and put it into docker-compose file
Afterwards, `docker-compose up` will bring up everything you need.

### Deploy to Fly
Please see comments in [fly.toml](fly.toml) file.
