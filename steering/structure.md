---
inclusion: always
name: project-structure
description: File organization, naming conventions, and architectural patterns.
---

# Project Structure

## 1. Brevity
- Short is better. Fewer lines = lower maintenance.
- Duplicate trivial code (<10 lines) rather than fragmenting.

## 2. Classes as Containers
- Use classes exclusively as containers for vectorized/functional methods.
- No internal state complexity.
- No deep inheritance.

## 3. Iterators
- Use Iterators/Generators and List/Dict Comprehensions.
- Avoid `for` loops for data transformations.

## 4. Anti-SOLID
- No abstractions of abstractions.
- No interfaces, factories, or deep inheritance.
- No premature abstractions.