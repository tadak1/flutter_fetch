import 'dart:async';

typedef Fetcher<T> = Future<T> Function();
typedef FutureReturned<T> = Future<T> Function();
typedef FetcherState = Map<String, DateTime>;
