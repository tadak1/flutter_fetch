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
