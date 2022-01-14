import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_fetch/flutter_fetch.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

AsyncSnapshot<T?> useSWRRequest<T>(
  String path,
  Fetcher<T> fetcher, {
  Iterable<Object?> additionalKeys = const [],
  T? fallbackData,
  Map<String, dynamic>? cache,
  bool shouldRetry = false,
  OnRetryFunction? onRetry,
  int maxRetryAttempts = 5,
}) {
  return use(_SWRStateHook(
    path: path,
    fetcher: fetcher,
    cache: cache,
    additionalKeys: additionalKeys,
    fallbackData: fallbackData,
    shouldRetry: shouldRetry,
    onRetry: onRetry,
    maxRetryAttempts: maxRetryAttempts,
  ));
}

class _SWRStateHook<T> extends Hook<AsyncSnapshot<T?>> {
  _SWRStateHook({
    required this.path,
    required this.fetcher,
    required this.cache,
    required Iterable<Object?> additionalKeys,
    required T? fallbackData,
    required bool shouldRetry,
    required OnRetryFunction? onRetry,
    required int maxRetryAttempts,
  }) : super(keys: [path, ...additionalKeys]);

  final String path;
  final Fetcher<T> fetcher;
  final Map<String, dynamic>? cache;

  @override
  _SWRStateHookState<T?> createState() => _SWRStateHookState();
}

class _SWRStateHookState<T>
    extends HookState<AsyncSnapshot<T?>, _SWRStateHook<T?>> {
  AsyncSnapshot<T?> _state = AsyncSnapshot<T?>.waiting();
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
        _state = AsyncSnapshot<T?>.withData(ConnectionState.active, event);
      });
    }, onError: (exception) {
      setState(() {
        _state = AsyncSnapshot<T?>.withError(ConnectionState.active, exception);
      });
    });
  }

  @override
  void dispose() {
    subscription?.cancel();
    subscription = null;
  }

  @override
  AsyncSnapshot<T?> build(BuildContext context) => _state;

  @override
  Object? get debugValue => _state;

  @override
  String get debugLabel => 'useSWRRequest<$T>';
}
