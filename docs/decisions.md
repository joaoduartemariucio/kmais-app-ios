# Decisions

Short record of choices that are not obvious from the code. Each one says what was decided,
why, and what it costs. Newest first within each group.

## Data entry

### Odometer out of order is a warning, not an error

When the odometer typed in a fuel-up or service does not fit between the previous and the
next record (by date), the form shows an orange note — "the next record has 56,000 km;
saving this changes the vehicle's history" — and still lets the user save.

- **Why:** people log old receipts, fix typos and register a car after the fact. Blocking
  the save made editing old records impossible.
- **Cost:** the history can hold inconsistent readings. Domain already copes:
  `Consumption.anomalies(in:)` flags them and they are left out of consumption stats.

### Numeric fields are digit-shifting masks

Typing fills from the right, like banking apps: `5899` becomes `R$ 5,899`. Each field has
a `NumberInput.Style`:

| Style | Fraction digits | Used for |
|---|---|---|
| `.kilometers`, `.months` | 0 | odometer, rule intervals |
| `.liters` | 2 | liters, tank capacity |
| `.fuelPrice` | 3 | price per liter (pumps in Brazil charge in 3 decimals) |
| `.money` | 2 | service cost |

- **Why:** a plain number pad is enough (no decimal separator to type or get wrong), the
  value is always shown formatted for the locale, and parsing is just
  `digits / 10^fractionDigits` — identical in any locale.
- **Cost:** the caret always sits at the end; editing in the middle of a number is not
  supported. Deleting a non-digit (a trailing currency symbol) removes the last digit.

### Keyboard closes on tap outside, scroll or "Done"

`.dismissesKeyboard()` on each form adds `scrollDismissesKeyboard`, a "Done" button above
the keyboard (the number pad has no return key) and a window-level tap recognizer.

- **Why:** SwiftUI has no reliable "tap outside" that doesn't also fire when tapping
  another field. The UIKit recognizer ignores touches on text inputs and does not cancel
  touches, so buttons and toggles keep working.
- **Cost:** once installed, the recognizer stays on the window for the whole app.

## Quality gates

### Coverage is checked on changed lines, not on the whole project

CI requires 80% of the executable lines added or modified by a change to run in tests
(see [CI](ci.md#coverage-of-changed-lines)). SwiftUI views and app wiring are left out via
`.coverageignore`.

- **Why:** a global threshold either blocks everything from day one or is set so low it
  means nothing. Checking new code raises coverage with every change and puts the cost on
  whoever writes the code, while it is still fresh.
- **Cost:** old untested code only gets tests when someone touches it — refactors and even
  reformatting pull those lines into the check. The ignore list needs judgment: a view that
  grows real logic should move it to its ViewModel rather than stay excluded.

### SwiftFormat with community defaults

The formatter runs on defaults, with options pinned only where defaults are ambiguous or
clash with SwiftLint ([CI](ci.md#format--swiftformat)). Formatting is checked, never
discussed in review.

## Architecture

### Layers as folders in one target, guarded by lint

- **Why:** one developer, one app target. Separate modules would add build and target
  maintenance for little gain today.
- **Cost:** the compiler can't stop `Presentation` from using a `Data` type; a name-based
  lint rule does, and its list is manual.
- **Revisit when:** a second target (widget, App Intents, watchOS) needs the same data —
  then `Domain` and `Data` become Swift packages.

### No `@Query`

- **Why:** `@Query` puts `@Model` types in views and erases the Data/Presentation boundary.
- **Cost:** ViewModels reload after every write; a change made elsewhere shows up on the
  next load. Fine for a single-user, offline app.
- **Revisit when:** iOS 27's `ResultsObserver` is available — it fits inside the
  repositories behind an additive `observe…() -> AsyncStream` method, with no protocol changes.

### No use-case layer

- **Why:** most use cases would be one-line pass-throughs to a repository. Business rules
  live in `Domain/Calculations` and are tested there.
- **Revisit when:** the same flow is triggered from three or more screens, or one operation
  has to coordinate several repositories consistently.

### CloudKit-ready schema, sync off

No unique constraints and optional relationships, as CloudKit requires. Turning sync on
later should not need a migration. The cost: uniqueness of `id` is not enforced by the
store (`fetchByID` asserts in debug), and orphan records are possible (mappers drop and log them).

## Calculations

### Money is `Decimal`; distance and volume are `Double`

Prices and totals never go through floating-point arithmetic.
`Decimal(approximating:)` converts a `Double` through its shortest string form, so
`0.1` stays `0.1`.

### Consumption only between full tanks

A km/L value needs a full tank at both ends; partial fill-ups in between add their liters
to the interval. Entries with non-positive liters are skipped entirely and reported as
anomalies.

### Forecasts are deterministic

`Maintenance.forecast` never reads the clock; the latest reading is "now". The next
service is the earlier of the distance-based date (from the vehicle's km/day pace) and
the calendar-based date. Months use `365.25 / 12` days only when shown to the user.

### The current odometer is the most recent reading, not the highest

A reading that goes backwards is bad data; returning the maximum would hide it.

## Status

- **Service reminders:** `ReminderScheduler` and its `UserNotifications` implementation
  exist, but no screen schedules notifications yet.
