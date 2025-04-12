.PHONY: build up down restart logs clean ps proto help

# Default target
help:
	@echo "Available commands:"
	@echo "  make build    - Build all services"
	@echo "  make up       - Start all services"
	@echo "  make down     - Stop all services"
	@echo "  make restart  - Restart all services"
	@echo "  make logs     - Show logs from all services"
	@echo "  make clean    - Stop and remove all containers, images, and volumes"
	@echo "  make ps       - Show running services"
	@echo "  make proto    - Generate protobuf files locally"
	@echo ""
	@echo "Service-specific commands:"
	@echo "  make logs-server      - Show logs from server"
	@echo "  make logs-transaction - Show logs from transaction service"
	@echo "  make logs-dashboard   - Show logs from dashboard service"

# Build all services
build:
	docker-compose build --no-cache

# Start all services
up:
	docker-compose up -d

# Start all services with logs
up-logs:
	docker-compose up

# Stop all services
down:
	docker-compose down

# Restart all services
restart:
	docker-compose restart

# Show logs from all services
logs:
	docker-compose logs -f

# Show logs for specific services
logs-server:
	docker-compose logs -f server

logs-transaction:
	docker-compose logs -f transaction

logs-dashboard:
	docker-compose logs -f dashboard

# Clean everything
clean:
	docker-compose down --rmi all --volumes --remove-orphans

# Show running services
ps:
	docker-compose ps

# Generate protobuf files locally
proto:
	python -m grpc_tools.protoc \
		--proto_path=protos/ \
		--python_out=. \
		--grpc_python_out=. \
		protos/simetrik.proto

# Build and start services
deploy: build up

# Stop and clean everything, then rebuild and start
redeploy: clean deploy
