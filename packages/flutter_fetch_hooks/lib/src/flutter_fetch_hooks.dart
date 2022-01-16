import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_fetch/flutter_fetch.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:riverpod/riverpod.dart';

AsyncValue<T?> useFetch<T>(
  String path,
  Fetcher<T> fetcher, {
  T? fallbackData,
  Map<String, dynamic>? cache,
  bool shouldRetry = false,
  OnRetryFunction? onRetry,
  int maxRetryAttempts = 5,
}) {
  return use(_FetchStateHook(
    path: path,
    fetcher: fetcher,
    cache: cache,
    fallbackData: fallbackData,
    shouldRetry: shouldRetry,
    onRetry: onRetry,
    maxRetryAttempts: maxRetryAttempts,
  ));
}

class _FetchStateHook<T> extends Hook<AsyncValue<T?>> {
  _FetchStateHook({
    required this.path,
    required this.fetcher,
    required this.cache,
    required T? fallbackData,
    required bool shouldRetry,
    required OnRetryFunction? onRetry,
    required int maxRetryAttempts,
  }) : super(keys: [path]);

  final String path;
  final Fetcher<T> fetcher;
  final Map<String, dynamic>? cache;

  @override
  _FetchStateHookState<T?> createState() => _FetchStateHookState();
}

class _FetchStateHookState<T>
    extends HookState<AsyncValue<T?>, _FetchStateHook<T?>> {
  AsyncValue<T?> _state = const AsyncValue.loading();
  StreamSubscription? subscription;

  @override
  void initHook() {
    super.initHook();
    final requester = Requester(cache: hook.cache);
    subscription = requester
        .fetch(
      hook.path,
      hook.fetcher,
    )
        .listen((event) {
      setState(() {
        _state =
            event != null ? AsyncValue.data(event) : const AsyncValue.loading();
      });
    }, onError: (exception) {
      setState(() {
        _state = AsyncValue.error(exception);
      });
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    subscription = null;
  }

  @override
  AsyncValue<T?> build(BuildContext context) => _state;

  @override
  Object? get debugValue => _state;

  @override
  String get debugLabel => 'useFetch<$T>';
}
