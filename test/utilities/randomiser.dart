import 'dart:math';

class Randomiser {
    static String buildRandomString() => (new Random().nextDouble() * 1000000).toString();

    static T getRandomElement<T>(List<T> list) => list[new Random().nextInt(list.length)];
}
