import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/data/pack_storage.dart';
import 'package:language_cards/src/models/stored_word.dart';
import '../mocks/pack_storage_mock.dart';
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
		
		final emptyPack = PackStorageMock.generatePack(Randomiser.nextInt(9) + 99);
		return [firstPack, secondPack, emptyPack];
	}
}
