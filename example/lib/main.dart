import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_fetch_hooks/flutter_fetch_hooks.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends HookWidget {
  const MyApp({Key? key}) : super(key: key);
  final flutterPluginsRepositoryPath = "/flutter/plugins";
  final flutterRepositoryPath = "/flutter/flutter";

  @override
  Widget build(BuildContext context) {
    final requestPath = useState<String>(flutterRepositoryPath);
    return MaterialApp(
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Example"),
        ),
        body: Column(
          children: [
            Expanded(
              child: ResponseDisplayWidget(
                path: requestPath.value,
              ),
            ),
            Expanded(
              child: ResponseDisplayWidget(
                path: requestPath.value,
              ),
            ),
          ],
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

class GithubRepositoryResponse {
  GithubRepositoryResponse({
    required this.fullName,
  });

  String fullName;

  factory GithubRepositoryResponse.fromJson(Map<String, dynamic> json) {
    return GithubRepositoryResponse(fullName: json["full_name"]);
  }
}

Future<Map<String, dynamic>> _fetchGithub(String path) async {
  final uri = Uri.https("api.github.com", path);
  developer.log(
    "Request to ${uri.toString()}",
  );
  final result = await http.get(uri);
  final Map<String, dynamic> json = jsonDecode(result.body);
  return json;
}

Future<GithubRepositoryResponse> _fetchGithubRepositoryResponse(
    String path) async {
  final json = await _fetchGithub("/repos" + path);
  return GithubRepositoryResponse.fromJson(json);
}

class ResponseDisplayWidget extends HookConsumerWidget {
  const ResponseDisplayWidget({
    Key? key,
    required this.path,
  }) : super(key: key);
  final String path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fetchState = useFetch<GithubRepositoryResponse>(
      keys: [
        "/repos",
        path,
        null,
        ["1", "2"],
        {"Key", "Value"},
      ],
      fetcher: () => _fetchGithubRepositoryResponse(path),
      deduplicationInterval: const Duration(seconds: 10),
    );
    return Center(
      child: Text(
        fetchState.value?.fullName ?? "Initial",
      ),
    );
  }
}
