import 'dart:io';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/data/word_storage.dart';
import 'package:language_cards/src/models/stored_pack.dart';
import 'package:language_cards/src/utilities/pack_exporter.dart';
import '../../mocks/pack_storage_mock.dart';
import '../../utilities/fake_path_provider_platform.dart';
import '../../utilities/randomiser.dart';

main() {

	test('Exports packs to a JSON-file', () async {
		await FakePathProviderPlatform.testWithinPathProviderContext(() async {
			final packStorage = new PackStorageMock();

			final firstPack = packStorage.getRandom();

			StoredPack secondPack;
			do {
				secondPack = packStorage.getRandom();
			} while (secondPack.id == firstPack.id);
			
			final emptyPack = PackStorageMock.generatePack(Randomiser.nextInt(9) + 99);
			final filePostfix = Randomiser.nextString();
			
			final packsToExport = [firstPack, secondPack, emptyPack];
			final expectedFilePath = await new PackExporter(packStorage.wordStorage)
				.export(packsToExport, filePostfix);
			_assertExportFileName(expectedFilePath, filePostfix);

			await _assertExportedPacks(expectedFilePath, packStorage, packsToExport);
		});
	});

	test('Exports packs to a JSON-file with a numbered name if there is already one named equally', 
		() async {
			await FakePathProviderPlatform.testWithinPathProviderContext(() async {
				final packStorage = new PackStorageMock();

				final firstPack = packStorage.getRandom();

				StoredPack secondPack;
				do {
					secondPack = packStorage.getRandom();
				} while (secondPack.id == firstPack.id);
				
				final emptyPack = PackStorageMock.generatePack(Randomiser.nextInt(9) + 99);
				final filePostfix = Randomiser.nextString();
				
				final packsToExport = [firstPack, secondPack, emptyPack];
				await new PackExporter(packStorage.wordStorage).export(packsToExport, filePostfix);
				
				final expectedFilePath = await new PackExporter(packStorage.wordStorage)
					.export(packsToExport, filePostfix);
				_assertExportFileName(expectedFilePath, filePostfix + '_1');

				await _assertExportedPacks(expectedFilePath, packStorage, packsToExport);
			});
		});
}

void _assertExportFileName(String exportFilePath, String expectedFilePostfix) =>
	expect(exportFilePath.endsWith(expectedFilePostfix + '.json'), true);

Future<void> _assertExportedPacks(
	String exportFilePath, PackStorageMock packStorage, List<StoredPack> packsToExport
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
