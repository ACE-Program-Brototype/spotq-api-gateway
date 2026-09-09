# SpotQ API Gateway

API Gateway service for SpotQ microservices built with Envoy Proxy to provide secure, scalable, and reliable traffic management, routing, health monitoring, and service communication.

---

## Features

- Dynamic Path Routing: Routes external requests to appropriate internal microservices based on `/api/v1/` URI path prefixes.
- WebSocket Proxy: Supports real-time WebSocket connections via HTTP Upgrade on port `10000`. Routes `/ws/<service>` paths to the appropriate backend service with path rewriting.
- Health Checks: Directly exposes gateway readiness endpoints and performs automated background health checks on upstream clusters.
- CORS Configuration: Built-in Cross-Origin Resource Sharing handling for modern web and mobile applications.
- Structured Access Logging: Standard JSON access logs sent to stdout containing latency, status code, cluster routing, and correlation request IDs.
- Admin & Observability Interface: Built-in Envoy administration server exposing metrics, cluster health, and configuration dumps.
- Automatic Retries & Timeouts: Configured retry policies and timeout safety limits for upstream service calls. (WebSocket routes intentionally omit retries — retries are meaningless for stateful connections.)

---

## Repository Structure

```
spotq-api-gateway/
├── .github/
│   └── workflows/
│       └── ci.yml             # GitHub Actions CI pipeline for configuration validation and build testing
├── envoy/
│   └── envoy.yaml             # Main Envoy Proxy configuration file
├── Dockerfile                 # Container packaging based on envoyproxy/envoy:v1.39-latest
├── package.json               # Development scripts and version specification
├── .gitignore                 # Version control exclusion configuration
└── README.md                  # Project documentation
```

---

## Ports and Services

| Port | Protocol | Purpose |
| --- | --- | --- |
| 10000 | HTTP / WebSocket | Primary API Gateway Listener — handles REST (`/api/v1/`) and real-time WebSocket (`/ws/`) traffic via HTTP Upgrade |
| 9901 | HTTP | Envoy Admin Interface & Prometheus Metrics |

---

## Route Mappings

| Ingress Path | Protocol | Upstream Cluster | Upstream Host & Port | Path Rewrite Rule |
| --- | --- | --- | --- | --- |
| `/healthz` | HTTP | Direct Response (Gateway) | N/A | Returns 200 OK with gateway health payload |
| `/api/v1/users/*` | HTTP | `user_service` | `user-service:3000` | Rewrites `/api/v1/users/*` to `/*` |
| `/api/v1/admin/*` | HTTP | `user_service` | `user-service:3000` | Rewrites `/api/v1/admin/*` to `/admin/*` |
| `/api/v1/restaurants/*` | HTTP | `restaurant_service` | `restaurant-service:3001` | Rewrites `/api/v1/restaurants/*` to `/*` |
| `/api/v1/storage/*` | HTTP | `restaurant_service` | `restaurant-service:3001` | Rewrites `/api/v1/storage/*` to `/storage/*` |
| `/api/v1/orders/*` | HTTP | `order_service` | `order-service:3002` | Rewrites `/api/v1/orders/*` to `/*` |
| `/api/v1/payments/*` | HTTP | `payment_service` | `payment-service:3003` | Rewrites `/api/v1/payments/*` to `/*` |
| `/api/v1/queues/*` | HTTP | `queue_service` | `queue-service:3004` | Rewrites `/api/v1/queues/*` to `/*` |
| `/ws/queues` | **WebSocket** | `queue_service` | `queue-service:3004` | Rewrites `/ws/queues` to `/ws` — real-time queue position updates |

---

## Admin Endpoints

The Envoy admin interface is accessible at `http://localhost:9901` when running locally.

### Production Allowlist (`allow_paths`)

- `/ready` - Readiness check for the gateway process.
- `/stats/prometheus` - Prometheus-formatted runtime metrics (latency, HTTP status counts, connection stats).
- `/clusters` - Status and health details for upstream service clusters.

### Sensitive & Debugging Endpoints

- `/config_dump` - **Sensitive**: Dumps full runtime configuration, upstream topologies, and internal routing structures. Excluded from production allowlists and intended for local debugging only.

> **Security Note:** Because the Envoy administration interface is **unauthenticated**, port `9901` must always be restricted to a trusted private network boundary (e.g., binding exclusively to `127.0.0.1`, private VPC subnets, or dedicated internal firewall rules) and must never be exposed to public networks.

---

## Getting Started

### Prerequisites

- Docker installed on host environment (v20.10+ recommended)
- Node.js (v18+) and PNPM (v9+) for running local scripts

### Running via Docker

Build the Docker image:

```bash
docker build -t spotq-api-gateway .
```

Run the container stand-alone:

```bash
docker run -d --name spotq-gateway -p 10000:10000 -p 127.0.0.1:9901:9901 spotq-api-gateway
```

### Running via Docker Compose

In the root repository containing `docker-compose.yaml`:

```bash
docker compose up --build -d api-gateway
```

---

## Package Scripts

Available PNPM scripts defined in `package.json`:

```bash
# Build the Docker image
pnpm run docker:build

# Run gateway container on port 10000 and admin port 9901 (bound to 127.0.0.1)
pnpm run docker:run

# Stop and remove the gateway container
pnpm run docker:stop

# Validate envoy.yaml configuration syntax against official Envoy container
pnpm run validate

# Lint YAML syntax
pnpm run lint
```

---

## Validation & Testing

To validate the syntax of `envoy/envoy.yaml` locally using Envoy:

```bash
docker run --rm -v $(pwd)/envoy/envoy.yaml:/etc/envoy/envoy.yaml:ro envoyproxy/envoy:v1.39-latest envoy --mode validate -c /etc/envoy/envoy.yaml
```

---

## CI/CD Pipeline

Continuous Integration is powered by GitHub Actions (`.github/workflows/ci.yml`). On pushes and pull requests targeting key branches (`main`, `development`, `staging`, `SCRUM-*`, `feat/**`, `fix/**`), the workflow automatically:

1. Validates YAML syntax in `envoy/envoy.yaml`.
2. Builds the container image `spotq-api-gateway`.
3. Executes `envoy --mode validate` inside the built container to ensure valid Envoy routing configuration.
