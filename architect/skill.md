---
id: "arch:principles"
scope: "Framework for architectural decision-making and client alignment"
activation: "Use at the start of any project to align technical decisions with client needs"
---

# Client-First Architectural Principles

This framework prioritizes project success by aligning technical decisions with client constraints and resource optimization.

## Hierarchy of Priorities

When designing or modifying a solution, evaluate decisions against this hierarchy:

| Priority | Principle | Core Logic |
|:---|:---|:---|
| **1** | **Requirement Fulfillment** | The solution MUST be correct and meet functional/non-functional requirements first. |
| **2** | **Cost & Resource Optimization** | Optimize memory, speed, and service costs. Use lazy evaluation and pushdown optimizations. |
| **3** | **Technical Debt Reduction** | Prioritize maintainability, simplicity, and readability. Avoid over-engineering. |
| **4** | **Process Simplification** | Streamline workflows and minimize the number of external services/dependencies. |

## Strategy for Resource Optimization (Priority 2)

- **Lazy Evaluation:** Prefer lazy APIs (Polars LazyFrame, Spark DataFrames) to allow the engine to optimize the execution plan.
- **Pushdown Optimizations:** Ensure predicate and filter pushdowns are active to minimize data transfer.
- **Shuffle Reduction:** Limit or eliminate operations that trigger data shuffling across the network.
- **Broadcast Joins:** Use broadcast joins for small tables to avoid expensive shuffles.
- **Smart Caching:** Use cache/persist only when it reduces redundant computation and lowers total cost.
- **Surgical Code:** Write only what is necessary (YAGNI).

## Maintenance and Debt (Priority 4)

- **High Readability:** Use explicit logic over clever abstractions.
- **Standard Tooling:** Stick to the client's ecosystem or industry-standard tools unless there is a critical reason not to.
- **Documentation:** Ensure the *why* is documented close to the *what*.

## Technology Selection (Priority 5)

- **Client Guardrails:** Respect the list of approved technologies provided by the client.
- **Balanced Portability:** Do not trade high operational complexity for the sake of hypothetical future migrations unless requested.
