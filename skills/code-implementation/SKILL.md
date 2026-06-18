---
id: "dev:core"
name: "Developer Implementation"
description: "HOW to implement code. Use when writing, refactoring, or implementing features. Reference steering/tech.md for tool patterns and steering/principles.md for principles."
scope: "Code implementation and quality"
activation: "When user asks to implement, write, or refactor code"
tags: [implementation, code, development]
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash]
---

# Developer Implementation Guide

HOW to implement code. For tooling, use devops subagent.

## Workflow

1. **Analyze requirements** → Define input/output
2. **Implement** → Follow code-conventions patterns
3. **Validate** → Run quality checks
4. **Document** → Commit with clear message

## Quality Checks

```bash
ruff check .
ruff format .
mypy .
```