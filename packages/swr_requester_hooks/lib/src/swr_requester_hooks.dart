import 'package:flutter/foundation.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:swr_requester/swr_requester.dart';

ValueNotifier<T?> useSWRRequest<T>(
  String path,
  Fetcher<T?> fetcher, {
  T? fallbackData,
  Map<String, dynamic>? cache,
  bool shouldRetry = false,
  OnRetryFunction? onRetry,
  int maxRetryAttempts = 5,
}) {
  final result = useState<T?>(null);
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
      result.value = event;
    });
    return () async {
      await subscription.cancel();
    };
  }, [path]);

  return result;
}
