class Enum {
    
    static Map<String, T> mapStringValues<T>(Iterable<T> values) {
        return new Map.fromIterable(values, key: (v) => stringifyValue(v),
            value: (v) => v);
    }

    static String stringifyValue(dynamic value) {
        final valueName = value.toString().split('.').last;
        return valueName.substring(0, 1).toUpperCase() + valueName.substring(1);
    }
}
