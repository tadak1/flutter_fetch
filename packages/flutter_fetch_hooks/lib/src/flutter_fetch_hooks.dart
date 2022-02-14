import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_fetch_hooks/src/retry_option.dart';
import 'package:flutter_fetch_hooks/src/type.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:retry/retry.dart';
import 'package:riverpod/riverpod.dart';

import 'fetch_state.dart';

AsyncValue<T> useFetch<T>(
  Reader reader, {
  required String path,
  required Fetcher<T> fetcher,
  T? fallbackData,
  Map<String, dynamic>? cache,
  FetchState? fetchState,
  RetryOption? retryOption,
  Duration deduplicationInterval = const Duration(seconds: 2),
}) {
  return use(_FetchStateHook(
    reader: reader,
    path: path,
    fetcher: fetcher,
    dataCache: cache,
    fetchState: fetchState,
    fallbackData: fallbackData,
    retryOption: retryOption,
    deduplicationInterval: deduplicationInterval,
  ));
}

class _FetchStateHook<T> extends Hook<AsyncValue<T>> {
  _FetchStateHook({
    required this.reader,
    required this.path,
    required this.fetcher,
    required this.dataCache,
    required this.fetchState,
    required this.deduplicationInterval,
    required this.retryOption,
    required this.fallbackData,
  }) : super(keys: [path]);

  final Reader reader;
  final String path;
  final Fetcher<T> fetcher;
  final Map<String, dynamic>? dataCache;
  final FetchState? fetchState;
  final Duration deduplicationInterval;
  final RetryOption? retryOption;
  final T? fallbackData;

  @override
  _FetchStateHookState<T> createState() => _FetchStateHookState();
}

class _FetchStateHookState<T>
    extends HookState<AsyncValue<T>, _FetchStateHook<T>> {
  AsyncValue<T> _state = const AsyncValue.loading();
  StreamSubscription<dynamic>? subscription;

  @override
  Object? get debugValue => _state;

  @override
  String get debugLabel => 'useFetch<$T>';

  @override
  AsyncValue<T> build(BuildContext context) => _state;

  @override
  void dispose() {
    subscription?.cancel();
    subscription = null;
  }

  @override
  void initHook() {
    super.initHook();
    if (hook.path.isEmpty) {
      return;
    }
    final cache = _readDataCache();
    var fetchState = globalCache[cache];
    if (fetchState == null) {
      fetchState = FetchState.initialize();
      globalCache[cache] = fetchState;
    }

    var updater = fetchState.updaters[hook.path];
    if (updater == null) {
      updater = StreamController<dynamic>.broadcast();
      fetchState.updaters.putIfAbsent(
        hook.path,
        () => updater!,
      );
    }

    final dynamic cachedResult = cache[hook.path];
    final fallbackData = hook.fallbackData;
    if (cachedResult != null) {
      _state = AsyncValue.data(cachedResult as T);
    } else if (fallbackData != null) {
      _state = AsyncValue.data(fallbackData);
    } else {
      _state = const AsyncValue.loading();
    }

    subscription = updater.stream.listen((dynamic event) {
      setState(() {
        _state = AsyncValue.data(event as T);
      });
    }, onError: (Object exception, StackTrace stackTrace) {
      setState(() {
        _state = AsyncValue.error(exception);
      });
    });

    final fetcher = fetchState.fetchers[hook.path];
    if (fetcher == null) {
      updater.sink.addStream(
        revalidateWithRetry(
          hook.path,
          hook.fetcher,
        ),
      );
      fetchState.fetchers[hook.path] = DateTime.now();
      Timer(hook.deduplicationInterval, () {
        fetchState?.fetchers.remove(hook.path);
      });
    }
  }

  DataCache _readDataCache() {
    final dataCache = hook.reader(dataCacheProvider);
    return hook.dataCache ?? dataCache;
  }

  Stream<T> revalidateWithRetry(
    String path,
    Fetcher<T> fetcher, {
    RetryOption? retryOption,
  }) async* {
    final revalidate = _makeRevalidateFunc(
      path: path,
      fetcher: fetcher,
    );
    if (retryOption == null) {
      yield await revalidate();
      return;
    }

    final onRetry = retryOption.onRetry;
    if (onRetry == null) {
      throw ArgumentError('onRetry are not specified.');
    }
    if (retryOption.maxRetryAttempts <= 0) {
      throw ArgumentError('maxRetryAttempts are not specified.');
    }
    yield await retry(
      () async {
        return revalidate();
      },
      retryIf: (exception) async {
        return await onRetry(path, exception);
      },
      maxAttempts: retryOption.maxRetryAttempts,
    );
  }

  FutureReturned<T> _makeRevalidateFunc({
    required String path,
    required Fetcher<T> fetcher,
  }) {
    return () async {
      final dataCache = _readDataCache();
      final resource = await fetcher(path);
      dataCache.update(
        path,
        (dynamic value) => resource,
        ifAbsent: () => resource,
      );
      return resource;
    };
  }
}
