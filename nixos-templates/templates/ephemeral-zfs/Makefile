.PHONY: all check format test clean install-hooks

all: check

# Install pre-commit hooks
install-hooks:
	pre-commit install
	@echo "Pre-commit hooks installed!"

# Format all Nix files with alejandra
format:
	@echo "Formatting Nix files..."
	@find . -name "*.nix" -not -path "./.git/*" -exec alejandra {} \;
	@echo "Formatting shell scripts..."
	@find . -name "*.sh" -not -path "./.git/*" -exec shfmt -w {} \;

# Run all checks
check: format lint test
	@echo "All checks passed!"

# Lint files
lint:
	@echo "Running Nix static analysis..."
	@find . -name "*.nix" -not -path "./.git/*" -exec statix check {} \; || true
	@echo "Checking for dead code..."
	@find . -name "*.nix" -not -path "./.git/*" -exec deadnix {} \; || true
	@echo "Running shellcheck..."
	@find . -name "*.sh" -not -path "./.git/*" -not -path "./tests/*" -exec shellcheck {} \;
	@echo "Checking Nix syntax..."
	@find . -name "*.nix" -not -path "./.git/*" -not -name "flake.nix" -not -name "configuration.nix" \
		-exec nix-instantiate --parse {} \; > /dev/null

# Run test suite
test:
	@echo "Running test suite..."
	@bash tests/run-all-tests.sh

# Build test configurations
build-test:
	@echo "Building test configuration..."
	@nix build .#nixosConfigurations.test-physical.config.system.build.toplevel --dry-run
	@nix build .#nixosConfigurations.test-vm.config.system.build.toplevel --dry-run

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf result result-*
	@rm -rf .pre-commit-cache

# Check a specific file
check-file:
	@if [ -z "$(FILE)" ]; then \
		echo "Usage: make check-file FILE=path/to/file.nix"; \
		exit 1; \
	fi
	@echo "Checking $(FILE)..."
	@alejandra $(FILE)
	@statix check $(FILE) || true
	@deadnix $(FILE) || true
	@if [[ "$(FILE)" == *.sh ]]; then shellcheck $(FILE); fi

# Pre-commit dry run
pre-commit-test:
	@pre-commit run --all-files

# Help
help:
	@echo "NixOS ZFS Makefile"
	@echo "=================="
	@echo "  make install-hooks  - Install git pre-commit hooks"
	@echo "  make format        - Format all code"
	@echo "  make check         - Run all checks (format, lint, test)"
	@echo "  make lint          - Run linters only"
	@echo "  make test          - Run test suite"
	@echo "  make build-test    - Build test configurations"
	@echo "  make clean         - Clean build artifacts"
	@echo "  make check-file FILE=<path> - Check a specific file"
	@echo "  make pre-commit-test - Test pre-commit hooks"