# Makefile - data-eng-skill (Based on GlobalTask)
# Optimized for environments with Git/Bash (Windows/Linux)

VENV_DIR := .venv
# Tools that replace the need for Sonar and requirements files
DEV_TOOLS := ruff pytest pre-commit commitizen cz-conventional-gitmoji bandit detect-secrets pyupgrade polars "pyspark==3.5.3" python-dateutil

ifeq ($(OS),Windows_NT)
    BIN := $(VENV_DIR)\Scripts
    PYTHON := $(BIN)\python.exe
else
    BIN := $(VENV_DIR)/bin
    PYTHON := $(BIN)/python
endif

.PHONY: all setup test lint clean commit install-uv activate check install-java install-aws

# Default execution
all: setup

# Install Java 17 (required by PySpark 3.5)
install-java:
	@echo "--- Verifying Java 17+ ---"
	@if java -version 2>&1 | grep -q '"17\|"21\|"22'; then \
		echo "✅ Java 17+ already installed"; \
	else \
		echo "--- Installing Java 17 ---"; \
		if [ "$(OS)" = "Windows_NT" ]; then \
			winget install EclipseAdoptium.Temurin.17.JDK --accept-source-agreements --accept-package-agreements; \
		elif [ "$$(uname)" = "Darwin" ]; then \
			brew install --cask temurin@17 || brew install openjdk@17; \
		else \
			sudo apt-get update && sudo apt-get install -y openjdk-17-jdk || \
			sudo yum install -y java-17-amazon-corretto-devel; \
		fi; \
		echo "✅ Java 17 installed. Restart your terminal to update JAVA_HOME."; \
	fi

# Install AWS CLI v2
install-aws:
	@echo "--- Verifying AWS CLI ---"
	@if aws --version 2>/dev/null; then \
		echo "✅ AWS CLI already installed"; \
	else \
		echo "--- Installing AWS CLI v2 ---"; \
		if [ "$(OS)" = "Windows_NT" ]; then \
			winget install Amazon.AWSCLI --accept-source-agreements --accept-package-agreements; \
		elif [ "$$(uname)" = "Darwin" ]; then \
			brew install awscli; \
		else \
			curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip" && \
			unzip -o /tmp/awscliv2.zip -d /tmp && \
			sudo /tmp/aws/install --update && \
			rm -rf /tmp/awscliv2.zip /tmp/aws; \
		fi; \
		echo "✅ AWS CLI installed"; \
	fi

# Install uv if missing (crucial for setup speed)
install-uv:
	@uv --version > /dev/null 2>&1 || (echo "--- Installing uv ---" && curl -LsSf https://astral.sh/uv/install.sh | sh)

# Configure the ENTIRE environment intelligently (idempotent)
setup: install-uv install-java install-aws
	@if [ ! -d "$(VENV_DIR)" ]; then \
		echo "--- Creating venv ---" && \
		uv venv $(VENV_DIR) --python 3.12 --seed; \
	fi
	@echo "--- Installing/Updating tools ---"
	uv pip install $(DEV_TOOLS)
	@echo "--- Configuring Git hooks (Commit, Push, Message) ---"
	uv run pre-commit install
	uv run pre-commit install --hook-type commit-msg
	uv run pre-commit install --hook-type pre-push
	@echo ""
	@echo ">>> Setup finished. To activate the environment run: <<<"
ifeq ($(OS),Windows_NT)
	@echo "    PowerShell : .venv\Scripts\Activate.ps1"
	@echo "    CMD        : .venv\Scripts\activate.bat"
	@echo "    Git Bash   : source .venv/Scripts/activate"
else
	@echo "    source .venv/bin/activate"
endif

# Show the correct activation command
activate:
ifeq ($(OS),Windows_NT)
	@echo "source .venv/Scripts/activate"
else
	@echo "source .venv/bin/activate"
endif

# Run all pre-commit hooks on all files
check:
	@echo "--- Running pre-commit on all files ---"
	uv run pre-commit run --all-files

# Linter and Security
lint:
	@echo "--- [RUFF] Fixing style and logical errors ---"
	uv run ruff check . --fix --unsafe-fixes
	@echo "--- [RUFF] Applying code formatting ---"
	uv run ruff format .
	@echo "--- [BANDIT] Security scan (SAST) ---"
	uv run bandit -r architect/ developer/ -lll

# Unit tests
test:
	@echo "--- Running tests with pytest ---"
	@if [ -d "tests" ]; then \
		uv run pytest; \
	else \
		echo "No tests directory found."; \
	fi

# Standardized commit with Gitmoji
commit:
	@echo "--- Starting commitizen ---"
	uv run cz commit

# Total workspace cleanup
clean:
	@echo "--- Cleaning temporary files and venv ---"
	@if [ -d "$(VENV_DIR)" ]; then rm -rf $(VENV_DIR); fi
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type d -name ".pytest_cache" -exec rm -rf {} +
	find . -type d -name ".ruff_cache" -exec rm -rf {} +
	find . -type d -name ".secrets.baseline" -exec rm -rf {} +
