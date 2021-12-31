import 'dart:async' show Stream;

final _cache = <String, Object?>{};

typedef Fetcher<T> = Future<T> Function(String path);

Stream<T?> fetch<T>(
  String path,
  Fetcher<T> fetcher, {
  T? fallbackData,
}) async* {
  final cachedValue = _cache[path];
  if (cachedValue != null) {
    final T? cached = _cache[path] as T?;
    yield cached;
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
