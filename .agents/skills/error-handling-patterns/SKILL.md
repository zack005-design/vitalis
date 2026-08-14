---
name: error-handling-patterns
description: Master error handling patterns across languages including exceptions, Result types, error propagation, and graceful degradation to build resilient applications. Use when implementing error handling, designing APIs, or improving application reliability.
---

# Error Handling Patterns

Build resilient applications with robust error handling strategies that gracefully handle failures and provide excellent debugging experiences.

## When to Use This Skill
- Implementing error handling in new features or API layers.
- Designing error-resilient APIs and database access routines.
- Debugging production exceptions and unhandled state failures.
- Creating user-friendly error messages and developer log context.
- Implementing retry mechanisms, fallback strategies, and circuit breakers.

## Core Concepts

### 1. Error Handling Philosophies
- **Exceptions**: Traditional `try-catch` blocks for unexpected control flow disruptions.
- **Result Types**: Explicit functional `Result<Success, Failure>` objects (e.g. `Either` or sealed class `Result`).
- **Graceful Fallbacks**: Degrading functionality to offline or cached states without crashing the UI.

### 2. Error Categories
- **Recoverable Errors**: Network timeouts, missing local files, invalid user input, rate limits.
- **Unrecoverable Errors**: Out-of-memory errors, stack overflow, critical database corruption.

## Detailed Patterns & Deep Dives
Detailed pattern documentation lives in [`references/details.md`](references/details.md). Read that file when deep architectural context or specific language implementations are required.

## Best Practices
- **Fail Fast**: Validate inputs early before starting expensive calculations or database operations.
- **Preserve Context**: Include stack traces, metadata, timestamps, and parameters in caught errors.
- **Meaningful Messages**: Explain clearly *what happened* and *how to fix it*.
- **Don't Swallow Errors**: Never catch an exception with an empty block; log or re-throw intentionally.
- **Type-Safe Errors**: Define explicit exception classes (`AppException`, `ValidationError`, `NetworkException`).

## Code Example (Dart / Flutter Resilient Pattern)

```dart
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final String message;
  final Object? error;
  final StackTrace? stackTrace;
  const Failure(this.message, [this.error, this.stackTrace]);
}

Future<Result<T>> runCatching<T>(Future<T> Function() action, {required String fallbackMessage}) async {
  try {
    final result = await action();
    return Success(result);
  } catch (e, st) {
    // Log exception context
    debugPrint('Error: $fallbackMessage - $e\n$st');
    return Failure(fallbackMessage, e, st);
  }
}
```

## Common Pitfalls
- **Catching Too Broadly**: `catch (e)` hiding critical bugs or unexpected null pointers.
- **Empty Catch Blocks**: Silently ignoring errors and failing silently.
- **Logging & Re-throwing**: Logging an exception and re-throwing it without wrapping, creating duplicate logs.
- **Unchecked Async Errors**: Leaving futures or background tasks without error callbacks.
