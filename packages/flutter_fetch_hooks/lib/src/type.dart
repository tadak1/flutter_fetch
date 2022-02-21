import 'dart:async';

typedef Fetcher<T> = Future<T> Function();
typedef FutureReturned<T> = Fetcher<T>;
typedef FetcherState = Map<String, DateTime>;
