import 'dart:async';

typedef OnRetry = FutureOr<bool> Function(
  Exception exception,
);

class RetryOption {
  RetryOption({
    this.onRetry,
    this.maxRetryAttempts = 0,
  });

  final OnRetry? onRetry;
  final int maxRetryAttempts;
}
