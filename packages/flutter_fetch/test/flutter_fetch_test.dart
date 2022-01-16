import 'dart:io';

import 'package:flutter_fetch/flutter_fetch.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockserver/mockserver.dart';

import 'test_utilities/mock_server.dart';
import 'test_utilities/test_model.dart';

void main() {
  setUpAll(() async {
    final endPoints = <EndPoint>[
      TestEndpoint(
        methodType: MethodType.get,
        pathWithQueryParameter: '/test_path1',
        responseBody: TestResponse(message: 'AfterFetch').toJson(),
      ),
    ];

    final mockServer = MockServer(
      port: 18080,
      endPoints: endPoints,
    );
    await mockServer.start();
  });

  group('fetch', () {
    group('stream', () {
      test('Emit null when absent cache, emit response after fetch', () async {
        final requester = Requester(cache: <String, dynamic>{});
        final result = requester.fetch<TestResponse>(
          '/test_path1',
          createHttpRequestFetcher('AfterFetch'),
        );

        expect(
          result,
          emitsInAnyOrder(
            <Object?>[
              null,
              TestResponse(message: 'AfterFetch'),
            ],
          ),
        );
      });
      test(
          'Emit fallbackData when absent cache and fallbackData has benn set,'
          'emit response after fetch', () async {
        final requester = Requester();
        final result = requester.fetch<TestResponse>(
          '/test_path1',
          createHttpRequestFetcher('AfterFetch'),
          fallbackData: TestResponse(message: 'FallbackData'),
        );

        expect(
          result,
          emitsInAnyOrder(
            <Object>[
              TestResponse(message: 'FallbackData'),
              TestResponse(message: 'AfterFetch'),
            ],
          ),
        );
      });
      test('Emit cache when present cache, emit response after fetch',
          () async {
        final cache = <String, dynamic>{
          '/test_path1': TestResponse(
            message: 'CachedData',
          ),
        };
        final requester = Requester(cache: cache);
        final result = requester.fetch<TestResponse>(
            '/test_path1', createHttpRequestFetcher('AfterFetch'));

        expect(
          result,
          emitsInOrder(
            <Object>[
              TestResponse(message: 'CachedData'),
              TestResponse(message: 'AfterFetch'),
            ],
          ),
        );
      });
    });
    group('retry', () {
      test('Retry three times', () async {
        final requester = Requester(cache: <String, dynamic>{});
        final result = requester.fetch<TestResponse>(
          '/retry_test_path1',
          createRetryRequestFetcher('RetryAfterFetch', 5),
          maxRetryAttempts: 5,
          shouldRetry: true,
          onRetry: (_, exception) {
            return exception is HttpException;
          },
        );

        expect(
          result,
          emitsInOrder(
            <Object?>[
              null,
              TestResponse(message: 'RetryAfterFetch'),
            ],
          ),
        );
      });

      test('Throw error when retry count is insufficient', () async {
        final requester = Requester(cache: <String, dynamic>{});
        final result = requester.fetch<TestResponse>(
          '/retry_test_path1',
          createRetryRequestFetcher('RetryAfterFetch', 5),
          maxRetryAttempts: 4,
          shouldRetry: true,
          onRetry: (_, exception) {
            return exception is HttpException;
          },
        );

        expect(
          result,
          emitsInOrder(
            <Object?>[
              null,
              emitsError(predicate((e) => e is HttpException)),
            ],
          ),
        );
      });

      test('Throw error when onRetry logic is wrong', () async {
        final requester = Requester(cache: <String, dynamic>{});
        final result = requester.fetch<TestResponse>(
          '/retry_test_path1',
          createRetryRequestFetcher('RetryAfterFetch', 5),
          maxRetryAttempts: 5,
          shouldRetry: true,
          onRetry: (_, exception) {
            return false;
          },
        );

        expect(
          result,
          emitsInOrder(
            <Object?>[
              null,
              emitsError(predicate((e) => e is HttpException)),
            ],
          ),
        );
      });

      test('No retry when shouldRetry is disabled', () async {
        final requester = Requester(cache: <String, dynamic>{});
        final result = requester.fetch<TestResponse>(
          '/retry_test_path1',
          createRetryRequestFetcher('RetryAfterFetch', 3),
          shouldRetry: false,
          maxRetryAttempts: 3,
          onRetry: (_, exception) {
            return exception is HttpException;
          },
        );

        expect(
          result,
          emitsInOrder(
            <Object?>[
              null,
              emitsError(predicate((e) => e is HttpException)),
            ],
          ),
        );
      });

      test(
          'Throw error when maxRetryAttempts less than 0 and not specified onRetry',
          () async {
        final requester = Requester(cache: <String, dynamic>{});
        final result = requester.fetch<TestResponse>(
          '/retry_test_path1',
          createRetryRequestFetcher('RetryAfterFetch', 3),
          shouldRetry: true,
        );

        expect(
          result,
          emitsInOrder(
            <Object?>[
              null,
              emitsError(predicate((e) => e is ArgumentError)),
            ],
          ),
        );
      });

      test(
          'Throw error when maxRetryAttempts less than equal 0 and specified onRetry',
          () async {
        final requester = Requester(cache: <String, dynamic>{});
        final result = requester.fetch<TestResponse>(
          '/retry_test_path1',
          createRetryRequestFetcher('RetryAfterFetch', 3),
          shouldRetry: true,
          maxRetryAttempts: 0,
          onRetry: (_, exception) {
            return exception is HttpException;
          },
        );

        expect(
          result,
          emitsInOrder(
            <Object?>[
              null,
              emitsError(predicate((e) => e is ArgumentError)),
            ],
          ),
        );
      });

      test(
          'Throw error when maxRetryAttempts greater than equal 0 and not specified onRetry',
          () async {
        final requester = Requester(cache: <String, dynamic>{});
        final result = requester.fetch<TestResponse>(
          '/retry_test_path1',
          createRetryRequestFetcher('RetryAfterFetch', 3),
          shouldRetry: true,
          maxRetryAttempts: 1,
        );

        expect(
          result,
          emitsInOrder(
            <Object?>[
              null,
              emitsError(predicate((e) => e is ArgumentError)),
            ],
          ),
        );
      });
    });
  });
}
