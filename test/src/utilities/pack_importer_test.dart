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
			
			final filePath = await new PackExporter(packStorage.wordStorage)
				.export(packsToExport, Randomiser.nextString());
			await new ExporterTester(filePath)
				.assertImportedPacks(packStorage, packsToExport);
		});
	});

	test('Imports a pack with no cards from a JSON-file', () async {
		await FakePathProviderPlatform.testWithinPathProviderContext(() async {
			final packStorage = new PackStorageMock();
			final emptyPack = PackStorageMock.generatePack(Randomiser.nextInt(99) + 11);
			
			final packProps = emptyPack.toJsonMap(null);
			packProps.removeWhere((_, val) => val == null);

			final filePath = await _writeToJsonFile([packProps]);
			await new ExporterTester(filePath).assertImportedPacks(packStorage, [emptyPack]);
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
			final filePath = await _writeToJsonFile([Randomiser.nextString(), 
				Randomiser.nextInt(), Randomiser.nextString()]);
			
			final packStorage = new PackStorageMock();
			final outcome = await new PackImporter(packStorage, packStorage.wordStorage)
				.import(filePath);
			expect(outcome, null);
		});
	});
}

Future<String> _writeToJsonFile(dynamic obj) async {
	final dir = (await getExternalStorageDirectory()).path;

	final jsonFileName = Randomiser.nextString() + '.json';
	final jsonFile = new File(joinPaths([dir, jsonFileName]));
	jsonFile.createSync(recursive: true);

	jsonFile.writeAsStringSync(jsonEncode(obj), flush: true);
	return jsonFile.path;
} 
