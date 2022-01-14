import 'dart:convert';
import 'dart:io';

import 'package:flutter_fetch/flutter_fetch.dart';
import 'package:http/http.dart' as http;

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

Fetcher<TestResponse> createHttpRequestFetcher(String message) {
  return (String path) async {
    final uri = Uri.parse('http://localhost:18080$path');
    final response = await http.get(uri);
    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return TestResponse.fromJson(json);
  };
}

Fetcher<TestResponse> createRetryRequestFetcher(
    String message, int targetCount) {
  var currentCount = 0;
  return (String path) async {
    currentCount++;
    if (currentCount == targetCount) {
      return TestResponse(message: message);
    }
    throw HttpException('Error $currentCount');
  };
}
