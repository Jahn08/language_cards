import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/data/pack_storage.dart';
import 'package:language_cards/src/models/stored_word.dart';
import '../mocks/pack_storage_mock.dart';

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
			final exportedPack = StoredPack.fromDbMap(obj);
			expect(exportedPack.id, null);

			final originalPack = packsToExport.singleWhere((p) => p.name == exportedPack.name);
			expect(exportedPack.from, originalPack.from);
			expect(exportedPack.to, originalPack.to);

			final exportedCards = obj[StoredPack.cardsFieldName] as List<dynamic>;
			final originalCards = packedCards.where((c) => c.packId == originalPack.id).toList();
			expect(exportedCards.length, originalCards.length);

			exportedCards.forEach((cardDescr) {
				final exportedCard = StoredWord.fromDbMap(jsonDecode(cardDescr));
				expect(exportedCard.id, null);
				expect(exportedCard.packId, null);

				final card = originalCards.singleWhere((c) => c.text == exportedCard.text);
				expect(exportedCard.transcription, card.transcription);
				expect(exportedCard.translation, card.translation);
				expect(exportedCard.partOfSpeech, card.partOfSpeech);
			});
		}
	}
}
