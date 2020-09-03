import 'dart:math';

class Randomiser {
    static int nextInt([int maxLength]) => 
        new Random().nextInt((maxLength ?? 0) > 0 ? maxLength : 10);

    static String nextString() => (new Random().nextDouble() * 1000000).toString();
    
    static List<String> nextStringList({ int minLength, int maxLength }) {
        maxLength = maxLength ?? 10;
        var length = new Random().nextInt(maxLength) + (minLength ?? 0);
        return new List<String>.generate((length >= maxLength ? maxLength : length) + 1, 
            (_) => nextString());
    }

    static T nextElement<T>(List<T> list) => list[new Random().nextInt(list.length)];
}
