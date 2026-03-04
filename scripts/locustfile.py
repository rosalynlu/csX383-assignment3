from locust import HttpUser, task, between, events
import csv
import os
import time
import random
import threading

"""
Locust workload generator for PA2 Milestone 2:

- Refrigerator requests: GROCERY_ORDER (higher proportion)
- Truck requests: RESTOCK_ORDER (lower proportion)

Targets Flask Ordering service: POST /submit
"""

# ---------- Raw per-request latency logging ----------
LOG_DIR = os.getenv("LOCUST_LOG_DIR", "data")
RUN_TAG = os.getenv("RUN_TAG", time.strftime("%Y%m%d_%H%M%S"))
OUT_CSV = os.path.join(LOG_DIR, f"latencies_{RUN_TAG}.csv")

os.makedirs(LOG_DIR, exist_ok=True)

_lock = threading.Lock()
_csv_file = open(OUT_CSV, "w", newline="")
_writer = csv.writer(_csv_file)
_writer.writerow(["latency_ms", "kind", "name", "ok", "timestamp"])

@events.request.add_listener
def log_request(request_type, name, response_time, response_length, response, context, exception, start_time, url, **kwargs):
    # response_time is milliseconds
    kind = (context or {}).get("kind", "UNKNOWN")
    ok = 1 if exception is None else 0
    ts = time.time()
    with _lock:
        _writer.writerow([response_time, kind, name, ok, ts])
        _csv_file.flush()


# ---------- Payload generators (must match ordering_flask/app.py validation) ----------
VALID_ITEMS = ["bread", "milk", "beef", "apples", "napkins", "cheese", "chicken", "tomato", "soda"]

def make_grocery_order():
    # Must be non-empty items dict
    items = {}
    for item in random.sample(VALID_ITEMS, k=random.randint(1, 3)):
        items[item] = random.randint(1, 3)
    return {
        "request_type": "GROCERY_ORDER",
        "id": f"cust{random.randint(1, 10_000_000)}",
        "items": items
    }

def make_restock_order():
    items = {}
    for item in random.sample(VALID_ITEMS, k=random.randint(1, 3)):
        items[item] = random.randint(3, 10)
    return {
        "request_type": "RESTOCK_ORDER",
        "id": f"truck{random.randint(1, 10_000_000)}",
        "items": items
    }


class GroceryLoad(HttpUser):
    # Controls spacing between requests per simulated user
    wait_time = between(0.05, 0.25)

    # Ratio (fridge more common than truck)
    FRIDGE_WEIGHT = int(os.getenv("FRIDGE_WEIGHT", "85"))  # 85%
    TRUCK_WEIGHT  = int(os.getenv("TRUCK_WEIGHT",  "15"))  # 15%

    @task(FRIDGE_WEIGHT)
    def refrigerator_request(self):
        payload = make_grocery_order()
        self.client.post(
            "/submit",
            json=payload,
            name="POST /submit (fridge)",
            context={"kind": "GROCERY_ORDER"},
            timeout=30,
        )

    @task(TRUCK_WEIGHT)
    def truck_request(self):
        payload = make_restock_order()
        self.client.post(
            "/submit",
            json=payload,
            name="POST /submit (truck)",
            context={"kind": "RESTOCK_ORDER"},
            timeout=30,
        )
