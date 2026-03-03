FROM python:3.10-slim

WORKDIR /app

# Install dependencies
COPY pricing/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy pricing service main script
COPY services/pricing_grpc/server.py .

# Copy pre-generated Protobuf/gRPC stubs
COPY generated/ ./generated/

# Copy database helper utility
COPY utils/ ./utils/

# Default environment variables (override in K8s deployment)
ENV DB_HOST=localhost
ENV DB_PORT=5432
ENV DB_NAME=grocery_db
ENV DB_USER=admin
ENV DB_PASSWORD=

# gRPC port
EXPOSE 50053

CMD ["python", "server.py"]
