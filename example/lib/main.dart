import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_fetch_hooks/flutter_fetch_hooks.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends HookWidget {
  const MyApp({Key? key}) : super(key: key);
  final flutterPluginsRepositoryPath = "/repos/flutter/plugins";
  final flutterRepositoryPath = "/repos/flutter/flutter";

  @override
  Widget build(BuildContext context) {
    final requestPath = useState<String>(flutterRepositoryPath);
    final response = useSWRRequest(requestPath.value, (path) async {
      final uri = Uri.https("api.github.com", path);
      developer.log(
        "Request to ${uri.toString()}",
      );
      final result = await http.get(uri);
      final Map<String, dynamic> json = jsonDecode(result.body);
      return json;
    });
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Example"),
        ),
        body: response.data == null
            ? const Text("Loading")
            : Center(
                child: Text(
                  response.data?["full_name"] ?? "",
                ),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            requestPath.value = flutterRepositoryPath == requestPath.value
                ? flutterPluginsRepositoryPath
                : flutterRepositoryPath;
          },
        ),
      ),
    );
  }
}
