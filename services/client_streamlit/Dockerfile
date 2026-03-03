FROM python:3.10-slim

WORKDIR /app

# Install deps
COPY services/client_streamlit/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy app
COPY services/client_streamlit/app.py .

EXPOSE 8501

CMD ["streamlit", "run", "app.py", "--server.address=0.0.0.0", "--server.port=8501"]
