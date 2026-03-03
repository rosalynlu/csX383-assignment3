import streamlit as st
import requests
import os

# ------------------------------------------------------------
# Grocery Store Streamlit Client
#
# Purpose:
#   - Provide a simple browser UI for Grocery and Restock orders
#   - Send the order request as HTTP+JSON to the Ordering Flask service
#   - Display the JSON response returned by Ordering
# ------------------------------------------------------------

st.set_page_config(page_title="Grocery Store Client", layout="centered")
st.title("CSX383 PA1 — Grocery Store Client (Streamlit)")
st.caption("This client sends HTTP+JSON to the Ordering (Flask) service.")

# URL of the Ordering microservice (Flask)
default_url = os.getenv("ORDERING_SERVICE_URL", "http://localhost:5000")
ordering_url = st.text_input(
    "Ordering Service URL",
    f"{default_url}/submit"
)

# User selects whether this is a grocery order or a restock request
request_type = st.selectbox("Request Type", ["GROCERY_ORDER", "RESTOCK_ORDER"])

# ID field depends on request type (customer vs supplier)
id_label = "Customer ID" if request_type == "GROCERY_ORDER" else "Supplier ID"
id_value = st.text_input(id_label)

# Catalog
st.subheader("Items (enter qty > 0)")
items_catalog = [
    "bread", "milk", "eggs",
    "chicken", "beef",
    "apples", "bananas",
    "soda", "napkins"
]

# Collect item quantities into a dictionary
items = {}
for name in items_catalog:
    qty = st.number_input(f"{name} qty", min_value=0, step=1, value=0)
    if qty > 0:
        items[name] = qty

# JSON payload sent to Ordering service
payload = {"request_type": request_type, "id": id_value, "items": items}

st.subheader("Preview JSON payload")
st.json(payload)

# When user clicks Submit, POST request is sent to Flask Ordering service
if st.button("Submit"):

    # Validation
    if not ordering_url.strip():
        st.error("Ordering Service URL is required.")
        st.stop()
    if not id_value.strip():
        st.error(f"{id_label} is required.")
        st.stop()
    if not items:
        st.error("Add at least one item with qty > 0.")
        st.stop()

    # Send HTTP POST JSON request to Ordering service
    try:
        resp = requests.post(ordering_url, json=payload, timeout=8)
        st.write("HTTP status:", resp.status_code)

        # Display response from Ordering service
        try:
            st.subheader("Response (JSON)")
            st.json(resp.json())
        except Exception:
            st.subheader("Response (Text)")
            st.code(resp.text)

    except requests.exceptions.RequestException as e:
        st.error(f"Request failed: {e}")
        st.info("Common causes: Ordering service not running, wrong URL/port, VM IP mismatch.")
