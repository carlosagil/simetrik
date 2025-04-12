FROM node:18-alpine

WORKDIR /app

# Install dependencies
COPY src/dashboard_service/package*.json ./
RUN npm install

# Copy proto files
COPY src/protos/ protos/

# Generate gRPC code
RUN npm install -g grpc-tools
RUN grpc_tools_node_protoc \
  --js_out=import_style=commonjs,binary:. \
  --grpc_out=grpc_js:. \
  --proto_path=protos \
  protos/simetrik.proto

# Copy application files
COPY src/dashboard_service/ .

EXPOSE 50052 3000 8080

CMD ["node", "server.js"]