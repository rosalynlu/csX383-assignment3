FROM python:3.10-slim

WORKDIR /app

# Install dependencies
COPY robot/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy robot service main script
COPY services/robots/robot.py .

# Copy pre-generated Protobuf/gRPC stubs
COPY generated/ ./generated/

# Copy pre-generated FlatBuffers Python classes
COPY groceryfb/ ./groceryfb/

# Robot identity and connection config (override in K8s deployment per robot pod)
# ROBOT_NAME must be one of: bread, dairy, meat, produce, party
ENV ROBOT_NAME=bread
ENV ZMQ_SUB_ADDR=tcp://127.0.0.1:5556
ENV INVENTORY_ADDR=127.0.0.1:50051

# Robots are pure subscribers/clients — no inbound port to expose

CMD ["sh", "-c", "python robot.py --name ${ROBOT_NAME} --sub_addr ${ZMQ_SUB_ADDR} --inventory_addr ${INVENTORY_ADDR}"]
