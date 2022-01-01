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
    test('Emit null when absent cache, emit response after fetch', () async {
      final requester = SWRRequester(cache: <String, dynamic>{});
      final result = requester.fetch<TestResponse>(
        "/test_path1",
        createResponseFetcher("AfterFetch"),
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
      final cache = <String, dynamic>{
        "/test_path1": TestResponse(
          message: "CachedData",
        ),
      };
      final requester = SWRRequester(cache: cache);
      final result = requester.fetch<TestResponse>(
          "/test_path1", createResponseFetcher("AfterFetch"));

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
