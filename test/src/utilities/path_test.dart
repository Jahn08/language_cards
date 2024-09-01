import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/utilities/path.dart';
import '../../utilities/randomiser.dart';

void main() {
  test('Joins an array of strings into a path string', () {
    final paths = [
      Randomiser.nextString(),
      Randomiser.nextString(),
      Randomiser.nextString()
    ];
    expect(Path.combine(paths), paths.join('/'));
  });

  test('Gets a full file name from a path', () {
    final expectedFileName = '${Randomiser.nextString()}.rand';
    final actualFileName = Path.getFileName(Path.combine(
        [Randomiser.nextString(), Randomiser.nextString(), expectedFileName]));
    expect(actualFileName, expectedFileName);
  });

  test('Gets a file name without its extension', () {
    const fileExtension = '.txt';
    final expectedFileName = Randomiser.nextString();
    final actualFileName =
        Path.stripFileExtension(expectedFileName + fileExtension);
    expect(actualFileName, expectedFileName);
  });

  test(
      'Returns a file name without changes when it has no extension to discard',
      () {
    final expectedFileName = Randomiser.nextInt(100000).toString();
    expect(Path.stripFileExtension(expectedFileName), expectedFileName);
  });
}
