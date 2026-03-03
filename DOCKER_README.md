# Docker Build & Run Guide

## Important: Build Context

All Docker builds **must be run from the project root** because the Dockerfiles
reference shared directories (`generated/`, `groceryfb/`, `utils/`) that live at
the project root.

```bash
cd /path/to/csX383-assignment2   # project root
```

---

## Build All Images at Once

```bash
chmod +x build-all.sh
./build-all.sh
```

To tag for a private registry:
```bash
REGISTRY=192.168.1.88:5000/team1 ./build-all.sh
```

---

## Build & Test Each Service Individually

### 1. Ordering Service (Flask HTTP, port 5000)

```bash
# Build
docker build -f ordering/Dockerfile -t ordering-service .

# Run locally
docker run -p 5000:5000 \
  -e INVENTORY_ADDR=<inventory-host>:50051 \
  ordering-service

# Test
curl http://localhost:5000/health
curl -X POST http://localhost:5000/submit \
  -H "Content-Type: application/json" \
  -d '{"request_type":"GROCERY_ORDER","id":"cust1","items":{"bread":1}}'
```

---

### 2. Inventory Service (gRPC port 50051, ZMQ PUB port 5556)

```bash
# Build
docker build -f inventory/Dockerfile -t inventory-service .

# Run locally
docker run -p 50051:50051 -p 5556:5556 \
  -e DB_HOST=<db-host> \
  -e DB_PORT=5432 \
  -e DB_NAME=grocery_db \
  -e DB_USER=admin \
  -e DB_PASSWORD=<password> \
  -e PRICING_GRPC_ADDR=<pricing-host>:50053 \
  -e ZMQ_PUB_ADDR=tcp://0.0.0.0:5556 \
  inventory-service
```

---

### 3. Pricing Service (gRPC port 50053)

```bash
# Build
docker build -f pricing/Dockerfile -t pricing-service .

# Run locally
docker run -p 50053:50053 \
  -e DB_HOST=<db-host> \
  -e DB_PORT=5432 \
  -e DB_NAME=grocery_db \
  -e DB_USER=admin \
  -e DB_PASSWORD=<password> \
  pricing-service
```

---

### 4. Robot Service (5 instances, one per aisle)

One image, configured via `ROBOT_NAME`. Run five containers:

```bash
# Build (once)
docker build -f robot/Dockerfile -t robot-service .

# Run all 5 robots
for AISLE in bread dairy meat produce party; do
  docker run -d \
    -e ROBOT_NAME=${AISLE} \
    -e ZMQ_SUB_ADDR=tcp://<inventory-host>:5556 \
    -e INVENTORY_ADDR=<inventory-host>:50051 \
    --name robot-${AISLE} \
    robot-service
done

# View logs for a specific robot
docker logs robot-bread
```

---

## Environment Variables Reference

| Service   | Variable           | Default                  | Description                        |
|-----------|--------------------|--------------------------|------------------------------------|
| ordering  | `INVENTORY_ADDR`   | `localhost:50051`        | Inventory gRPC endpoint            |
| inventory | `PRICING_GRPC_ADDR`| `localhost:50053`        | Pricing gRPC endpoint              |
| inventory | `ZMQ_PUB_ADDR`     | `tcp://0.0.0.0:5556`    | ZMQ PUB bind address               |
| inventory | `DB_HOST`          | `localhost`              | PostgreSQL host                    |
| inventory | `DB_PORT`          | `5432`                   | PostgreSQL port                    |
| inventory | `DB_NAME`          | `grocery_db`             | PostgreSQL database name           |
| inventory | `DB_USER`          | `admin`                  | PostgreSQL user                    |
| inventory | `DB_PASSWORD`      | *(empty)*                | PostgreSQL password                |
| pricing   | `DB_*`             | *(same as inventory)*    | PostgreSQL credentials             |
| robot     | `ROBOT_NAME`       | `bread`                  | Robot aisle (bread/dairy/meat/produce/party) |
| robot     | `ZMQ_SUB_ADDR`     | `tcp://127.0.0.1:5556`  | ZMQ SUB connect address            |
| robot     | `INVENTORY_ADDR`   | `127.0.0.1:50051`        | Inventory gRPC for reporting results|

---

## Port Reference

| Service   | Protocol | Port  | Notes                              |
|-----------|----------|-------|------------------------------------|
| ordering  | HTTP     | 5000  | Flask REST API (`/submit`, `/health`) |
| inventory | gRPC     | 50051 | Receives orders, robot results     |
| inventory | ZMQ PUB  | 5556  | Publishes work orders to robots    |
| pricing   | gRPC     | 50053 | Returns itemized pricing           |
| robots    | —        | —     | No inbound port (subscriber/client)|

> **K8s NodePort mapping (from PA2 spec):**
> Ordering 5000 → NodePort 30080,
> Inventory 50051 → NodePort 30081,
> Pricing 50053 → NodePort 30082

---

## Tagging for Private Registry

```bash
REGISTRY=192.168.1.88:5000/team1

docker tag ordering-service  ${REGISTRY}/ordering-service:latest
docker tag inventory-service ${REGISTRY}/inventory-service:latest
docker tag pricing-service   ${REGISTRY}/pricing-service:latest
docker tag robot-service     ${REGISTRY}/robot-service:latest

docker push ${REGISTRY}/ordering-service:latest
docker push ${REGISTRY}/inventory-service:latest
docker push ${REGISTRY}/pricing-service:latest
docker push ${REGISTRY}/robot-service:latest
```
