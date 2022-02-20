import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_fetch_hooks/src/retry_option.dart';
import 'package:flutter_fetch_hooks/src/type.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:retry/retry.dart';

typedef FetcherState = Map<String, DateTime>;

final FetcherState _globalCache = <String, DateTime>{};

FutureReturned<T> _makeRevalidateFunc<T>(
  BuildContext context, {
  required String path,
  required Fetcher<T> fetcher,
}) {
  return () async {
    final resource = await fetcher(path);
    SharedAppData.setValue(context, path, resource);
    return resource;
  };
}

Future<T> revalidateWithRetry<T>(
  BuildContext context,
  String path,
  Fetcher<T> fetcher, {
  RetryOption? retryOption,
}) async {
  final revalidate = _makeRevalidateFunc(
    context,
    path: path,
    fetcher: fetcher,
  );
  if (retryOption == null) {
    return revalidate();
  }

  final onRetry = retryOption.onRetry;
  if (onRetry == null) {
    throw ArgumentError('onRetry are not specified.');
  }
  if (retryOption.maxRetryAttempts <= 0) {
    throw ArgumentError('maxRetryAttempts are not specified.');
  }
  return retry(
    () async {
      return revalidate();
    },
    retryIf: (exception) async {
      return await onRetry(path, exception);
    },
    maxAttempts: retryOption.maxRetryAttempts,
  );
}

T? useFetch<T>({
  required String path,
  required Fetcher<T> fetcher,
  T? fallbackData,
  RetryOption? retryOption,
  Duration deduplicationInterval = const Duration(seconds: 2),
}) {
  final context = useContext();
  final ref = useRef<T?>(null);
  final listenableValue = SharedAppData.getValue(
    context,
    path,
    () => fallbackData,
  );
  final revalidate = _makeRevalidateFunc(
    context,
    path: path,
    fetcher: fetcher,
  );

  useEffect(() {
    ref.value = listenableValue;
    return;
  }, [listenableValue]);

  useEffect(() {
    Future(() async {
      final fetchTimeStamp = _globalCache[path];
      if (fetchTimeStamp == null) {
        _globalCache[path] = DateTime.now();
        Timer(deduplicationInterval, () {
          _globalCache.remove(path);
        });
        await revalidate();
      }
    });
    return;
  }, [path]);
  return ref.value;
}
