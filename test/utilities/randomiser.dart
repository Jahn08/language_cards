import 'dart:math';

class Randomiser {
  /// [max] is exclusive
  static int nextInt([int max]) =>
      new Random().nextInt((max ?? 0) > 0 ? max : 10);

  static String nextString() =>
      (new Random().nextDouble() * 1000000).toString();

  static List<String> nextStringList({int minLength, int maxLength}) {
    maxLength ??= 10;
    final length = new Random().nextInt(maxLength) + (minLength ?? 0);
    return new List<String>.generate(
        (length >= maxLength ? maxLength : length) + 1, (_) => nextString());
  }

  static T nextElement<T>(Iterable<T> list) =>
      list.elementAt(new Random().nextInt(list.length));
}
