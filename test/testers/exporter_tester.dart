import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/data/pack_storage.dart';
import 'package:language_cards/src/models/stored_word.dart';
import 'package:language_cards/src/utilities/pack_importer.dart';
import 'package:language_cards/src/utilities/path.dart';
import '../mocks/pack_storage_mock.dart';
import '../mocks/path_provider_channel_mock.dart';
import '../utilities/localizator.dart';
import '../utilities/randomiser.dart';

class ExporterTester {

	final String exportFilePath;

	ExporterTester(this.exportFilePath);

	void assertExportFileName(String expectedFilePostfix) =>
		expect(exportFilePath.endsWith(expectedFilePostfix + '.json'), true);

	Future<void> assertExportedPacks(
		PackStorageMock packStorage, List<StoredPack> packsToExport
	) async {
		final expectedFile = new File(exportFilePath);
		expect(expectedFile.existsSync(), true);

		final packObjs = jsonDecode(expectedFile.readAsStringSync()) as List<dynamic>;
		expect(packObjs?.length, packsToExport.length);

		final packedCards = await packStorage.wordStorage.fetchFiltered(
			parentIds: packsToExport.map((p) => p.id).toList());

		for (final obj in packObjs) {
			final exportedPackWithCards = StoredPack.fromJsonMap(obj);
			final exportedPack = exportedPackWithCards.key;
			expect(exportedPack.id, null);
			
			final originalPack = packsToExport.singleWhere((p) => p.name == exportedPack.name);
			assertPacksAreEqual(exportedPack, originalPack);	

			final exportedCards = exportedPackWithCards.value;
			final originalCards = packedCards.where((c) => c.packId == originalPack.id).toList();
			expect(exportedCards.length, originalCards.length);

			exportedCards.forEach((cardDescr) {
				final exportedCard = StoredWord.fromDbMap(jsonDecode(cardDescr));
				expect(exportedCard.id, null);
				expect(exportedCard.packId, null);
				
				final card = originalCards.singleWhere((c) => c.text == exportedCard.text);
				assertCardsAreEqual(exportedCard, card);
			});
		}
	}

	static void assertPacksAreEqual(StoredPack actual, StoredPack expected) {
		expect(actual.from, expected.from);
		expect(actual.to, expected.to);
	}

	static void assertCardsAreEqual(StoredWord actual, StoredWord expected) {
		expect(actual.transcription, expected.transcription);
		expect(actual.translation, expected.translation);
		expect(actual.partOfSpeech, expected.partOfSpeech);
		expect(actual.studyProgress, expected.studyProgress);
	}

	static List<StoredPack> getPacksForExport(PackStorageMock packStorage) {
		final firstPack = packStorage.getRandom();

		StoredPack secondPack;
		do {
			secondPack = packStorage.getRandom();
		} while (secondPack.id == firstPack.id);
		
		final newPack = PackStorageMock.generatePack(Randomiser.nextInt(9) + 99);
		return [firstPack, secondPack,
			new StoredPack('A_${newPack.name}', cardsNumber: 0, 
				from: newPack.from, to: newPack.to, id: newPack.id)];
	}

	Future<void> assertImport(
		PackStorageMock packStorage, List<StoredPack> originalPacks
	) async {
		final imports = await new PackImporter(packStorage, packStorage.wordStorage, 
			Localizator.defaultLocalization).import(exportFilePath);
		expect(imports == null, false);
		expect(imports.length, originalPacks.length);

		final packedCards = await packStorage.wordStorage.fetchFiltered(
			parentIds: originalPacks.map((p) => p.id).toList());
		for (final originalPack in originalPacks) {
			final importedPackObj = imports.entries.singleWhere((e) => 
				e.key.name == originalPack.name);
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
			parentIds: imports.keys.map((p) => p.id).toList());
		final importedCards = imports.values.expand((cards) => cards);
		expect(importedCards.length, storedCards.length);

		storedCards.forEach((storedCard) => 
			ExporterTester.assertCardsAreEqual(
				importedCards.singleWhere((c) => c.id == storedCard.id), storedCard));
	}

	static String writeToJsonFile(dynamic obj) {
		final dir = PathProviderChannelMock.getExternalStoragePath();

		final jsonFileName = Randomiser.nextString() + '.json';
		final jsonFile = new File(Path.combine([dir, jsonFileName]));
		jsonFile.createSync(recursive: true);

		jsonFile.writeAsStringSync(jsonEncode(obj), flush: true);
		return jsonFile.path;
	} 
}
