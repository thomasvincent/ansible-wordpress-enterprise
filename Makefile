.PHONY: help build test lint clean docker-test install galaxy-install

help:
	@echo "Available commands:"
	@echo "  make install          - Install Ansible and dependencies"
	@echo "  make galaxy-install   - Install Ansible Galaxy collections"
	@echo "  make lint             - Run linters (yamllint, ansible-lint)"
	@echo "  make test             - Run Molecule tests"
	@echo "  make docker-build     - Build Docker test images"
	@echo "  make docker-test      - Run tests in Docker containers"
	@echo "  make docker-dev       - Start development environment"
	@echo "  make docker-clean     - Clean Docker resources"
	@echo "  make clean            - Clean temporary files"

install:
	@echo "Installing Ansible and dependencies..."
	pip install --upgrade pip
	pip install ansible>=2.14 ansible-lint yamllint molecule molecule-plugins[docker] pytest-testinfra

galaxy-install:
	@echo "Installing Ansible Galaxy collections..."
	ansible-galaxy collection install community.general
	ansible-galaxy collection install community.mysql
	ansible-galaxy collection install ansible.posix

lint:
	@echo "Running linters..."
	yamllint .
	ansible-lint

test:
	@echo "Running Molecule tests..."
	molecule test

docker-build:
	@echo "Building Docker images..."
	docker-compose build ubuntu-22 ubuntu-24 rocky-9

docker-test:
	@echo "Running tests in Docker..."
	docker-compose run --rm molecule

docker-dev:
	@echo "Starting development environment..."
	docker-compose up -d wordpress-dev mysql redis mailhog
	@echo ""
	@echo "Services available:"
	@echo "  WordPress: http://localhost:8080"
	@echo "  MySQL: localhost:3307"
	@echo "  Redis: localhost:6380"
	@echo "  MailHog: http://localhost:8025"
	@echo ""
	@echo "To access WordPress container:"
	@echo "  docker-compose exec wordpress-dev bash"

docker-logs:
	docker-compose logs -f wordpress-dev

docker-stop:
	docker-compose down

docker-clean:
	@echo "Cleaning Docker resources..."
	docker-compose down -v
	docker system prune -f

clean:
	@echo "Cleaning temporary files..."
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type f -name "*.pyc" -delete
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".tox" -exec rm -rf {} + 2>/dev/null || true
	rm -rf molecule/default/.molecule

# Development shortcuts
dev: docker-dev

stop: docker-stop

logs: docker-logs

shell:
	docker-compose exec wordpress-dev bash

mysql-shell:
	docker-compose exec mysql mysql -uroot -proot wordpress

redis-cli:
	docker-compose exec redis redis-cli
