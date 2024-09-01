import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/utilities/pack_exporter.dart';
import '../../mocks/pack_storage_mock.dart';
import '../../mocks/permission_channel_mock.dart';
import '../../testers/exporter_tester.dart';
import '../../mocks/context_channel_mock.dart';
import '../../utilities/localizator.dart';
import '../../utilities/randomiser.dart';

void main() {
  testWidgets('Exports packs to a JSON-file', (_) async {
    await ContextChannelMock.testWithChannel(() async {
      final packStorage = new PackStorageMock();
      final packsToExport = ExporterTester.getPacksForExport(packStorage);

      final filePostfix = Randomiser.nextString();
      final expectedFilePath = await new PackExporter(packStorage.wordStorage)
          .export(packsToExport, filePostfix, Localizator.defaultLocalization);

      final exporterTester = new ExporterTester(expectedFilePath);
      exporterTester.assertExportFileName(filePostfix);
      await exporterTester.assertExportedPacks(packStorage, packsToExport);
    });
  });

  testWidgets(
      'Exports packs to a JSON-file with a numbered name if there is already one named equally',
      (_) async {
    await ContextChannelMock.testWithChannel(() async {
      final packStorage = new PackStorageMock();
      final packsToExport = ExporterTester.getPacksForExport(packStorage);

      final filePostfix = Randomiser.nextString();
      await new PackExporter(packStorage.wordStorage)
          .export(packsToExport, filePostfix, Localizator.defaultLocalization);

      final expectedFilePath = await new PackExporter(packStorage.wordStorage)
          .export(packsToExport, filePostfix, Localizator.defaultLocalization);

      final exporterTester = new ExporterTester(expectedFilePath);
      exporterTester.assertExportFileName(filePostfix + '_1');
      await exporterTester.assertExportedPacks(packStorage, packsToExport);
    });
  });

  testWidgets(
      'Exports packs successfully when a user grants required permissions',
      (_) async {
    await ContextChannelMock.testWithChannel(() async {
      await PermissionChannelMock.testWithChannel(() async {
        final packStorage = new PackStorageMock();
        final packsToExport = ExporterTester.getPacksForExport(packStorage);

        final filePostfix = Randomiser.nextString();
        final expectedFilePath = await new PackExporter(packStorage.wordStorage)
            .export(
                packsToExport, filePostfix, Localizator.defaultLocalization);

        final exporterTester = new ExporterTester(expectedFilePath);
        exporterTester.assertExportFileName(filePostfix);
        await exporterTester.assertExportedPacks(packStorage, packsToExport);
      }, noPermissionsByDefault: true);
    }, arePermissionsRequired: true);
  });

  testWidgets('Throws an error when a user grants no access to an export path',
      (_) async {
    await ContextChannelMock.testWithChannel(() async {
      await PermissionChannelMock.testWithChannel(() async {
        final packStorage = new PackStorageMock();
        final packsToExport = ExporterTester.getPacksForExport(packStorage);

        final filePostfix = Randomiser.nextString();

        FileSystemException? error;
        try {
          await new PackExporter(packStorage.wordStorage).export(
              packsToExport, filePostfix, Localizator.defaultLocalization);
        } on FileSystemException catch (err) {
          error = err;
        }

        assert(error != null, true);
        assert(error.toString().contains('permissions'), true);
      }, noPermissionsByDefault: true, shouldDenyPermissions: true);
    }, arePermissionsRequired: true);
  });
}
