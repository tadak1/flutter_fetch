import 'package:flutter_test/flutter_test.dart';
import 'package:swr_requester/swr_requester.dart';

class TestResponse {
  TestResponse({
    required this.message,
  });

  String message;

  @override
  bool operator ==(Object other) {
    return other is TestResponse && other.message == message;
  }

  @override
  String toString() {
    return "TestResponse("
        "message: $message"
        ")";
  }

  @override
  int get hashCode => message.hashCode;
}

Fetcher<TestResponse> createResponseFetcher(String message) {
  return (String uri) async {
    return TestResponse(message: message);
  };
}

void main() {
  group("fetch", () {
    test('Emit null when absent cache, emit response after fetch', () async {
      final result = fetch<TestResponse>(
          "/test_path1", createResponseFetcher("AfterFetch"));

      expect(
        result,
        emitsInAnyOrder(
          [
            null,
            TestResponse(message: "AfterFetch"),
          ],
        ),
      );
    });
    test(
        'Emit fallbackData when absent cache and fallbackData has benn set, emit response after fetch',
        () async {
      final result = fetch<TestResponse>(
        "/test_path2",
        createResponseFetcher("AfterFetch"),
        fallbackData: TestResponse(message: "FallbackData"),
      );

      expect(
        result,
        emitsInAnyOrder(
          [
            TestResponse(message: "FallbackData"),
            TestResponse(message: "AfterFetch"),
          ],
        ),
      );
    });
    test('Emit cache when present cache, emit response after fetch', () async {
      await for (var _ in fetch<TestResponse>(
          "/test_path3", createResponseFetcher("CachedData"))) {}
      final result = fetch<TestResponse>(
          "/test_path3", createResponseFetcher("AfterFetch"));

      expect(
        result,
        emitsInOrder(
          [
            TestResponse(message: "CachedData"),
            TestResponse(message: "AfterFetch"),
          ],
        ),
      );
    });
  });
}
