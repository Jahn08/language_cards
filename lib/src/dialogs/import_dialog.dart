import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import '../data/base_storage.dart';
import '../models/stored_pack.dart';
import '../models/stored_word.dart';
import '../utilities/pack_importer.dart';
import '../widgets/styled_text_field.dart';
import 'cancellable_dialog.dart';

class _ImportFormDialogState extends State<_ImportFormDialog> {
    final _key = new GlobalKey<FormState>();

	String _importFilePath;

	@override
	Widget build(BuildContext context) {
		final locale = AppLocalizations.of(context);
		return new AlertDialog(
			content: new Container(
				height: MediaQuery.of(context).size.height * 0.2,
				child: _buildForm(locale)
			),
			title: new Text(locale.importDialogTitle),
			actions: [
				widget.cancelButton,
				RaisedButton(
					child: new Text(locale.importDialogImportBtnLabel), 
					onPressed: () async {
						final state = _key.currentState;
						if (!state.validate())
							return null;

						state.save();

						widget.fileProcessor?.call(_importFilePath);
					}
				)
			]
		);
	}

	Widget _buildForm(AppLocalizations locale) => 
		new Form(
			key: _key,
			child: new Column(
				children: [
					new StyledTextField(
						locale.importDialogFileNameTextFieldLabel,
						onChanged: (value, _) => setState(() => this._importFilePath = value),
						initialValue: this._importFilePath,
						isRequired: true,
						readonly: true
					),
					new RaisedButton(
						child: new Text(locale.importDialogFileSelectorBtnLabel),
						onPressed: () async {
							final fileResult = await FilePicker.platform.pickFiles(
								allowedExtensions: ['json'],
								type: FileType.custom,
								withData: true
							);

							final filePath = fileResult.paths.firstWhere(
								(_) => true, orElse: () => null);
							setState(() => _importFilePath = filePath);
						}
					)
				]
			)
		);
}

class _ImportFormDialog extends StatefulWidget {

	final RaisedButton cancelButton;

	final Function(String) fileProcessor;

	_ImportFormDialog(this.cancelButton, this.fileProcessor);

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
				buildCancelBtn(context, null),
				(filePath) async {
					final outcome = await new PackImporter(packStorage, cardStorage).import(filePath);
					returnResult(context, new ImportDialogResult(filePath, outcome));
				}
			)
        );
    }
}
