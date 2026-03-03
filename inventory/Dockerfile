FROM python:3.10-slim

WORKDIR /app

# Install dependencies
COPY inventory/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy inventory service main script
COPY services/inventory_grpc/server.py .

# Copy pre-generated Protobuf/gRPC stubs
COPY generated/ ./generated/

# Copy pre-generated FlatBuffers Python classes
COPY groceryfb/ ./groceryfb/

# Copy database helper utility
COPY utils/ ./utils/

# Default environment variables (override in K8s deployment)
ENV ZMQ_PUB_ADDR=tcp://0.0.0.0:5556
ENV PRICING_GRPC_ADDR=localhost:50053
ENV DB_HOST=localhost
ENV DB_PORT=5432
ENV DB_NAME=grocery_db
ENV DB_USER=admin
ENV DB_PASSWORD=

# gRPC port
EXPOSE 50051
# ZeroMQ PUB port (for robot subscribers)
EXPOSE 5556

CMD ["python", "server.py"]
