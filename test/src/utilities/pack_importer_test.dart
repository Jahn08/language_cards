import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/utilities/pack_exporter.dart';
import 'package:language_cards/src/utilities/pack_importer.dart';
import 'package:language_cards/src/utilities/string_ext.dart';
import 'package:path_provider/path_provider.dart';
import '../../mocks/pack_storage_mock.dart';
import '../../testers/exporter_tester.dart';
import '../../utilities/fake_path_provider_platform.dart';
import '../../utilities/randomiser.dart';

main() {

	test('Imports packs from a JSON-file even if there are already packs with equal names', () async {
		await FakePathProviderPlatform.testWithinPathProviderContext(() async {
			final packStorage = new PackStorageMock();
			final packsToExport = ExporterTester.getPacksForExport(packStorage);
			
			final filePostfix = Randomiser.nextString();
			final expectedFilePath = await new PackExporter(packStorage.wordStorage)
				.export(packsToExport, filePostfix);
			
			final outcome = await new PackImporter(packStorage, packStorage.wordStorage)
				.import(expectedFilePath);
			expect(outcome == null, false);
			expect(outcome.length, packsToExport.length);
			
			final packedCards = await packStorage.wordStorage.fetchFiltered(
				parentIds: packsToExport.map((p) => p.id).toList());
			for (final originalPack in packsToExport) {
				final importedPackObj = outcome.entries
					.singleWhere((e) => e.key.name == originalPack.name);
				final importedPack = importedPackObj.key;
				expect(importedPack.isNew, false);
				expect(importedPack.id == originalPack.id, false);
				
				ExporterTester.assertPacksAreEqual(importedPack, originalPack);

				final storedPack = await packStorage.find(importedPack.id);
				ExporterTester.assertPacksAreEqual(importedPack, storedPack);

				final importedCards = importedPackObj.value;
				final originalCards = packedCards.where((c) => c.packId == originalPack.id).toList();
				expect(importedCards.length, originalCards.length);

				originalCards.forEach((originalCard) {
					final importedCard = importedCards.singleWhere((c) => c.text == originalCard.text);
					expect(importedCard.isNew, false);
					expect(importedCard.id == originalCard.id, false);
					expect(importedCard.packId, importedPack.id);
					
					ExporterTester.assertCardsAreEqual(importedCard, originalCard);
				});
			}

			final storedCards = await packStorage.wordStorage.fetchFiltered(
				parentIds: outcome.keys.map((c) => c.id).toList());
			final importedCards = outcome.values.expand((cards) => cards);
			expect(importedCards.length, storedCards.length);

			storedCards.forEach((storedCard) => 
				ExporterTester.assertCardsAreEqual(
					importedCards.singleWhere((c) => c.id == storedCard.id), storedCard));
		});
	});

	test('Imports nothing from a non-existent file', () async { 
		final packStorage = new PackStorageMock();
		final outcome = await new PackImporter(packStorage, packStorage.wordStorage)
			.import(Randomiser.nextString());
		expect(outcome, null);
	});

	test('Imports nothing from a JSON-file with a wrong format', () async { 
		await FakePathProviderPlatform.testWithinPathProviderContext(() async {
			final dir = (await getExternalStorageDirectory()).path;

			final jsonFileName = Randomiser.nextString() + '.json';
			final jsonFile = new File(joinPaths([dir, jsonFileName]));
			jsonFile.createSync(recursive: true);
			
			final randomObj = [Randomiser.nextString(), Randomiser.nextInt(),
				Randomiser.nextString()];
			jsonFile.writeAsStringSync(jsonEncode(randomObj), flush: true);

			final packStorage = new PackStorageMock();
			final outcome = await new PackImporter(packStorage, packStorage.wordStorage)
				.import(jsonFile.path);
			expect(outcome, null);
		});
	});
}
