import 'dart:async';

import 'package:retry/retry.dart';

final _defaultCache = <String, dynamic>{};

typedef Fetcher<T> = Future<T> Function(String path);
typedef OnRetryFunction = FutureOr<bool> Function(
  String key,
  Exception exception,
);

class Requester {
  Requester({
    Map<String, dynamic>? cache,
  }) : _cache = cache ?? _defaultCache;

  final Map<String, dynamic> _cache;

  Stream<T?> fetch<T>(
    String path,
    Fetcher<T> fetcher, {
    T? fallbackData,
    bool shouldRetry = false,
    OnRetryFunction? onRetry,
    int maxRetryAttempts = 5,
  }) async* {
    final dynamic cachedValue = _cache[path];
    if (cachedValue != null) {
      yield cachedValue as T?;
    } else if (fallbackData != null) {
      yield fallbackData;
    } else {
      yield null;
    }

    if (shouldRetry) {
      yield await retry(
        () async => _revalidate(
          path: path,
          fetcher: fetcher,
        ),
        retryIf: (exception) async {
          if (onRetry == null) {
            throw exception;
          }
          final isCached = await onRetry(path, exception);
          if (!isCached) {
            throw exception;
          }
          return true;
        },
        maxAttempts: maxRetryAttempts,
      );
    } else {
      yield await _revalidate(
        path: path,
        fetcher: fetcher,
      );
    }
  }

  Future<T> _revalidate<T>({
    required String path,
    required Fetcher<T> fetcher,
  }) async {
    final resource = await fetcher(path);
    _cache.update(
      path,
      (dynamic value) => resource,
      ifAbsent: () => resource,
    );
    return resource;
  }

  T mutate<T>(String key, T value) {
    _cache.update(key, (dynamic value) => value,
        ifAbsent: () => value as Object);
    return value;
  }
}
