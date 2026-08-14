# Detailed Error Handling Patterns & Worked Examples

This reference document provides extended patterns, implementation examples, and failure recovery strategies across Dart/Flutter, Python, and TypeScript.

---

## 1. Sealed Class Result Pattern (Dart 3+)

```dart
sealed class NetworkResult<T> {}

class NetworkSuccess<T> extends NetworkResult<T> {
  final T value;
  NetworkSuccess(this.value);
}

class NetworkError<T> extends NetworkResult<T> {
  final int statusCode;
  final String message;
  NetworkError(this.statusCode, this.message);
}

class NetworkOffline<T> extends NetworkResult<T> {}

// Usage in Repository
Future<NetworkResult<List<String>>> fetchItems() async {
  try {
    final response = await http.get(Uri.parse('https://api.example.com/items'));
    if (response.statusCode == 200) {
      return NetworkSuccess(parseItems(response.body));
    }
    return NetworkError(response.statusCode, 'Server returned failure');
  } on SocketException {
    return NetworkOffline();
  } catch (e) {
    return NetworkError(500, 'Unexpected exception: $e');
  }
}
```

---

## 2. Flutter UI Error Boundaries & Fallbacks

```dart
class AppErrorBoundary extends StatelessWidget {
  final Widget child;

  const AppErrorBoundary({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return Material(
        color: Colors.transparent,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Something went wrong: ${details.exceptionAsString()}',
              style: const TextStyle(color: Colors.redAccent),
            ),
          ),
        ),
      );
    };

    return child;
  }
}
```

---

## 3. Python Order Processing Example

```python
class ApplicationError(Exception):
    """Base application exception."""
    def __init__(self, message: str, code: str = "GENERIC_ERROR"):
        super().__init__(message)
        self.code = code

class ValidationError(ApplicationError):
    def __init__(self, message: str):
        super().__init__(message, code="VALIDATION_ERROR")

class NotFoundError(ApplicationError):
    def __init__(self, entity: str, entity_id: str):
        super().__init__(f"{entity} with ID {entity_id} not found", code="NOT_FOUND")

def process_order(order_id: str) -> dict:
    if not order_id:
        raise ValidationError("Order ID is required")
    
    try:
        # Simulate processing
        return {"status": "completed", "order_id": order_id}
    except ApplicationError:
        raise
    except Exception as e:
        raise ApplicationError("Internal order processing failure", code="INTERNAL_ERROR") from e
```
