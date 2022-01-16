import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_fetch_hooks/src/flutter_fetch_hooks.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

class TestResponse {
  TestResponse({
    required this.message,
  });

  factory TestResponse.fromJson(Map<String, dynamic> json) {
    return TestResponse(
      message: json['message'] as String,
    );
  }

  String message;

  @override
  bool operator ==(Object other) {
    return other is TestResponse && other.message == message;
  }

  @override
  String toString() {
    return 'TestResponse('
        'message: $message'
        ')';
  }

  Map<String, Object> toJson() {
    return <String, Object>{
      'message': message,
    };
  }

  @override
  int get hashCode => message.hashCode;
}

void main() {
  group("hooks", () {
    testWidgets('Show loading text and fetched text when no cache',
        (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          HookBuilder(builder: (context) {
            final response = useSWRRequest(
              "/test_path1",
              (path) async {
                await Future.delayed(const Duration(seconds: 1));
                return TestResponse(message: 'FetchedData');
              },
              cache: {},
            );

            return response.when(data: (response) {
              return Text(
                "${response?.message}",
                textDirection: TextDirection.ltr,
              );
            }, error: (exception, trace) {
              final error = exception as HttpException?;
              return Text(
                error?.message ?? "",
                textDirection: TextDirection.ltr,
              );
            }, loading: () {
              return const Text(
                "Loading",
                textDirection: TextDirection.ltr,
              );
            });
          }),
        );

        expect(find.text("Loading"), findsOneWidget);
        await Future.delayed(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        expect(find.text("FetchedData"), findsOneWidget);
      });
    });

    testWidgets(
        'Show loading text and cached text and fetched text when exists stale data',
        (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          HookBuilder(builder: (context) {
            final response = useSWRRequest("/test_path1", (path) async {
              await Future.delayed(const Duration(seconds: 1));
              return TestResponse(message: 'FetchedData');
            }, cache: <String, dynamic>{
              '/test_path1': TestResponse(
                message: 'CachedData',
              ),
            });
            return response.when(data: (response) {
              return Text(
                "${response?.message}",
                textDirection: TextDirection.ltr,
              );
            }, error: (exception, trace) {
              final error = exception as HttpException?;
              return Text(
                error?.message ?? "",
                textDirection: TextDirection.ltr,
              );
            }, loading: () {
              return const Text(
                "Loading",
                textDirection: TextDirection.ltr,
              );
            });
          }),
        );

        expect(find.text("Loading"), findsOneWidget);
        await tester.pumpAndSettle();
        expect(find.text("CachedData"), findsOneWidget);
        await Future.delayed(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        expect(find.text("FetchedData"), findsOneWidget);
      });
    });

    testWidgets('Show loading text and error text when throw exception',
        (tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
          HookBuilder(builder: (context) {
            final response = useSWRRequest<TestResponse?>(
              "/test_path1",
              (path) async {
                await Future.delayed(const Duration(seconds: 1));
                throw const HttpException("Connection Error");
              },
              cache: {},
              shouldRetry: false,
            );
            return response.when(data: (response) {
              return Text(
                "${response?.message}",
                textDirection: TextDirection.ltr,
              );
            }, error: (exception, trace) {
              final error = exception as HttpException?;
              return Text(
                error?.message ?? "",
                textDirection: TextDirection.ltr,
              );
            }, loading: () {
              return const Text(
                "Loading",
                textDirection: TextDirection.ltr,
              );
            });
          }),
        );

        expect(find.text("Loading"), findsOneWidget);
        await Future.delayed(const Duration(seconds: 1));
        await tester.pumpAndSettle();
        expect(find.text("Connection Error"), findsOneWidget);
      });
    });
  });
}
