## What
Code in this repo is a result of following [Zero To Production In Rust](https://github.com/LukeMathWalker/zero-to-production)
book that builds newsletter app, with my certain additions to the code of it like:
1) incrementing on what is already provided in book,
2) doing certain things differently.

## Why
1. Showcasing my ways working with code, building backends and infra for them, and leaving place for questions like
'What can be improved here?'
2. Place for me to explore new technologies, for example Rust or [Fly](https://fly.io)

## Already there, added by me:
1. [Otel layer](src/telemetry.rs) for sending traces to [ClickStack](https://clickhouse.com/use-cases/observability).
2. Deploy to [Fly](https://fly.io), please [fly.toml](fly.toml) file.
3. Sending traces to [ClickStack](https://clickhouse.com/use-cases/observability) and [docker-compose](docker-compose.yml) file to see it all work together.
4. Kubernetes resources[k8s/minikube](k8s/minikube/) and scripts for [minikube up](scripts/minikube_up.sh) and 
[down](scripts/minikube_down.sh).

## How to explore

### Local run of newsletter service with db through cargo run
```shell
./scripts/init_db.sh
APP_ENVIRONMENT=local cargo run
```

### Run on Minikube
This project now has Kubernetes manifests that mirror the current local setup:
- postgres
- migrate job
- hyperdx (ClickStack all-in-one)
- newsletter service

Bring everything up with:
```shell
./scripts/minikube_up.sh
```

By default, the script starts Minikube with `5 CPU` and `10240MB` memory.
Override if needed:
```shell
MINIKUBE_CPUS=6 MINIKUBE_MEMORY_MB=11264 ./scripts/minikube_up.sh
```
It also uses `calico` CNI by default.
Override if needed:
```shell
MINIKUBE_CNI=flannel ./scripts/minikube_up.sh
```

Then port-forward:
```shell
kubectl -n newsletter port-forward svc/newsletter 8000:8000
kubectl -n newsletter port-forward svc/hyperdx 8080:8080 4317:4317 4318:4318
```

Open `http://localhost:8080` to configure HyperDX and generate an ingestion API key.
Then create/update `newsletter-secrets` (`otel-api-key`) to enable OTEL export:
```shell
HYPERDX_INGESTION_KEY=<your-key> ./scripts/set_hyperdx_key.sh
```

Smoke-test the whole setup (app + db + ClickStack):
```shell
# app health
curl -i http://127.0.0.1:8000/health_check

# app write path
curl -i -X POST http://127.0.0.1:8000/subscriptions \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d 'name=Alice%20Tester&email=alice@example.com'

# db verification (subscription row should be present)
kubectl -n newsletter exec -it postgres-0 -- \
  psql -U postgres -d newsletter -c \
  "select email,name,subscribed_at from subscriptions order by subscribed_at desc limit 5;"
```
After those requests, check `http://localhost:8080` for incoming telemetry from `newsletter`.

Tear down Minikube resources:
```shell
./scripts/minikube_down.sh
```

Optional cleanup flags:
```shell
./scripts/minikube_down.sh --remove-images --stop-cluster
```

### Run with docker-compose (with ClickStack accepting traces)

For initial run you need first do

docker-compose up -d hyperdx
then http://localhost:8080 -> create user not already -> click on username -> Team Settings -> API Keys -> Ingestion API Key -> and put it into docker-compose file Afterwards, docker-compose up will bring up everything you need.

### Deploy to Fly
Please see comments in [fly.toml](fly.toml) file.
