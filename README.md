# Kiro - AI Development Agent

Minimalist toolbox for AI-assisted development following **Agent Skills Open Standard**.

## Structure

```
steering/              # WHAT (always loaded)
├── tech.md            # Technologies
├── code-conventions.md  # Structure + Coding standards
└── visual-style.md   # UI/UX when needed

skills/                # HOW (on-demand)
├── architect-decisions/
├── project-setup/
├── knowledge-base/
├── migration/
├── logging/
└── skill-design/

agents/                # ROLES
├── architect.jsonc
├── developer.jsonc
└── devops.jsonc
```

## Roles

| Role | Responsibility | Skills |
|------|----------------|--------|
| **Architect** | Understand need → Generate specs → Design system | architect-decisions |
| **Developer** | Implement code following specs | project-setup, migration, logging |
| **DevOps** | CI/CD, hooks, boilerplates | project-setup |

## Steering by Role

- **Architect:** tech.md, code-conventions.md, visual-style.md
- **Developer:** tech.md, code-conventions.md
- **DevOps:** tech.md, code-conventions.md

## Priority Hierarchy

1. Solve client problem/need
2. Resource optimization (memory, speed, costs)
3. Reduce technical debt (minimalism, KISS, YAGNI, DRY)
4. Maintain consistency and standards

## Communication Style

- Short, direct, assertive responses
- NO emojis