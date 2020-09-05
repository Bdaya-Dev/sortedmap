part of sortedmap;

abstract class TypedSortedMap<TKey extends Comparable<TKey>, TVal>
    implements Map<TKey, TVal> {
  factory TypedSortedMap([Comparable Function(TKey, TVal) selector]) {
    return selector == null
        ? TypedSortedMap.byKey()
        : TypedSortedMap.byMapped(selector);
  }

  factory TypedSortedMap.byKey() {
    return _TypedSortedMapImpl._((k, v) => k, null, null);
  }

  factory TypedSortedMap.byValue() {
    return _TypedSortedMapImpl._((k, v) => v as Comparable, null, null);
  }

  factory TypedSortedMap.byMapped(Comparable Function(TKey, TVal) selector) {
    return _TypedSortedMapImpl._(selector, null, null);
  }

  /// Creates a [TypedSortedMap] that contains all key/value pairs of [other].
  factory TypedSortedMap.from(Map<TKey, TVal> other,
      [Comparable Function(TKey, TVal) selector]) {
    return TypedSortedMap(selector)..addAll(other);
  }

  /// Creates a [SortedMap] where the keys and values are computed from the
  /// [iterable].
  ///
  /// For each element of the [iterable] this constructor computes a key/value
  /// pair, by applying [key] and [value] respectively.
  ///
  /// The keys of the key/value pairs do not need to be unique. The last
  /// occurrence of a key will simply overwrite any previous value.
  ///
  /// If no functions are specified for [key] and [value] the default is to
  /// use the iterable value itself.
  static TypedSortedMap<TKey, TVal>
      fromIterable<TItem, TKey extends Comparable<TKey>, TVal>(
    Iterable<TItem> iterable, {
    TKey Function(TItem) key,
    TVal Function(TItem) value,
    Comparable Function(TKey, TVal) selector,
  }) {
    var map = TypedSortedMap<TKey, TVal>(selector);

    key ??= (v) => v as TKey;
    value ??= (v) => v as TVal;
    for (var element in iterable) {
      map[key(element)] = value(element);
    }
    return map;
  }

  /// Creates a [SortedMap] associating the given [keys] to [values].
  ///
  /// This constructor iterates over [keys] and [values] and maps each element of
  /// [keys] to the corresponding element of [values].
  ///
  /// If [keys] contains the same object multiple times, the last occurrence
  /// overwrites the previous value.
  ///
  /// It is an error if the two [Iterable]s don't have the same length.
  factory TypedSortedMap.fromIterables(
    Iterable<TKey> keys,
    Iterable<TVal> values, [
    Comparable Function(TKey, TVal) selector,
  ]) {
    var map = TypedSortedMap<TKey, TVal>(selector);
    var keyIterator = keys.iterator;
    var valueIterator = values.iterator;

    var hasNextKey = keyIterator.moveNext();
    var hasNextValue = valueIterator.moveNext();

    while (hasNextKey && hasNextValue) {
      map[keyIterator.current] = valueIterator.current;
      hasNextKey = keyIterator.moveNext();
      hasNextValue = valueIterator.moveNext();
    }

    if (hasNextKey || hasNextValue) {
      throw ArgumentError('Iterables do not have same length.');
    }
    return map;
  }

  /// The ordering.
  Comparable Function(TKey, TVal) get selector;
  set selector(Comparable Function(TKey, TVal) val);

  /// Makes a copy of this map. The key/value pairs in the map are not cloned.
  TypedSortedMap<TKey, TVal> clone();

  /// Get the last key in the map for which the key/value pair is strictly
  /// smaller than that of [key]. Returns [:null:] if no key was not found.
  TKey lastKeyBefore(TKey key);

  /// Get the first key in the map for which the key/value pair is strictly
  /// larger than that of [key]. Returns [:null:] if no key was not found.
  TKey firstKeyAfter(TKey key);

  /// Gets the keys within the desired bounds and limit.
  Iterable<TKey> subkeys({
    Pair<TKey, Comparable> start,
    Pair<TKey, Comparable> end,
    int limit,
    bool reversed = false,
  });
/*
TODO: implment the views
  /// Creates a filtered view of this map.
  FilteredMapView<TKey, TVal> filteredMapView(
          {Pair<TKey, Comparable> start,
          Pair<TKey, Comparable> end,
          int limit,
          bool reversed = false}) =>
      FilteredMapView(this,
          start: start, end: end, limit: limit, reversed: reversed);

  /// Creates a filtered map based on this map.
  FilteredMap<K, V> filteredMap(
          {Pair<K, Comparable> start,
          Pair<K, Comparable> end,
          int limit,
          bool reversed = false}) =>
      FilteredMap(Filter(
          validInterval: KeyValueInterval.fromPairs(start, end),
          ordering: ordering,
          limit: limit,
          reversed: reversed))
        ..addAll(this);
*/

  Pair<TKey, Comparable> _pairForKey(TKey key) =>
      containsKey(key) ? Pair(key, selector(key, this[key])) : null;
}

class _TypedSortedMapImpl<TKey extends Comparable<TKey>, TVal>
    extends MapBase<TKey, TVal> with TypedSortedMap<TKey, TVal> {
  Comparable Function(TKey, TVal) _selector;
  _TypedSortedMapImpl._(
      Comparable Function(TKey, TVal) selector, this._sortedPairs, this._map) {
    _selector = selector;
    _sortedPairs ??= TreeSet();
    _map ??= TreeMap();
  }

  @override
  Comparable Function(TKey p1, TVal p2) get selector => _selector;
  @override
  set selector(Comparable Function(TKey, TVal) val) {
    _selector = val;
    var oldMap = Map<TKey, TVal>.from(_map);
    clear();
    addAll(oldMap);
  }

  TreeSet<Pair<TKey, Comparable>> _sortedPairs;
  TreeMap<TKey, TVal> _map;

  @override
  bool containsKey(Object key) => _map.containsKey(key);

  @override
  Iterable<TKey> get keys => _sortedPairs.map((p) => p.key);

  @override
  TypedSortedMap<TKey, TVal> clone() => _TypedSortedMapImpl<TKey, TVal>._(
        _selector,
        TreeSet()..addAll(_sortedPairs),
        TreeMap<TKey, TVal>.from(_map),
      );

  @override
  TVal operator [](Object key) => _map[key];

  @override
  void operator []=(TKey key, TVal value) {
    var pair = _pairForKey(key);
    if (pair != null) _sortedPairs.remove(pair);
    _addPair(key, value);
  }

  @override
  bool get isEmpty => _map.isEmpty;

  void _addPair(TKey key, TVal value) {
    _map[key] = value;
    _sortedPairs.add(Pair(key, selector(key, value)));
  }

  @override
  void clear() {
    _map.clear();
    _sortedPairs.clear();
  }

  @override
  TVal remove(Object key) {
    if (!_map.containsKey(key)) return null;
    _sortedPairs.remove(_pairForKey(key));
    return _map.remove(key);
  }

  @override
  TKey lastKeyBefore(TKey key) {
    if (!_map.containsKey(key)) {
      throw StateError('No such key $key in collection');
    }
    var pair = _pairForKey(key);
    var it = _sortedPairs.fromIterator(pair, reversed: true);
    while (it.moveNext() && it.current == pair) {}
    return it.current?.key;
  }

  @override
  TKey firstKeyAfter(TKey key) {
    if (!_map.containsKey(key)) {
      throw StateError('No such key $key in collection');
    }
    var pair = _pairForKey(key);
    var it = _sortedPairs.fromIterator(pair);
    while (it.moveNext() && it.current == pair) {}
    return it.current?.key;
  }

  @override
  Iterable<TKey> subkeys({
    Pair<TKey, Comparable> start,
    Pair<TKey, Comparable> end,
    int limit,
    bool reversed = false,
  }) {
    var it = _subkeys(start, end, limit, reversed);
    if (reversed) return it.toList().reversed;
    return it;
  }

  Iterable<TKey> _subkeys(Pair<TKey, Comparable> start,
      Pair<TKey, Comparable> end, int limit, bool reversed) sync* {
    var from = reversed ? end : start;
    Iterator it = _sortedPairs.fromIterator(from, reversed: reversed);
    var count = 0;
    while (it.moveNext() && (limit == null || count++ < limit)) {
      var cmp = Comparable.compare(it.current, reversed ? start : end);
      if ((reversed && cmp < 0) || (!reversed && cmp > 0)) return;
      yield it.current.key;
    }
  }
}

abstract class UnmodifiableTypedSortedMap<K extends Comparable<K>, V>
    implements TypedSortedMap<K, V> {
  @override
  void operator []=(K key, V value) =>
      throw UnsupportedError('Map view cannot be modified.');

  @override
  void clear() => throw UnsupportedError('Map view cannot be modified.');

  @override
  V remove(Object key) =>
      throw UnsupportedError('Map view cannot be modified.');
}
