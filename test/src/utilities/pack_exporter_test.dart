import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/utilities/pack_exporter.dart';
import '../../mocks/pack_storage_mock.dart';
import '../../testers/exporter_tester.dart';
import '../../utilities/fake_path_provider_platform.dart';
import '../../utilities/randomiser.dart';

main() {

	testWidgets('Exports packs to a JSON-file', (tester) async {
		await FakePathProviderPlatform.testWithinPathProviderContext(tester, () async {
			final packStorage = new PackStorageMock();
			final packsToExport = ExporterTester.getPacksForExport(packStorage);
			
			final filePostfix = Randomiser.nextString();
			final expectedFilePath = await new PackExporter(packStorage.wordStorage)
				.export(packsToExport, filePostfix);
			
			final exporterTester = new ExporterTester(expectedFilePath);
			exporterTester.assertExportFileName(filePostfix);
			await exporterTester.assertExportedPacks(packStorage, packsToExport);
		});
	});

	testWidgets('Exports packs to a JSON-file with a numbered name if there is already one named equally', 
		(tester) async {
			await FakePathProviderPlatform.testWithinPathProviderContext(tester, () async {
				final packStorage = new PackStorageMock();
				final packsToExport = ExporterTester.getPacksForExport(packStorage);

				final filePostfix = Randomiser.nextString();
				await new PackExporter(packStorage.wordStorage).export(packsToExport, filePostfix);
				
				final expectedFilePath = await new PackExporter(packStorage.wordStorage)
					.export(packsToExport, filePostfix);

				final exporterTester = new ExporterTester(expectedFilePath);
				exporterTester.assertExportFileName(filePostfix + '_1');
				await exporterTester.assertExportedPacks(packStorage, packsToExport);
			});
		});
}
