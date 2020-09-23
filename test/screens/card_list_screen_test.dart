import 'package:language_cards/src/screens/card_list_screen.dart';
import '../utilities/list_screen_tester.dart';
import '../utilities/mock_word_storage.dart';

void main() {
    new ListScreenTester('Card', () => new CardListScreen(new MockWordStorage()))
        .testEditorMode();
}
