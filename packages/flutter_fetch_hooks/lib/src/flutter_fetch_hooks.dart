import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_fetch/flutter_fetch.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:riverpod/riverpod.dart';
import 'package:retry/retry.dart';

AsyncValue<T> useFetch<T>(
  String path,
  Fetcher<T> fetcher, {
  T? fallbackData,
  Map<String, dynamic>? cache,
  FetchState? fetchState,
  bool shouldRetry = false,
  OnRetryFunction? onRetry,
  int maxRetryAttempts = 5,
  Duration deduplicationInterval = const Duration(seconds: 2),
}) {
  return use(_FetchStateHook(
    path: path,
    fetcher: fetcher,
    cache: cache,
    fetchState: fetchState,
    fallbackData: fallbackData,
    shouldRetry: shouldRetry,
    onRetry: onRetry,
    maxRetryAttempts: maxRetryAttempts,
    deduplicationInterval: deduplicationInterval,
  ));
}

class _FetchStateHook<T> extends Hook<AsyncValue<T>> {
  _FetchStateHook({
    required this.path,
    required this.fetcher,
    required this.cache,
    required this.fetchState,
    required this.deduplicationInterval,
    required this.fallbackData,
    required bool shouldRetry,
    required OnRetryFunction? onRetry,
    required int maxRetryAttempts,
  }) : super(keys: [path]);

  final String path;
  final Fetcher<T> fetcher;
  final Map<String, dynamic>? cache;
  final FetchState? fetchState;
  final Duration deduplicationInterval;
  final T? fallbackData;

  @override
  _FetchStateHookState<T> createState() => _FetchStateHookState();
}

class _FetchStateHookState<T>
    extends HookState<AsyncValue<T>, _FetchStateHook<T>> {
  AsyncValue<T> _state = const AsyncValue.loading();
  StreamSubscription? subscription;

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
    final state = hook.fetchState ?? FetchState.initialize();

    var updater = state.updaters[hook.path];
    if (updater == null) {
      updater = StreamController.broadcast();
      state.updaters.putIfAbsent(
        hook.path,
        () => updater!,
      );
    }
    final dynamic cachedValue = hook.cache?[hook.path];
    if (cachedValue != null) {
      _state = AsyncValue.data(cachedValue as T);
    } else if (hook.fallbackData != null) {
      _state = AsyncValue.data(hook.fallbackData!);
    } else {
      _state = const AsyncValue.loading();
    }

    subscription = updater.stream.asBroadcastStream().listen((event) {
      setState(() {
        _state =
            event != null ? AsyncValue.data(event) : const AsyncValue.loading();
      });
    }, onError: (exception) {
      setState(() {
        _state = AsyncValue.error(exception);
      });
    });

    var fetcher = state.fetchers[hook.path];
    if (fetcher == null) {
      updater.sink.addStream(
        revalidate(
          hook.path,
          hook.fetcher,
        ),
      );
      state.fetchers[hook.path] = DateTime.now();
      Timer(hook.deduplicationInterval, () {
        state.fetchers.remove(hook.path);
      });
    }
  }

  Stream<T> revalidate(
    String path,
    Fetcher<T> fetcher, {
    bool shouldRetry = false,
    OnRetryFunction? onRetry,
    int maxRetryAttempts = 5,
  }) async* {
    if (shouldRetry) {
      if (onRetry == null || maxRetryAttempts <= 0) {
        throw ArgumentError('onRetry and maxRetryAttempts are not specified.');
      }
      yield await retry(
        () async => _revalidate(
          path: path,
          fetcher: fetcher,
        ),
        retryIf: (exception) async {
          return await onRetry(path, exception);
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

  Future<T> _revalidate({
    required String path,
    required Fetcher<T> fetcher,
  }) async {
    final resource = await fetcher(path);
    hook.cache?.update(
      path,
      (dynamic value) => resource,
      ifAbsent: () => resource,
    );
    return resource;
  }
}

final globalFetchStateProvider = Provider((ref) {
  return FetchState.initialize();
});

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
