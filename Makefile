# Makefile - data-eng-skill (Based on GlobalTask)
# Optimizado para entornos con Git/Bash (Windows/Linux)

VENV_DIR := .venv
# Herramientas que sustituyen la necesidad de Sonar y archivos de requerimientos
DEV_TOOLS := ruff pytest pre-commit commitizen cz-conventional-gitmoji bandit detect-secrets pyupgrade polars "pyspark==3.5.3" python-dateutil

ifeq ($(OS),Windows_NT)
    BIN := $(VENV_DIR)\Scripts
    PYTHON := $(BIN)\python.exe
else
    BIN := $(VENV_DIR)/bin
    PYTHON := $(BIN)/python
endif

.PHONY: all setup test lint clean commit install-uv activate check install-java install-aws

# Ejecución por defecto
all: setup

# Instala Java 17 (requerido por PySpark 3.5)
install-java:
	@echo "--- Verificando Java 17+ ---"
	@if java -version 2>&1 | grep -q '"17\|"21\|"22'; then \
		echo "✅ Java 17+ ya instalado"; \
	else \
		echo "--- Instalando Java 17 ---"; \
		if [ "$(OS)" = "Windows_NT" ]; then \
			winget install EclipseAdoptium.Temurin.17.JDK --accept-source-agreements --accept-package-agreements; \
		elif [ "$$(uname)" = "Darwin" ]; then \
			brew install --cask temurin@17 || brew install openjdk@17; \
		else \
			sudo apt-get update && sudo apt-get install -y openjdk-17-jdk || \
			sudo yum install -y java-17-amazon-corretto-devel; \
		fi; \
		echo "✅ Java 17 instalado. Reinicia tu terminal para que JAVA_HOME se actualice."; \
	fi

# Instala AWS CLI v2
install-aws:
	@echo "--- Verificando AWS CLI ---"
	@if aws --version 2>/dev/null; then \
		echo "✅ AWS CLI ya instalado"; \
	else \
		echo "--- Instalando AWS CLI v2 ---"; \
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
		echo "✅ AWS CLI instalado"; \
	fi

# Instala uv si no está (crucial para la velocidad del setup)
install-uv:
	@uv --version > /dev/null 2>&1 || (echo "--- Installing uv ---" && curl -LsSf https://astral.sh/uv/install.sh | sh)

# Configura TODO el entorno de forma inteligente (idempotente)
setup: install-uv install-java install-aws
	@if [ ! -d "$(VENV_DIR)" ]; then \
		echo "--- Creando venv ---" && \
		uv venv $(VENV_DIR) --python 3.12 --seed; \
	fi
	@echo "--- Instalando/Actualizando herramientas ---"
	uv pip install $(DEV_TOOLS)
	@echo "--- Configurando hooks de Git (Commit, Push, Message) ---"
	uv run pre-commit install
	uv run pre-commit install --hook-type commit-msg
	uv run pre-commit install --hook-type pre-push
	@echo ""
	@echo ">>> Setup terminado. Para activar el entorno corre: <<<"
ifeq ($(OS),Windows_NT)
	@echo "    PowerShell : .venv\Scripts\Activate.ps1"
	@echo "    CMD        : .venv\Scripts\activate.bat"
	@echo "    Git Bash   : source .venv/Scripts/activate"
else
	@echo "    source .venv/bin/activate"
endif

# Muestra el comando de activación correcto
activate:
ifeq ($(OS),Windows_NT)
	@echo "source .venv/Scripts/activate"
else
	@echo "source .venv/bin/activate"
endif

# Corre todos los hooks de pre-commit sobre todos los archivos
check:
	@echo "--- Corriendo pre-commit sobre todos los archivos ---"
	uv run pre-commit run --all-files

# Linter y Seguridad
lint:
	@echo "--- [RUFF] Corrigiendo estilo y errores lógicos ---"
	uv run ruff check . --fix --unsafe-fixes
	@echo "--- [RUFF] Aplicando formato de código ---"
	uv run ruff format .
	@echo "--- [BANDIT] Escaneo de seguridad (SAST) ---"
	uv run bandit -r architect/ developer/ -lll

# Pruebas unitarias
test:
	@echo "--- Ejecutando tests con pytest ---"
	@if [ -d "tests" ]; then \
		uv run pytest; \
	else \
		echo "No tests directory found."; \
	fi

# Commit estandarizado con Gitmoji
commit:
	@echo "--- Iniciando commitizen ---"
	uv run cz commit

# Limpieza total del espacio de trabajo
clean:
	@echo "--- Limpiando archivos temporales y venv ---"
	@if [ -d "$(VENV_DIR)" ]; then rm -rf $(VENV_DIR); fi
	find . -type d -name "__pycache__" -exec rm -rf {} +
	find . -type d -name ".pytest_cache" -exec rm -rf {} +
	find . -type d -name ".ruff_cache" -exec rm -rf {} +
	find . -type d -name ".secrets.baseline" -exec rm -rf {} +
