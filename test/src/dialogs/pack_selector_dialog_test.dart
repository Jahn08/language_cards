import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/dialogs/pack_selector_dialog.dart';
import 'package:language_cards/src/models/stored_pack.dart';
import 'package:language_cards/src/widgets/card_number_indicator.dart';
import '../../mocks/pack_storage_mock.dart';
import '../../testers/selector_dialog_tester.dart';

void main() {

    testWidgets('Shows the pack dialog according to items passed as arguments', (tester) async {
        final storage = new PackStorageMock();
        final chosenPack = storage.getRandom();

        final dialogTester = new SelectorDialogTester(tester, 
            (context) => _buildDialog(context, chosenPack.id));
        await dialogTester.testRenderingOptions(await _generatePacks(tester, storage), 
            (finder, pack) {
                final option = tester.widget<SimpleDialogOption>(finder);

                final optionTile = option.child as ListTile;
                expect((optionTile.title as Text).data, pack.name);
                expect((optionTile.subtitle as CardNumberIndicator).number, pack.cardsNumber);
                expect(optionTile.trailing != null, pack.id == chosenPack.id);
            }, ListTile);
    });

    testWidgets('Returns a chosen pack and hides the dialog', (tester) async {
        final dialogTester = new SelectorDialogTester(tester, _buildDialog);
        await dialogTester.testTappingItem(await _generatePacks(tester));
    });

    testWidgets('Returns null after tapping the cancel button of the pack dialog', 
        (tester) async {
            final dialogTester = new SelectorDialogTester(tester, _buildDialog);
            await dialogTester.testCancelling(await _generatePacks(tester));
        });
}

Future<List<StoredPack>> _generatePacks(WidgetTester tester, [PackStorageMock storage]) async {
    storage = storage ?? new PackStorageMock();
        
    List<StoredPack> packs;
    await tester.runAsync(() async => packs = await storage.fetch());
    
    return packs;
}

PackSelectorDialog _buildDialog(BuildContext context, [int chosenPackId]) => 
    new PackSelectorDialog(context, chosenPackId);
