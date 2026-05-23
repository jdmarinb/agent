# Standard Project Makefile
# Adheres to: Minimalism, CLI-First, Zero-New-Ops

SHELL := /bin/bash

.PHONY: all install format lint secrets test check clean help

all: install check

help:
	@echo "Usage:"
	@echo "  make install  - Install dependencies"
	@echo "  make format   - Auto-format code"
	@echo "  make lint     - Lint with auto-fix"
	@echo "  make secrets  - Detect secrets"
	@echo "  make test     - Run tests with coverage"
	@echo "  make check    - Run all quality checks"
	@echo "  make clean    - Remove artifacts"

install:
	uv sync

format:
	uv run ruff format src/ tests/

lint:
	uv run ruff check --fix --unsafe-fixes src/ tests/

secrets:
	uv run detect-secrets scan

test:
	uv run pytest tests/ --cov=src --cov-report=term-missing

check: format lint secrets test

clean:
	rm -rf .pytest_cache .ruff_cache .coverage htmlcov dist build
	find . -type d -name "__pycache__" -exec rm -rf {} +
