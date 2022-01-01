import 'dart:io';

import 'package:mockserver/mockserver.dart';

enum MethodType {
  get,
  post,
  put,
  patch,
  delete,
}

extension on MethodType {
  String get name {
    switch (this) {
      case MethodType.get:
        return "GET";
      case MethodType.post:
        return "POST";
      case MethodType.put:
        return "PUT";
      case MethodType.patch:
        return "PATH";
      case MethodType.delete:
        return "DELETE";
    }
  }
}

class TestEndpoint extends EndPoint {
  TestEndpoint({
    required this.pathWithQueryParameter,
    required this.methodType,
    required this.responseBody,
  }) : super(
          path: pathWithQueryParameter,
          method: methodType.name,
        );

  final String pathWithQueryParameter;
  final MethodType methodType;
  final Map<String, dynamic> responseBody;

  @override
  void process(HttpRequest request, HttpResponse response) {
    response
      ..writeJson(responseBody)
      ..close();
  }
}
