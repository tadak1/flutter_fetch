import 'dart:async' show Stream;

final _defaultCache = <String, dynamic>{};

typedef Fetcher<T> = Future<T> Function(String path);

class SWRRequester {
  SWRRequester({
    Map<String, dynamic>? cache,
  }) : _cache = cache ?? _defaultCache;

  final Map<String, dynamic> _cache;

  Stream<T?> fetch<T>(
    String path,
    Fetcher<T> fetcher, {
    T? fallbackData,
    Map<dynamic, dynamic>? cache,
  }) async* {
    final cachedValue = _cache[path];
    if (cachedValue != null) {
      yield cachedValue as T?;
    } else if (cachedValue == null && fallbackData != null) {
      yield fallbackData;
    } else {
      yield null;
    }

    try {
      final resource = await fetcher(path);
      _cache.update(
        path,
        (value) => resource,
        ifAbsent: () => resource,
      );
      yield resource;
    } catch (e) {
      rethrow;
    }
  }

  T mutate<T>(String key, T value) {
    _cache.update(key, (value) => value, ifAbsent: () => value);
    return value;
  }
}
