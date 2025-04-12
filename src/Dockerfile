FROM python:3.9-slim

RUN apt-get update && apt-get install -y netcat-openbsd && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY src/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY src/protos/ protos/

# Create nested directory structure for v1 proto
RUN mkdir -p simetrik/protos/v1

# Generate gRPC code with versioned Python path
RUN python -m grpc_tools.protoc \
    --proto_path=protos \
    --python_out=simetrik/protos/v1 \
    --grpc_python_out=simetrik/protos/v1 \
    protos/simetrik.proto

# Fix imports for the new nested structure
RUN sed -i 's/import simetrik_pb2/from simetrik.protos.v1 import simetrik_pb2/' simetrik/protos/v1/simetrik_pb2_grpc.py

# Create __init__.py files for Python package recognition
RUN touch simetrik/__init__.py && \
    touch simetrik/protos/__init__.py && \
    touch simetrik/protos/v1/__init__.py

COPY src/server/ server/

ENV PYTHONPATH=/app

CMD ["python", "-m", "server.server"]