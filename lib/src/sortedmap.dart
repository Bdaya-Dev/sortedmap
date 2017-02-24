// Copyright (c) 2016, Rik Bellens. All rights reserved. Use of this source code
// is governed by a BSD-style license that can be found in the LICENSE file.

part of sortedmap;


/// A [Pair] represents a key/value pair.
class Pair<K,V> implements Comparable<Pair<K,V>> {

  /// The key.
  final K key;

  /// The value.
  final V value;

  /// Creates a new key/value pair.
  const Pair(this.key,this.value);

  @override
  int get hashCode => quiver.hash2(key,value);

  @override
  bool operator==(dynamic other) => other is Pair && other.key==key && other.value == value;

  @override
  int compareTo(Pair<K, V> other) => Comparable.compare(key as Comparable,
      other.key as Comparable);

  @override
  String toString() => "Pair[$key,$value]";
}

/// A [Map] of objects that can be ordered relative to each other.
///
/// Key/value pairs of the map are compared using the `compare` function
/// passed in the constructor.
///
/// If the compare function is omitted, the objects are ordered by key which
/// is assumed to be [Comparable], and are compared using their
/// [Comparable.compareTo] method.
/// Non-comparable objects (including `null`) will not work as keys
/// in that case.
abstract class SortedMap<K,V> implements Map<K,V> {

  /// Creates a new [SortedMap] instance with an optional [compare] function,
  /// defining the ordering.
  factory SortedMap([int compare(Pair<K,V> a, Pair<K,V> b)]) =>
      new _SortedMap._(compare, null, null);


  /// Creates a [SortedMap] that contains all key/value pairs of [other].
  factory SortedMap.from(Map<K,V> other, [int compare(Pair<K,V> a, Pair<K,V> b)]) {
    return new SortedMap(compare)..addAll(other);
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
  factory SortedMap.fromIterable(Iterable iterable,
      {K key(element),
        V value(element),
        int compare(Pair<K,V> a, Pair<K,V> b)}) {
    SortedMap<K, V> map = new SortedMap<K, V>(compare);

    if (key == null) key = (K v)=>v;
    if (value == null) value = (V v)=>v;
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
  factory SortedMap.fromIterables(Iterable<K> keys, Iterable<V> values,
      [int compare(Pair<K,V> a, Pair<K,V> b)]) {
    SortedMap<K, V> map = new SortedMap<K, V>(compare);
    Iterator<K> keyIterator = keys.iterator;
    Iterator<V> valueIterator = values.iterator;

    bool hasNextKey = keyIterator.moveNext();
    bool hasNextValue = valueIterator.moveNext();

    while (hasNextKey && hasNextValue) {
      map[keyIterator.current] = valueIterator.current;
      hasNextKey = keyIterator.moveNext();
      hasNextValue = valueIterator.moveNext();
    }

    if (hasNextKey || hasNextValue) {
      throw new ArgumentError("Iterables do not have same length.");
    }
    return map;
  }

  /// A [Comparator] function that defines the ordering.
  Comparator<Pair<K,V>> get comparator;

  /// Makes a copy of this map. The key/value pairs in the map are not cloned.
  SortedMap<K,V> clone();

  /// Gets the key/value pairs as an iterable
  Iterable<Pair<K,V>> get pairs;


  /// Get the last key in the map for which the key/value pair is strictly
  /// smaller than that of [key]. Returns [:null:] if no key was not found.
  K lastKeyBefore(K key);

  /// Get the first key in the map for which the key/value pair is strictly
  /// larger than that of [key]. Returns [:null:] if no key was not found.
  K firstKeyAfter(K key);

}


class _SortedMap<K,V> extends MapBase<K,V> with SortedMap<K,V> {

  @override
  final Comparator<Pair<K,V>> comparator;

  TreeSet<Pair<K,V>> _sortedPairs;
  Map<K,V> _map;

  _SortedMap._(this.comparator, this._sortedPairs, this._map) {
    _sortedPairs ??= new TreeSet(comparator: comparator);
    _map ??= {};
  }

  @override
  SortedMap<K,V> clone() => new _SortedMap._(this.comparator, _sortedPairs.toSet(), new Map.from(_map));

  @override
  Iterable<Pair<K,V>> get pairs => _sortedPairs.toSet();

  @override
  V operator [](Object key) => _map[key];

  @override
  void operator []=(K key, V value) {
    if (_map.containsKey(key)) {
      _sortedPairs.remove(new Pair(key, _map[key]));
    }
    _addPair(new Pair(key,value));
  }

  void _addPair(Pair<K,V> p) {
    _map[p.key] = p.value;
    _sortedPairs.add(p);
  }

  @override
  void clear() {
    _map.clear();
    _sortedPairs.clear();
  }

  @override
  Iterable<K> get keys => pairs.map((p)=>p.key);

  @override
  V remove(Object key) {
    if (_map.containsKey(key)) {
      _sortedPairs.remove(new Pair(key, _map[key]));
    }
    return _map.remove(key);
  }

  @override
  K lastKeyBefore(K key) {
    if (!_map.containsKey(key)) {
      throw new StateError("No such key $key in collection");
    }
    var pair = new Pair(key, _map[key]);
    var it = _sortedPairs.fromIterator(pair, reversed: true);
    while (it.moveNext()&&it.current==pair);
    return it.current?.key;
  }

  @override
  K firstKeyAfter(K key) {
    if (!_map.containsKey(key)) {
      throw new StateError("No such key $key in collection");
    }
    var pair = new Pair(key, _map[key]);
    var it = _sortedPairs.fromIterator(pair);
    while (it.moveNext()&&it.current==pair);
    return it.current?.key;
  }

}