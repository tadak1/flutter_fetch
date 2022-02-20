String convertToHash(StringBuffer buffer, Object? keys) {
  return _writeDeepCollectionHashCode(buffer, keys).toString();
}

StringBuffer _writeDeepCollectionHashCode(StringBuffer buffer, Object? keys) {
  if (keys == null) {
    return buffer..write(null.hashCode);
  }
  if (keys is Iterable) {
    for (final key in keys) {
      convertToHash(buffer, key);
    }
    return buffer;
  }
  if (keys is Map) {
    for (final entry in keys.entries) {
      buffer.write((entry.key as Object).hashCode);
      convertToHash(buffer, (entry.value as Object).hashCode);
    }
    return buffer;
  }
  buffer.write(keys.hashCode);
  return buffer;
}
