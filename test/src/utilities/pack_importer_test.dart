import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/data/pack_storage.dart';
import 'package:language_cards/src/models/stored_word.dart';
import 'package:language_cards/src/utilities/pack_exporter.dart';
import 'package:language_cards/src/utilities/pack_importer.dart';
import '../../mocks/pack_storage_mock.dart';
import '../../testers/exporter_tester.dart';
import '../../mocks/context_channel_mock.dart';
import '../../utilities/localizator.dart';
import '../../utilities/randomiser.dart';

void main() {

	testWidgets('Imports packs from a JSON-file even if there are already packs with equal names', 
		(_) async {
			await ContextChannelMock.testWithChannel(() async {
				final packStorage = new PackStorageMock();
				final packsToExport = ExporterTester.getPacksForExport(packStorage);
				
				final filePath = await new PackExporter(packStorage.wordStorage)
					.export(packsToExport, Randomiser.nextString(), Localizator.defaultLocalization);
				await new ExporterTester(filePath).assertImport(packStorage, packsToExport);
			});
		});

	testWidgets('Imports a pack with no cards from a JSON-file', (_) async {
		await ContextChannelMock.testWithChannel(() async {
			final packStorage = new PackStorageMock();
			final emptyPack = PackStorageMock.generatePack(Randomiser.nextInt(99) + 11);
			
			final packProps = emptyPack.toJsonMap(null);
			packProps.removeWhere((_, val) => val == null);

			final filePath = ExporterTester.writeToJsonFile([packProps]);
			await new ExporterTester(filePath).assertImport(packStorage, [emptyPack]);
		});
	});

	test('Imports nothing from a non-existent file', () async {
		final packStorage = new PackStorageMock();
		
		FileSystemException err;
		Map<StoredPack, List<StoredWord>> outcome;
		try {
			outcome = await new PackImporter(packStorage, packStorage.wordStorage, 
				Localizator.defaultLocalization).import(Randomiser.nextString());
		}
		on ImportException catch (ex) {
			err = ex.error as FileSystemException;
		}

		expect(outcome, null);
		expect(err == null, false);
	});

	testWidgets('Imports nothing from a JSON-file with a wrong format', (_) async { 
		await ContextChannelMock.testWithChannel(() async {
			final filePath = ExporterTester.writeToJsonFile([Randomiser.nextString(), 
				Randomiser.nextInt(), Randomiser.nextString()]);

			ImportException err;
			
			try {
				final packStorage = new PackStorageMock();
				await new PackImporter(packStorage, packStorage.wordStorage, 
					Localizator.defaultLocalization).import(filePath);
				fail('The $PackImporter should have failed');
			}
			on ImportException catch (ex) {
				err = ex;
			}
		
			expect(err == null, false);
		});
	});
}
