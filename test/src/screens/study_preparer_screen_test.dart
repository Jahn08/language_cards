import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:language_cards/src/data/study_storage.dart';
import 'package:language_cards/src/models/stored_pack.dart';
import 'package:language_cards/src/models/word_study_stage.dart';
import 'package:language_cards/src/screens/study_preparer_screen.dart';
import 'package:language_cards/src/widgets/one_line_text.dart';
import '../../mocks/pack_storage_mock.dart';
import '../../mocks/root_widget_mock.dart';
import '../../utilities/assured_finder.dart';
import '../../utilities/localizator.dart';
import '../../utilities/widget_assistant.dart';

void main() {

    testWidgets('Renders card packs as selected displaying their number of cards and study levels', 
        (tester) async {
            final storage = await _pumpScreen(tester);

            final packs = await _fetchNamedPacks(tester, storage);
            expect(_findCheckTiles(), findsNWidgets(packs.length));
            
            await _assureConsecutivelyCheckedTiles(tester, packs, (p, packTileFinder) {
                expect(find.descendant(
					of: packTileFinder, 
                    matching: find.text(
						Localizator.defaultLocalization.cardNumberIndicatorContent(
							p.cardsNumber.toString()
						)
					)
				), findsOneWidget);
            });

            final studyPacks = await _fetchStudyPacks(tester, storage);
            _assureCardNumbersForStudyLevels(studyPacks);

			_findDownwardScrollBtn(shouldFind: false);
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

            await _assureConsecutivelyCheckedTiles(tester);
            _assureCardNumbersForStudyLevels(studyPacks, []);

            await widgetAssistant.tapWidget(selectorBtnFinder);
            
            await _assureConsecutivelyCheckedTiles(tester, packs);
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
            await _assureNonConsecutivelyCheckedTiles(tester, checkedPacks);
            _assureCardNumbersForStudyLevels(studyPacks, 
                checkedPacks.map((p) => p.id).toList());

            final packToCheck = packsToUncheck.last;
            final packTileFinder = await _findPackTile(assistant, packToCheck.name);
            await assistant.tapWidget(packTileFinder);

            checkedPacks.add(packToCheck);
            await _assureNonConsecutivelyCheckedTiles(tester, checkedPacks);
            _assureCardNumbersForStudyLevels(studyPacks, 
                checkedPacks.map((p) => p.id).toList());
        });

		testWidgets('Scrolls down to the end of the list of study packs and back up by clicking the floating button', 
			(tester) async {
				final storage = await _pumpScreen(tester, packsNumber: 15, cardsNumber: 50);
				final downwardScrollBtnFinder = _findDownwardScrollBtn(shouldFind: true);

				final assistant = new WidgetAssistant(tester);
				await assistant.tapWidget(downwardScrollBtnFinder); 
				const int animationTimeoutMs = 700;
				await assistant.pumpAndAnimate(animationTimeoutMs);

	            final storedPacks = _sortPacksByName(await _fetchNamedPacks(tester, storage));

				final checkTileFinder = _findCheckTiles();
				List<CheckboxListTile> checkTiles = 
					tester.widgetList<CheckboxListTile>(checkTileFinder).toList();
				final checkTilesLength = checkTiles.length;

				const itemsToTake = 3;
				int index = itemsToTake;
				storedPacks.skip(storedPacks.length - itemsToTake).forEach((p) { 
					final checkTile = checkTiles.elementAt(checkTilesLength - (index--));
					expect((checkTile.title as OneLineText).content, p.name);
				});

				expect(downwardScrollBtnFinder, findsNothing);
				
				final upwardScrollBtnFinder = AssuredFinder.findOne(
					icon: Icons.arrow_upward_rounded, shouldFind: true);
				await assistant.tapWidget(upwardScrollBtnFinder);
				await assistant.pumpAndAnimate(animationTimeoutMs);
				
				index = 0;
				checkTiles = tester.widgetList<CheckboxListTile>(checkTileFinder).toList();
				storedPacks.take(itemsToTake).forEach((p) { 
					final checkTile = checkTiles.elementAt(index++);
					expect((checkTile.title as OneLineText).content, p.name);
				});

				expect(upwardScrollBtnFinder, findsNothing);
				expect(downwardScrollBtnFinder, findsOneWidget);
			});
}

List<StoredPack> _sortPacksByName(List<StoredPack> packs) => 
	packs..sort((a, b) => a.name.compareTo(b.name));

Future<PackStorageMock> _pumpScreen(WidgetTester tester, { int packsNumber, int cardsNumber }) 
	async {
		final storage = new PackStorageMock(packsNumber: packsNumber, cardsNumber: cardsNumber);
		await tester.pumpWidget(
			RootWidgetMock.buildAsAppHome(child: new StudyPreparerScreen(storage), noBar: true));
		await tester.pump(const Duration(milliseconds: 700));

		return storage;
	}

Future<List<StoredPack>> _fetchNamedPacks(WidgetTester tester, PackStorageMock storage) async =>
    (await tester.runAsync<List<StoredPack>>(() => storage.fetch()))
        .where((p) => !p.isNone).toList();

Future<List<StudyPack>> _fetchStudyPacks(WidgetTester tester, PackStorageMock storage) =>
    tester.runAsync<List<StudyPack>>(() => storage.fetchStudyPacks());

Finder _findCheckTiles() {
	final finder = find.byType(CheckboxListTile, skipOffstage: false);
	expect(finder, findsWidgets);

	return finder;
}

Future<void> _assureConsecutivelyCheckedTiles(WidgetTester tester, 
    [List<StoredPack> checkedPacks, void Function(StoredPack, Finder) tileChecker]) async {

    if (checkedPacks == null || checkedPacks.isEmpty) {
		expect(tester.widgetList<CheckboxListTile>(_findCheckTiles()).every((t) => t.value), 
            false);
		return;
	}
        
	final sortedPacks = _sortPacksByName(checkedPacks);

	final checkTiles = _findCheckTiles();
	int index = 0;
	sortedPacks.forEach((p) { 
		final packTileFinder = checkTiles.at(index++);
		expect(tester.widget<CheckboxListTile>(packTileFinder).value, true);

		tileChecker?.call(p, packTileFinder);
	});
}

Future<void> _assureNonConsecutivelyCheckedTiles(WidgetTester tester, 
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
		packTileFinder ??= await _findPackTile(assistant, p.name);
		
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

void _assureCardNumbersForStudyLevels(Iterable<StudyPack> studyPacks, [List<int> includedPackIds]) {
    final studyStages = <int, int>{ for (var v in WordStudyStage.values) v: 0 };

	Iterable<StudyPack> stPacks = studyPacks;
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

Finder _findDownwardScrollBtn({ bool shouldFind }) => 
	AssuredFinder.findOne(icon: Icons.arrow_downward_rounded, shouldFind: shouldFind ?? false);
