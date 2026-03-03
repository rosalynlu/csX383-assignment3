# Milestone 1 — Multi-Cluster Deployment (NodePort Configuration)

## Overview

For Milestone 1, the grocery microservices application is deployed across three Kubernetes clusters (C1, C2, C3).

Because services are distributed across clusters, all remotely accessed services are exposed as NodePort instead of ClusterIP.

The end-to-end grocery pipeline has been verified and is operational.


1. Download S26_CLUSTER.pem to your ssh folder (Prof. Gokhale sent an email on 2/12 about this) and set permissions with
   ```bash   
   chmod 400 ~/.ssh/S26_CLUSTER.pem 
  ```
2. In your ssh folder, edit your config file (nano config) and add the following. Make sure you change the ProxyJump value to whatever your bastion host is named in the config file (ie. I named mine “bastion”):

Host nw-c1-m1
HostName 172.16.1.196
User cc
IdentityFile ~/.ssh/S26_CLUSTER.pem
ProxyJump <WHATEVER YOUR BASTION HOST IS CALLED>

Host nw-c2-m1
HostName 172.16.2.136
User cc
IdentityFile ~/.ssh/S26_CLUSTER.pem
ProxyJump <WHATEVER YOUR BASTION HOST IS CALLED>

Host nw-c3-m1
HostName 172.16.3.137
User cc
IdentityFile ~/.ssh/S26_CLUSTER.pem
ProxyJump <WHATEVER YOUR BASTION HOST IS CALLED>

Host nw-c4-m1
HostName 172.16.4.151
User cc
IdentityFile ~/.ssh/S26_CLUSTER.pem
ProxyJump <WHATEVER YOUR BASTION HOST IS CALLED>

#Cluster Layout

## Cluster C1 — Refrigerator Client

Service: refrigerator
Type: NodePort
Mapping: 8501 → 30091

This cluster hosts the Streamlit Refrigerator client.

## Cluster C2 — Core Services

Service: ordering
Protocol: HTTP
Type: NodePort
Mapping: 5000 → 30083

Service: inventory
Protocol: gRPC + ZMQ publisher
Type: NodePort
Mappings:
50051 → 30081
5556 → 30557

Service: pricing
Protocol: gRPC
Type: NodePort
Mapping: 50053 → 31433

Inventory is configured to call Pricing using NodePort:

```
PRICING_GRPC_ADDR=172.16.2.99:31433
```
This ensures cross-cluster communication is used instead of ClusterIP.

### Cluster C3 — Robot Workers

Robot pods run in Cluster 3.

Robots subscribe to Inventory via ZMQ and report results back via gRPC.

Robots do not require NodePort services.

Deployment Verification

### Check Services
```bash
ssh nw-c1-m1 "kubectl get svc -n team6"
ssh nw-c2-m1 "kubectl get svc -n team6"
ssh nw-c3-m1 "kubectl get svc -n team6"
```

Expected:

C1 refrigerator service is NodePort

C2 ordering, inventory, pricing are NodePort

C3 may not show services for team6

## Check Pods
```bash
ssh nw-c1-m1 "kubectl get pods -n team6 -o wide"
ssh nw-c2-m1 "kubectl get pods -n team6 -o wide"
ssh nw-c3-m1 "kubectl get pods -n team6 -o wide"
```
All pods should show Running.

### End-to-End Functional Verification

Option 1 — Submit Order Using Terminal (Recommended)

### Step 1 — Get a Worker Node IP from Cluster 2
```bash
ssh nw-c2-m1 "kubectl get nodes -o wide | grep nw-c2-w | head -1"
```

Example output:
```
nw-c2-w11 172.16.2.99
```
### Step 2 — Submit a Grocery Order

```bash
curl -X POST http://<worker-node-ip>:30083/submit
-H "Content-Type: application/json"
-d '{
"request_type": "GROCERY_ORDER",
"id": "terminal-test",
"items": {
"bread": 1,
"milk": 1,
"eggs": 1
}
}'
```
Expected Result:

HTTP 200 response

"code": "OK"

Itemized bill

Total price displayed

# Option 2 — Use the Refrigerator Client (Browser)

Because cluster node IPs (172.16.x.x) are private, SSH port forwarding must be used.

### Step 1 — Create SSH Tunnel (run from local machine)
```bash
ssh -L 8501:localhost:30091 nw-c1-m1
```
Leave this terminal open.

### Step 2 — Open Browser

Navigate to:
```
http://localhost:8501
```
Submit a grocery order and confirm:

Request succeeds

Itemized bill is shown

No errors occur

### Cross-Cluster Connectivity Check

Verify Pricing NodePort is reachable from another cluster:

ssh nw-c3-m1 "nc -vz 172.16.2.99 31433"

Expected output:
Connection succeeded


## Milestone 1 Status

Application deployed across clusters
Remote services exposed as NodePort
Cross-cluster communication verified
End-to-end grocery pipeline operational


