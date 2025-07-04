# Makefile for xk6-encoding

.PHONY: help build test test-verbose test-coverage benchmark clean install-xk6 lint fmt

# Default target
.DEFAULT_GOAL := help

# Variables
XK6_VERSION := latest
K6_VERSION := latest
EXTENSION_NAME := xk6-encoding
EXTENSION_URL := github.com/oleiade/xk6-encoding
OUTPUT_BINARY := k6
GO_PACKAGES := ./...

help: ## Show this help message
	@echo "Available targets:"
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-20s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

install-xk6: ## Install xk6 tool
	@echo "Installing xk6..."
	go install go.k6.io/xk6/cmd/xk6@$(XK6_VERSION)

build: install-xk6 ## Build k6 binary with xk6-encoding extension
	@echo "Building k6 with xk6-encoding extension..."
	xk6 build --with $(EXTENSION_URL)@latest
	@echo "Built k6 binary with xk6-encoding extension"

build-dev: install-xk6 ## Build k6 binary with local xk6-encoding extension (for development)
	@echo "Building k6 with local xk6-encoding extension..."
	xk6 build --with $(EXTENSION_URL)=.
	@echo "Built k6 binary with local xk6-encoding extension"

test: ## Run all tests
	@echo "Running tests..."
	go test $(GO_PACKAGES) -v

test-short: ## Run tests without verbose output
	@echo "Running tests (short)..."
	go test $(GO_PACKAGES)

test-verbose: ## Run tests with verbose output
	@echo "Running tests with verbose output..."
	go test $(GO_PACKAGES) -v

test-coverage: ## Run tests with coverage
	@echo "Running tests with coverage..."
	go test $(GO_PACKAGES) -cover -coverprofile=coverage.out
	@echo "Coverage report generated: coverage.out"

test-coverage-html: test-coverage ## Generate HTML coverage report
	@echo "Generating HTML coverage report..."
	go tool cover -html=coverage.out -o coverage.html
	@echo "HTML coverage report generated: coverage.html"

benchmark: ## Run benchmarks
	@echo "Running benchmarks..."
	go test $(GO_PACKAGES) -bench=. -benchmem

benchmark-verbose: ## Run benchmarks with verbose output
	@echo "Running benchmarks with verbose output..."
	go test $(GO_PACKAGES) -bench=. -benchmem -v

lint: ## Run linter
	@echo "Running linter..."
	golangci-lint run

fmt: ## Format Go code
	@echo "Formatting Go code..."
	go fmt $(GO_PACKAGES)

tidy: ## Tidy up go.mod
	@echo "Tidying up go.mod..."
	go mod tidy

vet: ## Run go vet
	@echo "Running go vet..."
	go vet $(GO_PACKAGES)

clean: ## Clean build artifacts
	@echo "Cleaning build artifacts..."
	rm -f $(OUTPUT_BINARY)
	rm -f coverage.out
	rm -f coverage.html

test-examples: build-dev ## Test examples with built k6 binary
	@echo "Testing examples with built k6 binary..."
	@if [ -f "./$(OUTPUT_BINARY)" ]; then \
		echo "Running encode.js example..."; \
		./$(OUTPUT_BINARY) run examples/encode.js; \
		echo "Running decode.js example..."; \
		./$(OUTPUT_BINARY) run examples/decode.js; \
		echo "Running encode-decode.js example..."; \
		./$(OUTPUT_BINARY) run examples/encode-decode.js; \
		echo "Running decode-chunked.js example..."; \
		./$(OUTPUT_BINARY) run examples/decode-chunked.js; \
	else \
		echo "Error: k6 binary not found. Run 'make build-dev' first."; \
		exit 1; \
	fi

# Composite targets
all: fmt vet lint test ## Run format, vet, lint, and tests

ci: fmt vet test-coverage ## Run CI pipeline (format, vet, test with coverage)

dev-setup: install-xk6 build-dev ## Setup development environment

# Check if required tools are installed
check-tools: ## Check if required tools are installed
	@echo "Checking required tools..."
	@command -v go >/dev/null 2>&1 || { echo "Go is required but not installed. Aborting." >&2; exit 1; }
	@command -v xk6 >/dev/null 2>&1 || { echo "xk6 is not installed. Run 'make install-xk6' first." >&2; exit 1; }
	@command -v golangci-lint >/dev/null 2>&1 || { echo "golangci-lint is not installed. Install it from https://golangci-lint.run/usage/install/" >&2; }
	@echo "All required tools are available."

# Debug target to show variables
debug: ## Show debug information
	@echo "XK6_VERSION: $(XK6_VERSION)"
	@echo "K6_VERSION: $(K6_VERSION)"
	@echo "EXTENSION_NAME: $(EXTENSION_NAME)"
	@echo "EXTENSION_URL: $(EXTENSION_URL)"
	@echo "OUTPUT_BINARY: $(OUTPUT_BINARY)"
	@echo "GO_PACKAGES: $(GO_PACKAGES)"
