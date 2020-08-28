import 'dart:math';

class Randomiser {
    static int buildRandomInt([int maxLength]) => 
        new Random().nextInt((maxLength ?? 0) > 0 ? maxLength : 10);

    static String buildRandomString() => (new Random().nextDouble() * 1000000).toString();
    
    static List<String> buildRandomStringList({ int minLength, int maxLength }) {
        maxLength = maxLength ?? 10;
        var length = new Random().nextInt(maxLength) + (minLength ?? 0);
        return new List<String>.generate((length >= maxLength ? maxLength : length) + 1, 
            (_) => buildRandomString());
    }

    static T getRandomElement<T>(List<T> list) => list[new Random().nextInt(list.length)];
}
