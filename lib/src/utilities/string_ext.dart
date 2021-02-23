String joinPaths(Iterable<String> parts) => parts.join('/');

bool isNullOrEmpty(String str) => str == null || str.isEmpty;

String getValueOrDefault(String val, String def) => isNullOrEmpty(val) ? val: def;
