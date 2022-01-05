import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:swr_requester/swr_requester.dart';

ValueNotifier<AsyncSnapshot<T?>> useSWRRequest<T>(
  String path,
  Fetcher<T?> fetcher, {
  T? fallbackData,
  Map<String, dynamic>? cache,
  bool shouldRetry = false,
  OnRetryFunction? onRetry,
  int maxRetryAttempts = 5,
}) {
  final result = useState(AsyncSnapshot<T?>.waiting());
  final requester = SWRRequester(cache: cache);

  useEffect(() {
    final subscription = requester
        .fetch(
      path,
      fetcher,
      fallbackData: fallbackData,
      shouldRetry: shouldRetry,
      onRetry: onRetry,
      maxRetryAttempts: maxRetryAttempts,
    )
        .listen((event) {
      result.value = AsyncSnapshot<T?>.withData(ConnectionState.active, event);
    }, onError: (exception) {
      result.value =
          AsyncSnapshot<T?>.withError(ConnectionState.done, exception);
    });
    return () async {
      await subscription.cancel();
    };
  }, [path]);

  return result;
}
