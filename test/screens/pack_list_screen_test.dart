import 'package:language_cards/src/screens/pack_list_screen.dart';
import '../utilities/list_screen_tester.dart';
import '../utilities/mock_pack_storage.dart';

void main() {
    new ListScreenTester('Pack', () => new PackListScreen(new MockPackStorage()))
        .testEditorMode();
}
