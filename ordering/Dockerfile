FROM python:3.10-slim

WORKDIR /app

# Install dependencies
COPY ordering/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy ordering service main script
COPY services/ordering_flask/app.py .

# Copy pre-generated Protobuf/gRPC stubs
COPY generated/ ./generated/

# Flask configuration
ENV FLASK_APP=app.py
ENV INVENTORY_ADDR=localhost:50051

# Flask HTTP port
EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')" || exit 1

CMD ["flask", "run", "--host=0.0.0.0", "--port=5000"]
