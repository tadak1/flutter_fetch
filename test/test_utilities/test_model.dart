import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:swr_requester/swr_requester.dart';

class TestResponse {
  TestResponse({
    required this.message,
  });

  String message;

  factory TestResponse.fromJson(Map<String, dynamic> json) {
    return TestResponse(
      message: json["message"],
    );
  }

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

  Map<String, dynamic> toJson() {
    return {
      "message": message,
    };
  }

  @override
  int get hashCode => message.hashCode;
}

Fetcher<TestResponse> createResponseFetcher(String message) {
  return (String path) async {
    final uri = Uri.parse("http://localhost:18080$path");
    final response = await http.get(uri);
    final json =
        jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    return TestResponse.fromJson(json);
  };
}
