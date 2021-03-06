import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:language_cards/src/data/study_storage.dart';
import 'package:language_cards/src/models/stored_pack.dart';
import 'package:language_cards/src/models/word_study_stage.dart';
import 'package:language_cards/src/screens/study_preparer_screen.dart';
import '../../mocks/pack_storage_mock.dart';
import '../../mocks/root_widget_mock.dart';
import '../../utilities/assured_finder.dart';
import '../../utilities/localizator.dart';
import '../../utilities/widget_assistant.dart';

main() {

    testWidgets('Renders card packs as selected displaying their number of cards and study levels', 
        (tester) async {
            final storage = await _pumpScreen(tester);

            final packs = await _fetchNamedPacks(tester, storage);
            expect(_findCheckTiles(), findsNWidgets(packs.length));
            
            await _assureCheckedTiles(tester, packs, (p, packTileFinder) {
                expect(find.descendant(
					of: packTileFinder, 
                    matching: find.text(
						Localizator.defaultLocalization.cardNumberIndicatorContent(p.cardsNumber))
					), findsOneWidget);
            });

            final studyPacks = await _fetchStudyPacks(tester, storage);
            _assureCardNumbersForStudyLevels(studyPacks);
        });

    testWidgets('Unselects/selects all card packs changing the summary of their study levels', 
        (tester) async {
            final storage = await _pumpScreen(tester);
            
            final packs = await _fetchNamedPacks(tester, storage);
            final studyPacks = await _fetchStudyPacks(tester, storage);

            final widgetAssistant = new WidgetAssistant(tester);
			final selectorBtnFinder = AssuredFinder.findOne(
				icon: Icons.select_all, 
				shouldFind: true
			);
            await widgetAssistant.tapWidget(selectorBtnFinder);

            await _assureCheckedTiles(tester);
            _assureCardNumbersForStudyLevels(studyPacks, []);

            await widgetAssistant.tapWidget(selectorBtnFinder);
            
            await _assureCheckedTiles(tester, packs);
            _assureCardNumbersForStudyLevels(studyPacks);
        });

    testWidgets('Unselects/selects some card packs changing the summary of their study levels', 
        (tester) async {
            final storage = await _pumpScreen(tester);

            final studyPacks = await _fetchStudyPacks(tester, storage);

            final packs = await _fetchNamedPacks(tester, storage);
            final packsToUncheck = <StoredPack>[packs.first, packs.last];
            
            final assistant = new WidgetAssistant(tester);
            
            for (final p in _sortPacksByName(packsToUncheck)) {
                final packTileFinder = await _findPackTile(assistant, p.name);
                await assistant.tapWidget(packTileFinder);
            }

            final uncheckedPackIds = packsToUncheck.map((p) => p.id).toList();
            final checkedPacks = packs.where((p) => !uncheckedPackIds.contains(p.id)).toList();
            await _assureCheckedTiles(tester, checkedPacks);
            _assureCardNumbersForStudyLevels(studyPacks, 
                checkedPacks.map((p) => p.id).toList());

            final packToCheck = packsToUncheck.last;
            final packTileFinder = await _findPackTile(assistant, packToCheck.name);
            await assistant.tapWidget(packTileFinder);

            checkedPacks.add(packToCheck);
            await _assureCheckedTiles(tester, checkedPacks);
            _assureCardNumbersForStudyLevels(studyPacks, 
                checkedPacks.map((p) => p.id).toList());
        });
}

List<StoredPack> _sortPacksByName(List<StoredPack> packs) => 
	packs..sort((a, b) => a.name.compareTo(b.name));

Future<StudyStorage> _pumpScreen(WidgetTester tester) async {
    final storage = new PackStorageMock();
    await tester.pumpWidget(
        RootWidgetMock.buildAsAppHome(child: new StudyPreparerScreen(storage), noBar: true));
    await tester.pump(new Duration(milliseconds: 500));

    return storage;
}

Future<List<StoredPack>> _fetchNamedPacks(WidgetTester tester, PackStorageMock storage) async =>
    (await tester.runAsync<List<StoredPack>>(() => storage.fetch()))
        .where((p) => !p.isNone).toList();

Future<List<StudyPack>> _fetchStudyPacks(WidgetTester tester, PackStorageMock storage) =>
    tester.runAsync<List<StudyPack>>(() => storage.fetchStudyPacks());

Finder _findCheckTiles() =>
    AssuredFinder.findSeveral(type: CheckboxListTile, shouldFind: true);

Future<void> _assureCheckedTiles(WidgetTester tester, 
    [List<StoredPack> checkedPacks, void Function(StoredPack, Finder) tileChecker]) async {

    if (checkedPacks == null || checkedPacks.isEmpty) {
		expect(tester.widgetList<CheckboxListTile>(_findCheckTiles()).every((t) => t.value), 
            false);
		return;
	}
        
	final assistant = new WidgetAssistant(tester);
	final sortedPacks = _sortPacksByName(checkedPacks);

	Finder packTileFinder = await _findPackTile(assistant, sortedPacks.first.name, searchUpwards: true);
	for (final p in sortedPacks) {
		if (packTileFinder == null)
			packTileFinder = await _findPackTile(assistant, p.name);
		
		expect(tester.widget<CheckboxListTile>(packTileFinder).value, true);

		tileChecker?.call(p, packTileFinder);
		
		packTileFinder = null;
	}
}

Future<Finder> _findPackTile(WidgetAssistant assistant, String packName, { bool searchUpwards }) async {
    final packTileFinder = find.ancestor(of: find.text(packName), 
        matching: find.byType(CheckboxListTile));
	final visibleFinder = await assistant.scrollUntilVisible(
		packTileFinder, CheckboxListTile, upwards: searchUpwards ?? false);
    expect(visibleFinder, findsOneWidget);
    return visibleFinder;
}

void _assureCardNumbersForStudyLevels(Iterable<StudyPack> stPacks, [List<int> includedPackIds]) {
    final studyStages = new Map<int, int>.fromIterable(WordStudyStage.values,
        key: (k) => k, value: (_) => 0);

    if (includedPackIds != null)
        stPacks = stPacks.where((p) => includedPackIds.contains(p.pack.id));

    stPacks.expand((e) => e.cardsByStage.entries).forEach((en) =>
        studyStages[en.key] += en.value);

	final locale = Localizator.defaultLocalization;
	final levels = <String, int>{};
		studyStages.entries.forEach((en) {
			final key = WordStudyStage.stringify(en.key, locale);
			if (levels.containsKey(key))
				levels[key] += en.value;
			else
				levels[key] = en.value;
		});
    levels[locale.studyPreparerScreenAllCardsCategoryName] = 
        levels.values.reduce((res, el) => res + el);

    levels.forEach((lvl, cardNumber) { 
        final levelFinder = find.ancestor(of: find.text(lvl, skipOffstage: false), 
            matching: find.byType(ListTile, skipOffstage: false));
        expect(levelFinder, findsOneWidget);
        expect(find.descendant(of: levelFinder, 
            matching: find.text(cardNumber.toString(), skipOffstage: false)), findsOneWidget);
    });
}
