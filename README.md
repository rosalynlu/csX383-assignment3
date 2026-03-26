# csX383-assignment3

This repository contains the implementation of Programming Assignment 2 for CSX383 using a microservice architecture, which is based off of [Programming Assignment 1](https://github.com/rosalynlu/csX383-assignment1) and [Programming Assignment 2](https://github.com/rosalynlu/csX383-assignment2).

## Table of Contents
* [**Programming Assignment 1**](#Programming-Assignment-1)
  * [Architecture Overview](#Architecture-Overview)
  * [Technologies Used](#Technologies-Used)
  * [Setup](#Setup)
  * [Deployment](#Deployment)
  * [Latency Analytics](#Latency-Analytics)
* [**Programming Assignment 2**](#Programming-Assignment-2)
  * [Locust Workload & Tail Latency Analysis](#Locust-Workload-&-Tail-Latency-Analysis)
  * [ContainerLab HIL Implementation](#ContainerLab-HIL-Implementation)
* [**Programming Assignment 3** (In Progress)](#Programming-Assignment-3-(In-Progress))
  * [Milestone 1: ContainerLab OSPF WAN](#Milestone-1-ContainerLab-OSPF-WAN)
* [Notes](#Notes)

## Repository Structure

```
csX383-assignment3/
├── client/
│   ├── __init__.py
│   └── requirements.txt         # Python dependencies (all services)
├── containerlab1_ospf/          # OSPF WAN topology
│   ├── clab-pa3wan/             # Auto-generated runtime directory
│   │   └── ...
│   ├── outputs/                 # Outputs
│   │   └── ...
│   ├── r1-r6/                   # Router configs (FRR)
│   ├── capture.sh               # Collect routing + OSPF outputs
│   ├── cleanup.sh               # Destroy topology
│   ├── pa3wan.clab.yaml         # ContainerLab topology (6 routers + 2 LAN hosts)
│   ├── run.sh                   # Deploy topology + configure LAN interfaces
│   └── set-lan-ifs.sh           # Configure LAN1/LAN2 host interfaces
├── data/
│   ├── ...                      # Latencies datasets
├── flatbuffers_local/
│   ├── __init__.py
│   └── work.fbs                 # Local FlatBuffers schema backup
├── generated/
│   ├── flatbuffers/
│   │   └── __init__.py          # FlatBuffers generated Python modules
│   ├── proto/
│   │   ├── __init__.py
│   │   ├── grocery_pb2.py       # Generated Protobuf Python code
│   │   └── grocery_pb2_grpc.py  # Generated gRPC Python stubs
│   └── __init__.py
├── groceryfb/
│   ├── __init__.py
│   ├── ItemQty.py               # Generated FlatBuffers classes
│   ├── RequestType.py
│   └── WorkOrder.py
├── inventory/
│   ├── Dockerfile
│   └── requirements.txt
├── k8s/                         # Kubernetes
│   └── ...
├── ordering/
│   ├── Dockerfile
│   └── requirements.txt
├── out/                         # CDF/Latency statistics outputs
│   └── ...
├── pricing/
│   ├── Dockerfile
│   └── requirements.txt
├── robot/
│   ├── Dockerfile
│   └── requirements.txt
├── schemas/
│   ├── flatbuffers/
│   │   └── work.fbs             # FlatBuffers schema (Inventory -> Robots)
│   ├── proto/
│   │   ├── grocery.proto        # Protobuf schema (all gRPC services)
│   │   └── robots.proto         # Robot-specific Protobuf definitions
│   └── sql/
│       ├── init_schema.sql      # PostgreSQL database schema
│       └── seed_data.sql        # Initial data for items and pricing
├── scripts/
│   ├── init_db.sh               # Database initialization script
│   ├── locustfile.py            # Locust worload definition for load testing
│   ├── plot_latency.py          # latency analytics visualization script
│   ├── requirements.txt
│   └── tail_latency.py          # P2 tail lantency analysis(P50/P90/P95 + CDF) 
├── services/
│   ├── client_streamlit/
│   │   ├── Dockerfile
│   │   ├── app.py               # Streamlit web UI client
│   │   └── requirements.txt
│   ├── inventory_grpc/
│   │   ├── __init__.py
│   │   └── server.py            # Inventory gRPC server + ZeroMQ PUB
│   ├── ordering_flask/
│   │   └── app.py               # Flask Ordering service (HTTP/JSON -> gRPC)
│   ├── pricing_grpc/
│   │   ├── __init__.py
│   │   └── server.py            # Pricing gRPC server
│   └── robots/
│       └── robot.py             # Robot worker (run 5 instances with different names)
├── utils/
│   ├── __init__.py
│   └── db.py                    # Database connection helper
├── .dockerignore
├── .env                         # Environment variables (not in git)
├── .env.example                 # Example environment configuration
├── .gitignore
├── DOCKER_README.md
├── MILESTONE1_MULTICLUSTER_README.md
├── README.md                    # This file
└── build-all-sh
```

# Programming Assignment 1

## Architecture Overview

- **Streamlit** web interface client
- **Flask + HTTP/JSON** ordering microservice
- **gRPC + Protobuf** inventory microservice
- **gRPC + Protobuf** pricing microservice
- **PostgreSQL** database (inventory, pricing, analytics)
- **ZeroMQ pub-sub + FlatBuffers** payload for robot communication
  - Inventory publishes FETCH/RESTOCK topics via FlatBuffers payload
  - Robots subscribe and respond back to inventory via gRPC/Protobuf

## Technologies Used

- **Frontend**: Streamlit web UI
- **Ordering Service**: Flask + HTTP/JSON → gRPC
- **Inventory Service**: gRPC + Protobuf server, ZeroMQ PUB publisher
- **Pricing Service**: gRPC + Protobuf server
- **Robot Communication**:
  - Inventory → Robots: ZeroMQ PUB/SUB + FlatBuffers
  - Robots → Inventory: gRPC + Protobuf
- **Database**: PostgreSQL (inventory, pricing, analytics)
- **Deployment Environment**: Chameleon Cloud VM (Ubuntu 24.04)
- **Access Method**: SSH with port forwarding (tunneling)

## Setup

### Requirements

SSH into the VM from your local machine (using your SSH config + bastion setup)

From the repository root, activate the virtual environment:

```
source .venv/bin/activate
```

Install required packages:

```bash
pip install -r client/requirements.txt
```

Install FlatBuffers compiler (flatc):

```bash
sudo apt update
sudo apt install -y flatbuffers-compiler
flatc --version
```

### Database Setup

The PostgreSQL database stores:
- **Items table**: Product inventory (name, category, quantity)
- **Pricing table**: Item pricing information
- **Analytics table**: Request tracking (request_id, served_id, request_type, duration metrics)

Install PostgreSQL:

```bash
sudo apt update
sudo apt install -y postgresql postgresql-contrib
```

Start PostgreSQL service:

```bash
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

Create database user and set password (skip this step if already created):

```bash
sudo -u postgres createuser -s --pwprompt admin
```

Copy environment configuration:

```bash
cp .env.example .env
```

Edit the .env file and set your database password:

```bash
nano .env
```

Update the following variables:
- `DB_PASSWORD`: The password you set for your PostgreSQL user
- `DB_USER`: Database user (default: admin)
- `DB_NAME`: Database name (default: grocery_db)
- `DB_HOST`: Database host (default: localhost)
- `DB_PORT`: Database port (default: 5432)

Initialize database (creates tables and seeds initial data):

```bash
bash scripts/init_db.sh
```

This script will:
- Create the grocery_db database
- Create tables (items, pricing, analytics)
- Seed initial inventory data (9 items across 5 categories)
- Seed pricing data for all items

Expected output:

```bash
Database initialized and seeded
```

## Deployment

You will run Inventory, 5 robots, Pricing, Ordering, and Streamlit on the cloud VM.

### Install and start tmux

```bash
sudo apt install -y tmux
tmux new -s pa1
```

where `pa1` is the user-defined tmux session name.

Once inside tmux, create windows for each service. After each command, the terminal will hang (this is expected). To open a new window, `CTRL-B + C` or `CTRL-B + : + new-window`. The new window should already be in the repository root.

### Run

**Window 1 - Inventory (gRPC + ZeroMQ PUB)**

```bash
source .venv/bin/activate
python services/inventory_grpc/server.py
```

Expected output:

```bash
[Inventory] ZMQ PUB bound at tcp://0.0.0.0:5556
[Inventory gRPC] listening on 0.0.0.0:50051
```

**Windows 2-6 - Robots (5 separate processes)**

Run one command per window:

```bash
source .venv/bin/activate
python services/robots/robot.py --name bread
```

```bash
source .venv/bin/activate
python services/robots/robot.py --name dairy
```

```bash
source .venv/bin/activate
python services/robots/robot.py --name meat
```

```bash
source .venv/bin/activate
python services/robots/robot.py --name produce
```

```bash
source .venv/bin/activate
python services/robots/robot.py --name party
```

Expected outputs:

```bash
[bread] Connected SUB to tcp://127.0.0.1:5556 (topics: FETCH, RESTOCK)
[bread] gRPC connected to Inventory at 127.0.0.1:50051
```

```bash
[dairy] Connected SUB to tcp://127.0.0.1:5556 (topics: FETCH, RESTOCK)
[dairy] gRPC connected to Inventory at 127.0.0.1:50051
```

```bash
[meat] Connected SUB to tcp://127.0.0.1:5556 (topics: FETCH, RESTOCK)
[meat] gRPC connected to Inventory at 127.0.0.1:50051
```

```bash
[produce] Connected SUB to tcp://127.0.0.1:5556 (topics: FETCH, RESTOCK)
[produce] gRPC connected to Inventory at 127.0.0.1:50051
```

```bash
[party] Connected SUB to tcp://127.0.0.1:5556 (topics: FETCH, RESTOCK)
[party] gRPC connected to Inventory at 127.0.0.1:50051
```

**Window 7 - Pricing (gRPC)**

```bash
source .venv/bin/activate
python services/pricing_grpc/server.py
```

Expected output:

```bash
[Pricing gRPC] listening on 0.0.0.0:50053
```

**Window 8 - Ordering (Flask)**

```bash
source .venv/bin/activate
export INVENTORY_ADDR=127.0.0.1:50051
export FLASK_APP=services/ordering_flask/app.py
flask run --host 0.0.0.0 --port 5000
```

Expected output:

```bash
 * Serving Flask app 'services/ordering_flask/app.py'
 * Debug mode: off
WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on all addresses (0.0.0.0)
 * Running on http://127.0.0.1:5000
 * Running on http://172.16.6.226:5000
Press CTRL+C to quit
```

**Window 9 - Streamlit Client**

```bash
source .venv/bin/activate
streamlit run services/client_streamlit/app.py --server.address 0.0.0.0 --server.port 8501
```

Expected output:

```bash
Collecting usage statistics. To deactivate, set browser.gatherUsageStats to false.


  You can now view your Streamlit app in your browser.

  URL: http://0.0.0.0:8501
```

### Detach tmux

To leave tmux running, `CTRL-B + D`.

To reattach later:

```bash
tmux attach -t pa1
```

where `pa1` is the same user-defined tmux session name as when it was created.

**Open in browser**

Streamlit UI:

http://localhost:8501

Ordering health check:

http://localhost:5000/health

### Using the Client

1. Open http://localhost:8501 in your browser

2. Set Ordering Service URL to:
   ```
   http://localhost:5000/submit
   ```

3. Select request type (`GROCERY_ORDER` or `RESTOCK_ORDER`)

4. Enter Customer/Supplier ID

5. Add item quantities (>0) for items across different categories

6. Click Submit

7. View the response:
   - For **GROCERY_ORDER**: Returns itemized bill with pricing and total
   - For **RESTOCK_ORDER**: Returns confirmation of inventory restocked

**Example JSON payload:**

```json
{
  "request_type": "GROCERY_ORDER",
  "id": "abc123",
  "items": {
    "bread": 1,
    "milk": 1,
    "beef": 1,
    "apples": 2,
    "napkins": 1
  }
}
```

**Example Streamlit display:**

```
HTTP status: 200
```

**Example JSON response (Grocery Order):**

```json
{
  "code": "OK"
  "message":
  "OK: received all robot replies for 3a31108f-a986-40b8-8bde-2ea8043e1ddd\n\nITEMIZED BILL:\n\tapples: 2 x $2.99 = $5.98\n\tnapkins: 1 x $4.99 = $4.99\n\tbread: 1 x $3.99 = $3.99\n\tmilk: 1 x $4.50 = $4.50\n\tbeef: 1 x $12.99 = $12.99\nTOTAL: $32.45"
}
```

**Example JSON response (Restock Order):**

```json
{
  "code": "OK",
  "message": "OK: received all robot replies for 5b42119g-b997-51c9-9cef-3fb9154f2eee"
}
```

Inventory terminal logs will show that it:
- receives gRPC request
- publishes FETCH via ZeroMQ
- receives 5 robot gRPC responses (ROBOT_OK or ROBOT_NOOP)

Robot terminals will also log their received message and response.

**Example:**

```bash
[bread] Working on bread (sleep 0.50s)
[bread] OK sent request_id=3a31108f-a986-40b8-8bde-2ea8043e1ddd served_id=abc123 items=['bread']
```

```bash
[dairy] Working on milk (sleep 0.58s)
[dairy] OK sent request_id=3a31108f-a986-40b8-8bde-2ea8043e1ddd served_id=abc123 items=['milk']
```

```bash
[meat] Working on beef (sleep 0.46s)
[meat] OK sent request_id=3a31108f-a986-40b8-8bde-2ea8043e1ddd served_id=abc123 items=['beef']
```

```bash
[produce] Working on apples (sleep 0.33s)
[produce] OK sent request_id=3a31108f-a986-40b8-8bde-2ea8043e1ddd served_id=abc123 items=['apples']
```

```bash
[party] Working on napkins (sleep 0.52s)
[party] OK sent request_id=3a31108f-a986-40b8-8bde-2ea8043e1ddd served_id=abc123 items=['napkins']
```

```bash
127.0.0.1 - - [06/Feb/2026 01:02:59] "POST /submit HTTP/1.1" 200 -
```

## Latency Analytics

Added a latency analytics visualization pipeline using PostgreSQL analytics data.

**Functionality:**
- Queries latency data from the PostgreSQL analytics table
- Generates latency histogram and boxplot visualizations
- Outputs summary statistics for latency performance

**Prerequisites:**
- PostgreSQL running
- Database initialized (`scripts/init_db.sh`)
- Services running (inventory, pricing, ordering, robots)
- Latency data generated by submitting orders through Streamlit

**Generate Latency Data**
1. Start all services
2. Open Streamlit UI
3. Submit approximately 20-50 orders

**Running**

From repository root:

```bash
cd ~/csX383-assignment1
source .venv/bin/activate
export $(grep -v '^#' .env | xargs)
python scripts/plot_latency.py
```

To run the script from your local machine instead of the VM, forward port 5432 (see the updated SSH command in [Notes](#notes)).

**Output:**
- `latency_histogram.png`
- `latency_boxplot.png`
- `latency_summary.txt`

If no latency data exists, the script will print `No latency data found in analytics table.`

# Programming Assignment 2

## Locust Workload & Tail Latency Analysis

### Running Locust Experiments
For local testing: 
Start all services (see Deployment section), then run from the project root:
```bash
source venv/bin/activate

# 1 concurrent user (3 reps)
RUN_TAG=u1_rep1 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 1 -r 1 --run-time 60s --host http://localhost:5000 2>/dev/null
RUN_TAG=u1_rep2 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 1 -r 1 --run-time 60s --host http://localhost:5000 2>/dev/null
RUN_TAG=u1_rep3 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 1 -r 1 --run-time 60s --host http://localhost:5000 2>/dev/null

# 10 concurrent users (3 reps)
RUN_TAG=u10_rep1 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 10 -r 10 --run-time 60s --host http://localhost:5000 2>/dev/null
RUN_TAG=u10_rep2 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 10 -r 10 --run-time 60s --host http://localhost:5000 2>/dev/null
RUN_TAG=u10_rep3 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 10 -r 10 --run-time 60s --host http://localhost:5000 2>/dev/null

# 20 concurrent users (3 reps)
RUN_TAG=u20_rep1 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 20 -r 20 --run-time 60s --host http://localhost:5000 2>/dev/null
RUN_TAG=u20_rep2 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 20 -r 20 --run-time 60s --host http://localhost:5000 2>/dev/null
RUN_TAG=u20_rep3 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 20 -r 20 --run-time 60s --host http://localhost:5000 2>/dev/null
```

Output CSVs are saved to `data/latencies_<RUN_TAG>.csv`. Workload is 85% refrigerator (GROCERY_ORDER) and 15% truck (RESTOCK_ORDER).

For testing on VM, ssh into nw-c1-m1, cd into csX383-assignment2, and run the following:
```bash
python3 -m venv venv
source venv/bin/activate
pip install -r scripts/requirements.txt

# Same commands as above, but with the VM's internal IP address for the host

# 1 concurrent user
RUN_TAG=u1_rep1 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 1 -r 1 --run-time 60s --host http://172.16.2.136:30083 2>/dev/null
RUN_TAG=u1_rep2 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 1 -r 1 --run-time 60s --host http://172.16.2.136:30083 2>/dev/null
RUN_TAG=u1_rep3 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 1 -r 1 --run-time 60s --host http://172.16.2.136:30083 2>/dev/null

# 10 concurrent users
RUN_TAG=u10_rep1 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 10 -r 10 --run-time 60s --host http://172.16.2.136:30083 2>/dev/null
RUN_TAG=u10_rep2 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 10 -r 10 --run-time 60s --host http://172.16.2.136:30083 2>/dev/null
RUN_TAG=u10_rep3 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 10 -r 10 --run-time 60s --host http://172.16.2.136:30083 2>/dev/null

# 20 concurrent users
RUN_TAG=u20_rep1 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 20 -r 20 --run-time 60s --host http://172.16.2.136:30083 2>/dev/null
RUN_TAG=u20_rep2 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 20 -r 20 --run-time 60s --host http://172.16.2.136:30083 2>/dev/null
RUN_TAG=u20_rep3 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 20 -r 20 --run-time 60s --host http://172.16.2.136:30083 2>/dev/null
```

### Computing Tail Latencies & CDF Plots
```bash
python3 scripts/tail_latency.py \
  --input data/latencies_u1_rep*.csv data/latencies_u10_rep*.csv data/latencies_u20_rep*.csv \
  --outdir out \
  --title "Latency CDF" \
  --combined
```

**Output:**
- `out/cdf_per_run.png` — CDF curve per run
- `out/cdf_combined.png` — all runs overlaid
- `out/per_run_tail_latencies.csv` — P50/P90/P95/P99 per run
- `out/summary.txt` — pooled statistics across all runs

## ContainerLab HIL Implementation

### Install ContainerLab and Docker

Run on a seperate VM used for network emulation.

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo $VERSION_CODENAME) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

bash -c "$(curl -sL https://get.containerlab.dev)"
sudo usermod -aG docker $USER
newgrp docker
```

### Build WAN Forwarder Image

Run on ContainerLab VM.

If `wan_forwarder` directory does not exist yet:

```bash
mkdir -p wan_forwarder
```

```bash
cd wan_forwarder
cat > Dockerfile <<'EOF'
FROM alpine:3.20
RUN apk add --no-cache socat iproute2
CMD ["sh","-c","sleep infinity"]
EOF
docker build -t wan-forwarder:latest .
```

Create `topo.yaml`:

```yaml
name: pa2-wan
topology:
  nodes:
    wan_c1_c2:
      kind: linux
      image: wan-forwarder:latest
    wan_c2_c3:
      kind: linux
      image: wan-forwarder:latest
```

Deploy and verify topology:

```bash
sudo containerlab deploy -t topo.yaml
docker ps | grep pa2-wan
```

Inside the forwarders:

```bash
docker exec -it clab-pa2-wan-wan_c1_c2 sh -lc '
# forward WAN endpoint port 30083 -> real ordering nodeport
socat TCP-LISTEN:30083,fork,reuseaddr TCP:<CLUSTER_WORKER_NODE_IP>:30083 &
'
```

```bash
docker exec -it clab-pa2-wan-wan_c2_c3 sh -lc '
# gRPC
socat TCP-LISTEN:30081,fork,reuseaddr TCP:<CLUSTER_WORKER_NODE_IP>:30081 &
# ZMQ (still TCP)
socat TCP-LISTEN:30557,fork,reuseaddr TCP:<CLUSTER_WORKER_NODE_IP>:30557 &
'
```

Get WAN endpoint IPs:

We inserted ContainerLab WAN links in two places: between Cluster 1 and Cluster 2 (C1-C2), and between Cluster 2 and Cluster 3 (C2-C3).

```bash
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' clab-pa2-wan-wan_c1_c2
docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' clab-pa2-wan-wan_c2_c3
```

Apply WAN scenarios:

```bash
# C1-C2
docker exec -it clab-pa2-wan-wan_c1_c2 sh -lc '
tc qdisc add dev eth0 root netem delay 30ms loss 1% 2>/dev/null || true
'
# C2-C3
docker exec -it clab-pa2-wan-wan_c2_c3 sh -lc '
tc qdisc add dev eth0 root netem delay 30ms loss 1% 2>/dev/null || true
'
```

```bash
docker exec -it clab-pa2-wan-wan_c1_c2 sh -lc '
tc qdisc replace dev eth0 root netem delay 80ms loss 0.5%
tc qdisc add dev eth0 parent 1:1 tbf rate 10mbit burst 32kbit latency 400ms 2>/dev/null || true
'
# (if tbf layering is annoying, keep it simple and just do delay/loss)
```

```bash
docker exec -it clab-pa2-wan-wan_c1_c2 sh -lc 'tc qdisc del dev eth0 root 2>/dev/null || true'
docker exec -it clab-pa2-wan-wan_c2_c3 sh -lc 'tc qdisc del dev eth0 root 2>/dev/null || true'
```

### Point K8s Deployments

Run on local machine.

```bash
scp -r <VM_NAME>:~csX383-assignment2/k8s nw-c1-m1:~/team6
ssh nw-c1-m1 "kubectl apply -f team6/k8s/refrigerator-c1.yaml"
ssh nw-c3-m1 "kubectl apply -f team6/k8s/robots-c3.yaml"
```

Now all inter-cluster communication passes through ContainerLab WAN forwarders.

### Simulate WAN Network Conditions

```bash
docker exec clab-pa2-wan-wan_c1_c2 tc qdisc add dev eth0 root netem delay 30ms loss 1%

docker exec clab-pa2-wan-wan_c2_c3 tc qdisc add dev eth0 root netem delay 30ms loss 1%
```

```bash
docker exec clab-pa2-wan-wan_c1_c2 tc qdisc replace dev eth0 root netem delay 80ms loss 0.5%

docker exec clab-pa2-wan-wan_c2_c3 tc qdisc replace dev eth0 root netem delay 80ms loss 0.5%
```

```bash
docker exec clab-pa2-wan-wan_c1_c2 tc qdisc del dev eth0 root

docker exec clab-pa2-wan-wan_c2_c3 tc qdisc del dev eth0 root
```

### Run Workload Experiments

Repeat locust experiments for each WAN scenario and user load from the repo root:

```bash
python3 -m venv venv
source venv/bin/activate
```

```bash
RUN_TAG=baseline_u1_rep1 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 1 -r 1 --run-time 60s --host http://<NODE_IP>:30083
RUN_TAG=baseline_u1_rep2 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 1 -r 2 --run-time 60s --host http://<NODE_IP>:30083
RUN_TAG=baseline_u1_rep3 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 1 -r 3 --run-time 60s --host http://<NODE_IP>:30083
```

```bash
RUN_TAG=baseline_u10_rep1 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 10 -r 1 --run-time 60s --host http://<NODE_IP>:30083 2>/dev/null
RUN_TAG=baseline_u10_rep2 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 10 -r 2 --run-time 60s --host http://<NODE_IP>:30083 2>/dev/null
RUN_TAG=baseline_u10_rep3 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 10 -r 3 --run-time 60s --host http://<NODE_IP>:30083 2>/dev/null
```

```bash
RUN_TAG=baseline_u20_rep1 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 20 -r 1 --run-time 60s --host http://<NODE_IP>:30083 2>/dev/null
RUN_TAG=baseline_u20_rep2 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 20 -r 2 --run-time 60s --host http://<NODE_IP>:30083 2>/dev/null
RUN_TAG=baseline_u20_rep3 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 20 -r 3 --run-time 60s --host http://<NODE_IP>:30083 2>/dev/null
```

```bash
RUN_TAG=wan30ms_u1_rep1 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 1 -r 1 --run-time 60s --host http://<NODE_IP>:30083 2>/dev/null
RUN_TAG=wan30ms_u1_rep2 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 1 -r 2 --run-time 60s --host http://<NODE_IP>:30083 2>/dev/null
RUN_TAG=wan30ms_u1_rep3 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 1 -r 3 --run-time 60s --host http://<NODE_IP>:30083 2>/dev/null
```

```bash
RUN_TAG=wan30ms_u10_rep1 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 10 -r 1 --run-time 60s --host http://<NODE_IP>:30083 2>/dev/null
RUN_TAG=wan30ms_u10_rep2 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 10 -r 2 --run-time 60s --host http://<NODE_IP>:30083 2>/dev/null
RUN_TAG=wan30ms_u10_rep3 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 10 -r 3 --run-time 60s --host http://<NODE_IP>:30083 2>/dev/null
```

```bash
RUN_TAG=wan30ms_u20_rep1 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 20 -r 1 --run-time 60s --host http://<NODE_IP>:30083 2>/dev/null
RUN_TAG=wan30ms_u20_rep2 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 20 -r 2 --run-time 60s --host http://<NODE_IP>:30083 2>/dev/null
RUN_TAG=wan30ms_u20_rep3 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 20 -r 3 --run-time 60s --host http://<NODE_IP>:30083 2>/dev/null
```

```bash
RUN_TAG=wan80ms_u1_rep1 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 1 -r 1 --run-time 60s --host http://<NODE_IP>:30083 2>/dev/null
RUN_TAG=wan80ms_u1_rep2 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 1 -r 2 --run-time 60s --host http://<NODE_IP>:30083 2>/dev/null
RUN_TAG=wan80ms_u1_rep3 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 1 -r 3 --run-time 60s --host http://<NODE_IP>:30083 2>/dev/null
```

```bash
RUN_TAG=wan80ms_u10_rep1 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 10 -r 1 --run-time 60s --host http://<NODE_IP>:30083 2>/dev/null
RUN_TAG=wan80ms_u10_rep2 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 10 -r 2 --run-time 60s --host http://<NODE_IP>:30083 2>/dev/null
RUN_TAG=wan80ms_u10_rep3 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 10 -r 3 --run-time 60s --host http://<NODE_IP>:30083 2>/dev/null
```

```bash
RUN_TAG=wan80ms_u20_rep1 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 20 -r 1 --run-time 60s --host http://<NODE_IP>:30083 2>/dev/null
RUN_TAG=wan80ms_u20_rep2 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 20 -r 2 --run-time 60s --host http://<NODE_IP>:30083 2>/dev/null
RUN_TAG=wan80ms_u20_rep3 LOCUST_LOG_DIR=data locust -f scripts/locustfile.py --headless -u 20 -r 3 --run-time 60s --host http://<NODE_IP>:30083 2>/dev/null
```

`REFRIGERATOR_NODE_IP`: `172.20.20.2`

`ROBOTS_NODE_IP`: `172.20.20.3`

### Generate Tail Latency and CDF Plots

```bash
python3 scripts/tail_latency.py \
  --input "data/latencies_baseline_u*_rep*.csv" \
  --outdir out/baseline \
  --title "Baseline" \
  --combined
```

```bash
python3 scripts/tail_latency.py \
  --input "data/latencies_wan30ms_u*_rep*.csv" \
  --outdir out/wan30ms \
  --title "WAN 30ms + 1% loss" \
  --combined
```

```bash
python3 scripts/tail_latency.py \
  --input "data/latencies_wan80ms_u*_rep*.csv" \
  --outdir out/wan80ms \
  --title "WAN 80ms + 0.5% loss" \
  --combined
```

Metrics generated:
- P50 latency
- P90 latency
- P95 latency
- P99 latency

CDF plots are stored in `out/`.

# Programming Assignment 3 (In Progress)

## Milestone 1: ContainerLab OSPF WAN

This replaces the original ContainerLab WAN forwarder with a 6-router OSPF-based WAN topology using FRRouting (FRR).

- Traffic enters through LAN1
- Traverses the WAN using OSPF shortest path (cost-based)
- Exits through LAN2
- Demonstrates link-state routing (Dijkstra) behavior

### Setup and Run

- Start all routers (r1–r6)
- Start LAN hosts (lan1host, lan2host)
- Configure LAN interfaces and routing

From repository root, navigate to the ContainerLab directory and deploy the topology:

```bash
cd containerlab1_ospf
./run.sh
```

Verify containers are running:

```bash
docker ps | grep clab-pa3wan
```

Check OSPF neighbors and routing table:

```bash
docker exec -it clab-pa3wan-r1 vtysh -c "show ip ospf neighbor"
docker exec -it clab-pa3wan-r1 vtysh -c "show ip route"
```

Run traceroute:

```bash
docker exec -it clab-pa3wan-lan1host traceroute 172.16.2.2
```

Expected path:

```
lan1 -> r4 -> r1 -> r3 -> r5 -> r2 -> r6 -> lan2
```

### Collect Required Outputs

Run:

```bash
./capture.sh
```

Generates in containerlab1_ospf/outputs
- `show ip route`
- `show ip ospf neighbor`
- `show ip ospf database`
- traceroute output

### Packet Capture (Wireshark/tcpdump)

Run from local machine:

```bash
ssh <VM_NAME> "docker exec -i clab-pa3wan-r1 tcpdump -i eth1 -U -w -" | wireshark -k -i
```

Or save to file:

```bash
ssh <VM_NAME> "docker exec -i clab-pa3wan-r1 tcpdump -i eth1 -U -w -" > r1_eth1.pcap
```

Open .pcap in Wireshark

### Cleanup

Run:

```bash
./cleanup.sh
```

# Notes

**PostgreSQL authentication tip:** To avoid re-running the database user/password setup after each VM restart, you can set `pg_hba.conf` to use `trust` authentication for local connections. Then a simple `sudo systemctl restart postgresql` will bring the existing database back up without needing to recreate anything.

**Port forwarding:** To run on a floating IP on Chameleon Cloud, on a separate terminal on your local machine (before opening in browser):

```bash
ssh -i ~/.ssh/VM-key.pem \
  -N -L 8501:127.0.0.1:8501 -L 5000:127.0.0.1:5000 -L 5432:127.0.0.1:5432 \
  cc@129.114.24.252
```

where `VM-key.pem` is the virtual machine key (`team-ras-ssh-keypair.pem`). Port 5432 is for running the analytics script locally against the VM's PostgreSQL database.

From here, the rest of the instructions are the same.

**Checking OSPF neighbors:** The warning `Can't open configuration file /etc/frr/vtysh.conf` or configuration file processing failure notices are non-blocking and don't affect OSPF functionality. They are ignorable.
