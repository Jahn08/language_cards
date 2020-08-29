import 'dart:math';
import '../models/word.dart';

class WordStorage {
    final List<Word> _words = _generateWords(50);

    Future<List<Word>> getWords({ int skipCount, int takeCount }) {
        return Future.delayed(
            new Duration(milliseconds: new Random().nextInt(1000)),
                () => _words.skip(skipCount ?? 0).take(takeCount ?? 10).toList());
    }

    Future<bool> saveWord(Word word) async {
        if (word.id > 0)
            _words.removeWhere((w) => w.id == word.id);

        _words.add(word);

        return Future.value(true);
    }

    dispose() { }

    // TODO: A temporary method to debug rendering a list of words
    static List<Word> _generateWords(int length) {
        final list = new List<Word>.generate(length, (index) {
            final random = new Random();
            return new Word(random.nextDouble().toString(), 
                id: index, 
                partOfSpeech: Word.PARTS_OF_SPEECH[random.nextInt(Word.PARTS_OF_SPEECH.length)],
                translations: new List<String>.generate(random.nextInt(7), 
                    (index) => random.nextDouble().toString())
            );
        });

        list.sort((a, b) => a.text.compareTo(b.text));
        return list;
    }
}
