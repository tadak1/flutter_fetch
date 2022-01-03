import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swr_requester_hooks/src/swr_requester_hooks.dart';

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
            );
            if (response.value == null) {
              return const Text(
                "Loading",
                textDirection: TextDirection.ltr,
              );
            }
            return Text(
              "${response.value?.message}",
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
            if (response.value == null) {
              return const Text(
                "Loading",
                textDirection: TextDirection.ltr,
              );
            }
            return Text(
              "${response.value?.message}",
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
  });
}
