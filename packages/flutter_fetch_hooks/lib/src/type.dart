import 'dart:async';

typedef Fetcher<T> = Future<T> Function(String path);
typedef FutureReturned<T> = Future<T> Function();
