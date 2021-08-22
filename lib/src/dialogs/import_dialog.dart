import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import '../data/base_storage.dart';
import '../dialogs/confirm_dialog.dart';
import '../models/stored_pack.dart';
import '../models/stored_word.dart';
import '../utilities/context_provider.dart';
import '../utilities/pack_importer.dart';
import '../widgets/styled_text_field.dart';
import 'cancellable_dialog.dart';

class _ImportFormDialogState extends State<_ImportFormDialog> {
	static const String _jsonExtension = 'json';

    final _key = new GlobalKey<FormState>();

	final _importFilePathNotifier = new ValueNotifier<String>(null);

	bool _isJsonMimeSupported;

	@override
	Widget build(BuildContext context) {
		final locale = AppLocalizations.of(context);
		return new AlertDialog(
			content: new SizedBox(
				height: MediaQuery.of(context).size.height * 0.2,
				child: new Form(
					key: _key,
					child: new Column(
						children: [
							new ValueListenableBuilder(
								valueListenable: _importFilePathNotifier,
								builder: (_, String importFilePath, __) =>
									new StyledTextField(
										locale.importDialogFileNameTextFieldLabel,
										onChanged: (value, _) => _importFilePathNotifier.value = value,
										initialValue: importFilePath,
										isRequired: true,
										validator: (val) {
											return val == null || val.toLowerCase().endsWith('.$_jsonExtension') ?
												null: locale.importDialogFileNameTextFieldValidationError;
										},
									)
							),
							new ElevatedButton(
								child: new Text(locale.importDialogFileSelectorBtnLabel),
								onPressed: () async {
									_isJsonMimeSupported ??= await ContextProvider.isFileExtensionSupported(_jsonExtension);

									final fileResult = await (_isJsonMimeSupported ? FilePicker.platform.pickFiles(
										allowedExtensions: [_jsonExtension],
										type: FileType.custom
									): FilePicker.platform.pickFiles());
									
									if (fileResult == null)
										return;
										
									final filePath = fileResult.paths.firstWhere(
										(_) => true, orElse: () => null);
									_importFilePathNotifier.value = filePath;
								}
							)
						]
					)
				)
			),
			title: new Text(locale.importDialogTitle),
			actions: [
				widget.cancelButton,
				ElevatedButton(
					child: new Text(locale.importDialogImportBtnLabel), 
					onPressed: () async {
						final state = _key.currentState;
						if (!state.validate())
							return null;

						state.save();

						widget.fileProcessor?.call(_importFilePathNotifier.value);
					}
				)
			]
		);
	}

	@override
	void dispose() {
		_importFilePathNotifier.dispose();

		super.dispose();
	}
}

class _ImportFormDialog extends StatefulWidget {

	final ElevatedButton cancelButton;

	final Function(String) fileProcessor;

	const _ImportFormDialog(this.cancelButton, this.fileProcessor);

	@override
	_ImportFormDialogState createState() => new _ImportFormDialogState();
}

class ImportDialogResult {

	final Map<StoredPack, List<StoredWord>> packsWithCards;

	final String filePath;

	ImportDialogResult(this.filePath, this.packsWithCards);
}

class ImportDialog extends CancellableDialog<ImportDialogResult> {

	final BaseStorage<StoredPack> packStorage;

	final BaseStorage<StoredWord> cardStorage;

	ImportDialog(this.packStorage, this.cardStorage);

    Future<ImportDialogResult> show(BuildContext context) {
        return showDialog<ImportDialogResult>(
            context: context, 
            builder: (buildContext) => new _ImportFormDialog(
				buildCancelBtn(buildContext, null),
				(filePath) async {
					Map<StoredPack, List<StoredWord>> outcome;
					
					final locale = AppLocalizations.of(buildContext);
					try {
						outcome = await new PackImporter(packStorage, cardStorage, locale)
							.import(filePath);
					}
					catch (ex) {
						await new ConfirmDialog.ok(
							title: locale.importExportWarningDialogTitle, 
							content: locale.packListScreenImportDialogWrongFormatContent(filePath)
						).show(buildContext);

						if (!Platform.environment.containsKey('FLUTTER_TEST'))
							rethrow;
					}

     				// ignore: use_build_context_synchronously
					returnResult(buildContext, new ImportDialogResult(filePath, outcome));
				}
			)
        );
    }
}
