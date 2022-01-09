import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:swr_requester/swr_requester.dart';

AsyncSnapshot<T?> useSWRRequest<T>(
  String path,
  Fetcher<T> fetcher,
  List<Object?>? keys, {
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
    keys: keys,
  ));
}

class _SWRStateHook<T> extends Hook<AsyncSnapshot<T?>> {
  const _SWRStateHook({
    required this.path,
    required this.fetcher,
    required this.cache,
    List<Object?>? keys,
  }) : super(keys: keys);

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
    final requester = SWRRequester(cache: hook.cache);
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
