import 'package:flutter/foundation.dart';

@immutable
class FetchState<T> {
  const FetchState({
    required this.value,
    this.exception,
    this.isValidating = false,
  });

  final T? value;
  final Exception? exception;
  final bool isValidating;
}

@immutable
class InternalFetchState<T> {
  const InternalFetchState({
    required this.value,
    this.exception,
    this.isValidating = false,
    this.expiredAt,
  });

  final T? value;
  final Exception? exception;
  final bool isValidating;
  final DateTime? expiredAt;

  FetchState<T> toFetchState() {
    return FetchState<T>(
      value: value,
      exception: exception,
      isValidating: isValidating,
    );
  }
}
