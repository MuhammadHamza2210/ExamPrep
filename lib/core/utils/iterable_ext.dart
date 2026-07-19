extension IndexedIterable<E> on Iterable<E> {
  /// Like [map] but the callback also receives the element index.
  Iterable<T> mapIndexed<T>(T Function(int index, E element) f) sync* {
    var i = 0;
    for (final e in this) {
      yield f(i, e);
      i++;
    }
  }
}
