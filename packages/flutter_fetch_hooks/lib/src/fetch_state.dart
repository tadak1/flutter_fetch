import 'dart:async';

import 'package:riverpod/riverpod.dart';

typedef DataCache = Map<String, dynamic>;
typedef GlobalCache = Map<DataCache, FetchState>;

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
final dataCacheProvider = Provider<DataCache>((ref) {
  return <String, dynamic>{};
});
