---
id: "arch:principles"
scope: "Framework for architectural decision-making and client alignment"
activation: "Use at the start of any project to align technical decisions with client needs"
---

# Client-First Architectural Principles

This framework prioritizes project success by aligning technical decisions with client constraints and resource optimization.

## Hierarchy of Priorities

When designing or modifying a solution, evaluate decisions against this hierarchy (1 is highest):

| Priority | Principle | Core Logic |
|:---|:---|:---|
| **1** | **Requirement Fulfillment** | The solution MUST meet the functional and non-functional requirements defined by the client first. |
| **2** | **Cost Optimization** | Seek the most economical architecture that fulfills requirements. Optimize memory usage and code quality. Disable unnecessary features. |
| **3** | **Security** | Implement essential security patterns (encryption, identity, access control) without over-engineering for the specific context. |
| **4** | **Technical Debt Reduction** | Prioritize maintainability and simplicity. The code must be easy to read and manage by any engineer (or AI). |
| **5** | **Vendor Lock-in Mitigation** | Favor open standards only when they don't aggressively increase technical debt or contradict client-allowed technologies. |

## Strategy for Resource Optimization (Priority 2)

- **Surgical Code:** Write only what is necessary.
- **Feature Pruning:** Identify and disable components or services that do not contribute to the primary objective.
- **Resource Efficiency:** Prioritize memory-efficient libraries and patterns (e.g., streaming over in-memory batch processing).

## Maintenance and Debt (Priority 4)

- **High Readability:** Use explicit logic over clever abstractions.
- **Standard Tooling:** Stick to the client's ecosystem or industry-standard tools unless there is a critical reason not to.
- **Documentation:** Ensure the *why* is documented close to the *what*.

## Technology Selection (Priority 5)

- **Client Guardrails:** Respect the list of approved technologies provided by the client.
- **Balanced Portability:** Do not trade high operational complexity for the sake of hypothetical future migrations unless requested.
