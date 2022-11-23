import 'package:hive/hive.dart';

class MockBox implements Box {
  Map<dynamic, dynamic> box = {};
  @override
  bool get isEmpty => box.isEmpty;
  @override
  bool get isNotEmpty => box.isNotEmpty;

  @override
  dynamic get(dynamic key, {defaultValue}) {
    return box[key] ?? defaultValue;
  }

  @override
  put(dynamic key, dynamic value) async {
    box[key] = value;
  }

  @override
  Future<int> clear() async {
    box.clear();
    return 0;
  }

  @override
  Future<void> putAll(Map<dynamic, dynamic> other) async {
    box.addAll(other);
  }

  @override
  Future<void> delete(key) async {
    box.remove(key);
  }

  @override
  Future<int> add(value) {
    // TODO: implement add
    throw UnimplementedError();
  }

  @override
  Future<Iterable<int>> addAll(Iterable values) {
    // TODO: implement addAll
    throw UnimplementedError();
  }

  @override
  Future<void> close() {
    // TODO: implement close
    throw UnimplementedError();
  }

  @override
  Future<void> compact() {
    // TODO: implement compact
    throw UnimplementedError();
  }

  @override
  bool containsKey(key) {
    // TODO: implement containsKey
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAll(Iterable keys) async {
    for (var element in keys) {
      box.remove(element);
    }
  }

  @override
  Future<void> deleteAt(int index) {
    // TODO: implement deleteAt
    throw UnimplementedError();
  }

  @override
  Future<void> deleteFromDisk() {
    // TODO: implement deleteFromDisk
    throw UnimplementedError();
  }

  @override
  Future<void> flush() {
    // TODO: implement flush
    throw UnimplementedError();
  }

  @override
  getAt(int index) {
    // TODO: implement getAt
    throw UnimplementedError();
  }

  @override
  // TODO: implement isOpen
  bool get isOpen => throw UnimplementedError();

  @override
  keyAt(int index) {
    // TODO: implement keyAt
    throw UnimplementedError();
  }

  @override
  // TODO: implement keys
  Iterable get keys => box.keys;

  @override
  // TODO: implement lazy
  bool get lazy => throw UnimplementedError();

  @override
  // TODO: implement length
  int get length => box.length;

  @override
  // TODO: implement name
  String get name => 'local';

  @override
  // TODO: implement path
  String? get path => throw UnimplementedError();

  @override
  Future<void> putAt(int index, value) {
    // TODO: implement putAt
    throw UnimplementedError();
  }

  @override
  Map toMap() {
    // TODO: implement toMap
    throw UnimplementedError();
  }

  @override
  // TODO: implement values
  Iterable get values => box.values;

  @override
  Iterable valuesBetween({startKey, endKey}) {
    // TODO: implement valuesBetween
    throw UnimplementedError();
  }

  @override
  Stream<BoxEvent> watch({key}) {
    // TODO: implement watch
    throw UnimplementedError();
  }
}
