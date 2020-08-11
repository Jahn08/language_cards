import 'dart:math';

class Randomiser {
    static buildRandomString() => (new Random().nextDouble() * 1000000).toString();
}
