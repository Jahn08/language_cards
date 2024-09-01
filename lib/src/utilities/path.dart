class Path {
  static const String _separator = '/';

  Path._();

  static String combine(Iterable<String> parts) => parts.join(_separator);

  static String getFileName(String path) => path.split(_separator).last;

  static String stripFileExtension(String fileName) {
    const extSeparator = '.';
    final parts = fileName.split(extSeparator);
    final partsNumber = parts.length;
    return partsNumber < 3
        ? parts.first
        : parts.take(partsNumber - 1).join(extSeparator);
  }
}
