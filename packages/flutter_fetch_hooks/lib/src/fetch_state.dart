import 'dart:async';

import 'package:riverpod/riverpod.dart';

typedef Cache = Map<String, dynamic>;
typedef GlobalCache = Map<Cache, FetchState>;

class FetchState {
  FetchState({
    required this.updaters,
    required this.fetchers,
  });

  factory FetchState.initialize() {
    return FetchState(
      updaters: {},
      fetchers: {},
    );
  }

  final Map<String, StreamController<dynamic>> updaters;
  final Map<String, DateTime> fetchers;
}

final GlobalCache globalCache = {};
final fetchCacheProvider = Provider<Cache>((ref) {
  return <String, dynamic>{};
});
