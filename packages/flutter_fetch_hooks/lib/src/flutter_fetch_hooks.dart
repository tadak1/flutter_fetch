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

FutureReturned<T> _makeRevalidateFunc<T>({
  required String path,
  required Fetcher<T> fetcher,
  RetryOption? retryOption,
}) {
  return () async {
    return revalidateWithRetry(path, fetcher, retryOption: retryOption);
  };
}

Future<T> revalidateWithRetry<T>(
  String path,
  Fetcher<T> fetcher, {
  RetryOption? retryOption,
}) async {
  if (retryOption == null) {
    return fetcher(path);
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
      return fetcher(path);
    },
    retryIf: (exception) async {
      return await onRetry(path, exception);
    },
    maxAttempts: retryOption.maxRetryAttempts,
  );
}

FetchState<T?> useFetch<T>({
  required String path,
  required Fetcher<T> fetcher,
  T? fallbackData,
  RetryOption? retryOption,
  Duration deduplicationInterval = const Duration(seconds: 2),
}) {
  final context = useContext();
  final ref = useRef<FetchState<T?>>(const FetchState(
    value: null,
    isValidating: false,
  ));

  // ignore: omit_local_variable_types
  final FetchState<T?> listenableValue = SharedAppData.getValue(
    context,
    path,
    () => FetchState(
      value: fallbackData,
      isValidating: false,
    ),
  );
  final revalidate = _makeRevalidateFunc(
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
        final fetchState = ref.value;
        SharedAppData.setValue(
          context,
          path,
          FetchState(
            value: fetchState.value,
            isValidating: true,
          ),
        );
        final result = await revalidate();
        SharedAppData.setValue(
          context,
          path,
          FetchState(
            value: result,
            isValidating: false,
          ),
        );
      }
    });
    return;
  }, [path]);
  return ref.value;
}

@immutable
class FetchState<T> {
  const FetchState({
    required this.value,
    required this.isValidating,
  });

  final T? value;
  final bool isValidating;
}
