import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/models/stored_pack.dart';
import 'package:language_cards/src/utilities/pack_exporter.dart';
import '../../mocks/pack_storage_mock.dart';
import '../../testers/exporter_tester.dart';
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
			
			final exporterTester = new ExporterTester(expectedFilePath);
			exporterTester.assertExportFileName(filePostfix);
			await exporterTester.assertExportedPacks(packStorage, packsToExport);
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

				final exporterTester = new ExporterTester(expectedFilePath);
				exporterTester.assertExportFileName(filePostfix + '_1');
				await exporterTester.assertExportedPacks(packStorage, packsToExport);
			});
		});
}
