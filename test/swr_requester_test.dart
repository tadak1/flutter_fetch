import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockserver/mockserver.dart';
import 'package:swr_requester/swr_requester.dart';

import 'test_utilities/mock_server.dart';
import 'test_utilities/test_model.dart';

void main() {
  setUpAll(() async {
    final List<EndPoint> endPoints = [
      TestEndpoint(
        methodType: MethodType.get,
        pathWithQueryParameter: '/test_path1',
        responseBody: TestResponse(message: "AfterFetch").toJson(),
      ),
    ];

    final MockServer mockServer = MockServer(
      port: 18080,
      endPoints: endPoints,
    );
    await mockServer.start();
  });

  group("fetch", () {
    group("stream", () {
      test('Emit null when absent cache, emit response after fetch', () async {
        final requester = SWRRequester(cache: <String, dynamic>{});
        final result = requester.fetch<TestResponse>(
          "/test_path1",
          createHttpRequestFetcher("AfterFetch"),
        );

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
        final requester = SWRRequester();
        final result = requester.fetch<TestResponse>(
          "/test_path1",
          createHttpRequestFetcher("AfterFetch"),
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
      test('Emit cache when present cache, emit response after fetch',
          () async {
        final cache = <String, dynamic>{
          "/test_path1": TestResponse(
            message: "CachedData",
          ),
        };
        final requester = SWRRequester(cache: cache);
        final result = requester.fetch<TestResponse>(
            "/test_path1", createHttpRequestFetcher("AfterFetch"));

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
    group("retry", () {
      test("Retry three times", () async {
        final requester = SWRRequester(cache: {});
        final result = requester.fetch<TestResponse>(
          "/retry_test_path1",
          createRetryRequestFetcher("RetryAfterFetch", 5),
          maxRetryAttempts: 5,
          shouldRetry: true,
          onRetry: (_, exception) {
            return exception is HttpException;
          },
        );

        expect(
          result,
          emitsInOrder(
            [
              null,
              TestResponse(message: "RetryAfterFetch"),
            ],
          ),
        );
      });

      test("Throw error when retry count is insufficient", () async {
        final requester = SWRRequester(cache: {});
        final result = requester.fetch<TestResponse>(
          "/retry_test_path1",
          createRetryRequestFetcher("RetryAfterFetch", 5),
          maxRetryAttempts: 4,
          shouldRetry: true,
          onRetry: (_, exception) {
            return exception is HttpException;
          },
        );

        expect(
          result,
          emitsInOrder(
            [
              null,
              emitsError(predicate((e) => e is HttpException)),
            ],
          ),
        );
      });

      test("Throw error when onRetry logic is wrong", () async {
        final requester = SWRRequester(cache: {});
        final result = requester.fetch<TestResponse>(
          "/retry_test_path1",
          createRetryRequestFetcher("RetryAfterFetch", 5),
          maxRetryAttempts: 5,
          shouldRetry: true,
          onRetry: (_, exception) {
            return false;
          },
        );

        expect(
          result,
          emitsInOrder(
            [
              null,
              emitsError(predicate((e) => e is HttpException)),
            ],
          ),
        );
      });

      test("No retry when shouldRetry is disabled", () async {
        final requester = SWRRequester(cache: {});
        final result = requester.fetch<TestResponse>(
          "/retry_test_path1",
          createRetryRequestFetcher("RetryAfterFetch", 3),
          shouldRetry: false,
          maxRetryAttempts: 3,
          onRetry: (_, exception) {
            return exception is HttpException;
          },
        );

        expect(
          result,
          emitsInOrder(
            [
              null,
              emitsError(predicate((e) => e is HttpException)),
            ],
          ),
        );
      });
    });
  });
}
