import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_fetch_hooks/src/flutter_fetch_hooks.dart';

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
            if (!response.hasData) {
              return const Text(
                "Loading",
                textDirection: TextDirection.ltr,
              );
            }
            return Text(
              "${response.data?.message}",
              textDirection: TextDirection.ltr,
            );
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
            if (response.data == null) {
              return const Text(
                "Loading",
                textDirection: TextDirection.ltr,
              );
            }
            return Text(
              "${response.data?.message}",
              textDirection: TextDirection.ltr,
            );
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
            final response = useSWRRequest(
              "/test_path1",
              (path) async {
                await Future.delayed(const Duration(seconds: 1));
                throw const HttpException("Connection Error");
              },
              cache: {},
              shouldRetry: false,
            );
            if (!response.hasData && response.hasError) {
              final exception = response.error as HttpException?;
              return Text(
                exception?.message ?? "",
                textDirection: TextDirection.ltr,
              );
            }
            if (!response.hasData) {
              return const Text(
                "Loading",
                textDirection: TextDirection.ltr,
              );
            }
            return Text(
              "${response.data?.message}",
              textDirection: TextDirection.ltr,
            );
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
