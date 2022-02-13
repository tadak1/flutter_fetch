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

final Cache defaultDataCache = <String, dynamic>{};

AsyncValue<T> useFetch<T>(
  String path,
  Fetcher<T> fetcher, {
  T? fallbackData,
  Map<String, dynamic>? cache,
  FetchState? fetchState,
  RetryOption? retryOption,
  Duration deduplicationInterval = const Duration(seconds: 2),
}) {
  return use(_FetchStateHook(
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
    required this.path,
    required this.fetcher,
    required this.fetchState,
    required this.deduplicationInterval,
    required this.retryOption,
    required this.fallbackData,
    required Map<String, dynamic>? dataCache,
  })  : _dataCache = dataCache ?? defaultDataCache,
        super(keys: [path]);

  final String path;
  final Fetcher<T> fetcher;
  final Map<String, dynamic> _dataCache;
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

    final cache = hook._dataCache;
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

    final dynamic cachedValue = hook._dataCache[hook.path];
    if (cachedValue != null) {
      _state = AsyncValue.data(cachedValue as T);
    } else if (hook.fallbackData != null) {
      _state = AsyncValue.data(hook.fallbackData!);
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
      final resource = await fetcher(path);
      hook._dataCache.update(
        path,
        (dynamic value) => resource,
        ifAbsent: () => resource,
      );
      return resource;
    };
  }
}
