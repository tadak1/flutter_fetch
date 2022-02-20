import 'package:flutter/foundation.dart';

@immutable
class FetchState<T> {
  const FetchState({
    required this.value,
    required this.isValidating,
  });

  final T? value;
  final bool isValidating;
}

@immutable
class InternalFetchState<T> {
  const InternalFetchState({
    required this.value,
    required this.isValidating,
    required this.expiredAt,
  });

  final T? value;
  final bool isValidating;
  final DateTime? expiredAt;

  FetchState<T> toFetchState() {
    return FetchState<T>(
      value: value,
      isValidating: isValidating,
    );
  }
}
