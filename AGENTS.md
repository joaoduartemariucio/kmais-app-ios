# AGENTS.md

Guide for AI coding agents working on Kmais — an iOS app that tracks car and motorcycle
maintenance: fuel log, consumption, cost per km and service reminders.

## Commands

```bash
make ci            # everything CI runs, in order — must pass before handing work back
make format        # fix formatting
make lint          # SwiftLint, strict
make build         # build app + tests with coverage
make test          # unit tests
make coverage      # ≥ 80% of changed executable lines must be covered
```

Needs `swiftlint` and `swiftformat` (`brew install swiftlint swiftformat`).

## Architecture — do not break these

Pragmatic Clean Architecture in one target, folders as layers. Details: [docs/architecture.md](docs/architecture.md).

- `Domain/` imports **Foundation only**. Entities are `nonisolated` `Sendable` structs;
  calculations are pure functions and never read the clock.
- `Data/` is the only place that knows SwiftData. `@Model` types end in `Model`; a new one
  must be added to `KmaisSchema` **and** to the `presentation_no_data_types` rule in `.swiftlint.yml`.
- `Presentation/` talks to Domain protocols only. One `@MainActor @Observable` ViewModel per
  screen. No `@Query`.
- `App/AppDependencies` is the only place that creates concrete types.

## Conventions

- **No comments in Swift code.** The why goes in [docs/decisions.md](docs/decisions.md).
- Money is `Decimal`; distance and volume are `Double`.
- Form fields are `String` with a `NumberInput.Style`; validation is `[ValidationIssue]`,
  blocking (red) or warning (orange).
- Every user-facing string goes in `kmais-app-ios/Localizable.xcstrings` with its **pt-BR**
  translation.
- Swift 6 concurrency: zero warnings. Types that do not need the main actor are `nonisolated`.

## Tests

- Swift Testing (`@Suite`, `@Test`, `#expect`), never XCTest for unit tests.
- Domain calculations in `kmais-app-iosTests/Calculations/`, ViewModels in `ViewModels/`.
- Use the fakes in `kmais-app-iosTests/Fakes/` and `FixedDateProvider`; no test touches SwiftData.
- New or changed logic needs tests: the CI gate is 80% of changed lines
  (SwiftUI views and `App/` are excluded — see `.coverageignore`).

## Before handing work back

1. `make ci` passes.
2. `docs/decisions.md` has an entry for any choice a reader could not infer from the code.
3. Never commit, push or create branches unless the user asks.

## Agent workflow

This repo defines four Claude Code subagents in `.claude/agents/` — a car and motorcycle
expert, an iOS specialist, a reviewer and an executor. How and why they work together:
[docs/agents.md](docs/agents.md).
