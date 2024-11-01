import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:language_cards/src/data/pack_storage.dart';
import 'package:language_cards/src/models/language.dart';
import 'package:language_cards/src/models/stored_word.dart';
import 'package:language_cards/src/utilities/pack_exporter.dart';
import 'package:language_cards/src/utilities/pack_importer.dart';
import '../../mocks/pack_storage_mock.dart';
import '../../testers/exporter_tester.dart';
import '../../mocks/context_channel_mock.dart';
import '../../utilities/localizator.dart';
import '../../utilities/randomiser.dart';

void main() {
  testWidgets(
      'Imports packs from a JSON-file even if there are already packs with equal names',
      (_) async {
    await ContextChannelMock.testWithChannel(() async {
      final packStorage = new PackStorageMock();
      final packsToExport = ExporterTester.getPacksForExport(packStorage);

      final filePath = await new PackExporter(packStorage.wordStorage).export(
          packsToExport,
          Randomiser.nextString(),
          Localizator.defaultLocalization);
      await new ExporterTester(filePath)
          .assertImport(packStorage, packsToExport);
    });
  });

  testWidgets('Imports equally named packs from a JSON-file', (_) async {
    await ContextChannelMock.testWithChannel(() async {
      final packStorage = new PackStorageMock(packsNumber: 2);
      final packToExport = packStorage.getRandom();

      var allWords = await packStorage.wordStorage.fetch();
      final packToExportWordsNumber =
          allWords.where((w) => w.packId == packToExport.id).length;

      final sameLangPackToExport = new StoredPack(packToExport.name,
          from: packToExport.from, to: packToExport.to);
      final diffLangPackToExport = new StoredPack(packToExport.name,
          from: Language.values.firstWhere(
              (l) => l != packToExport.from && l != packToExport.to),
          to: packToExport.to);
      await packStorage.upsert([sameLangPackToExport, diffLangPackToExport]);

      final wordsToExport =
          allWords.where((w) => w.packId == null).take(2).toList();
      wordsToExport[0].packId = sameLangPackToExport.id;
      wordsToExport[1].packId = diffLangPackToExport.id;
      await packStorage.wordStorage
          .upsert([wordsToExport[0], wordsToExport[1]]);

      final packsToExport = [
        packToExport,
        sameLangPackToExport,
        diffLangPackToExport
      ];
      final filePath = await new PackExporter(packStorage.wordStorage).export(
          packsToExport,
          Randomiser.nextString(),
          Localizator.defaultLocalization);

      final imports = await new PackImporter(packStorage,
              packStorage.wordStorage, Localizator.defaultLocalization)
          .import(filePath);
      expect(imports.length, packsToExport.length);
      expect(
          imports.entries.every((e) => e.key.name == packToExport.name), true);

      allWords = await packStorage.wordStorage.fetch();

      final importedPack = imports.entries.singleWhere((p) =>
          p.key.from == packToExport.from &&
          p.key.to == packToExport.to &&
          p.value.length > 1);
      expect(importedPack.value.length, packToExportWordsNumber);
      expect(allWords.where((w) => w.packId == importedPack.key.id).length,
          packToExportWordsNumber);

      final importedSameLangPack = imports.entries.singleWhere((p) =>
          p.key.from == packToExport.from &&
          p.key.to == packToExport.to &&
          p.value.length == 1);
      expect(
          allWords
              .where((w) =>
                  w.packId == importedSameLangPack.key.id &&
                  w.text == wordsToExport[0].text)
              .length,
          1);
      expect(importedSameLangPack.value.single.packId,
          importedSameLangPack.key.id);
      expect(importedSameLangPack.value.single.text, wordsToExport[0].text);

      final importedDiffLangPack = imports.entries.singleWhere((p) =>
          p.key.from == diffLangPackToExport.from &&
          p.key.to == diffLangPackToExport.to);
      expect(
          allWords
              .where((w) =>
                  w.packId == importedDiffLangPack.key.id &&
                  w.text == wordsToExport[1].text)
              .length,
          1);
      expect(importedDiffLangPack.value.single.packId,
          importedDiffLangPack.key.id);
      expect(importedDiffLangPack.value.single.text, wordsToExport[1].text);
    });
  });

  testWidgets('Imports a pack with no cards from a JSON-file', (_) async {
    await ContextChannelMock.testWithChannel(() async {
      final packStorage = new PackStorageMock();
      final emptyPack =
          PackStorageMock.generatePack(Randomiser.nextInt(99) + 11);

      final packProps = emptyPack.toJsonMap([]);
      packProps.removeWhere((_, val) => val == null);

      final filePath = ExporterTester.writeToJsonFile([packProps]);
      await new ExporterTester(filePath).assertImport(packStorage, [emptyPack]);
    });
  });

  test('Imports nothing from a non-existent file', () async {
    final packStorage = new PackStorageMock();

    FileSystemException? err;
    Map<StoredPack, List<StoredWord>>? outcome;
    try {
      outcome = await new PackImporter(packStorage, packStorage.wordStorage,
              Localizator.defaultLocalization)
          .import(Randomiser.nextString());
    } on ImportException catch (ex) {
      err = ex.error as FileSystemException;
    }

    expect(outcome, null);
    expect(err == null, false);
  });

  testWidgets('Imports nothing from a JSON-file with a wrong format',
      (_) async {
    await ContextChannelMock.testWithChannel(() async {
      final filePath = ExporterTester.writeToJsonFile([
        Randomiser.nextString(),
        Randomiser.nextInt(),
        Randomiser.nextString()
      ]);

      ImportException? err;

      try {
        final packStorage = new PackStorageMock();
        await new PackImporter(packStorage, packStorage.wordStorage,
                Localizator.defaultLocalization)
            .import(filePath);
      } on ImportException catch (ex) {
        err = ex;
      }

      expect(err == null, false);
    });
  });
}
