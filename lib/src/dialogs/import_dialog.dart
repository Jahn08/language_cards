import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:file_picker/file_picker.dart';
import 'outcome_dialog.dart';
import '../models/stored_pack.dart';
import '../models/stored_word.dart';
import '../utilities/context_provider.dart';
import '../widgets/cancel_button.dart';
import '../widgets/one_line_text.dart';
import '../widgets/styled_text_field.dart';

class _ImportFormDialogState extends State<_ImportFormDialog> {
  static const String _jsonExtension = 'json';

  final _key = new GlobalKey<FormState>();

  final _importFilePathNotifier = new ValueNotifier<String?>('');

  bool? _isJsonMimeSupported;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context)!;
    return new AlertDialog(
        content: new SizedBox(
            height: MediaQuery.of(context).size.height * 0.2,
            child: new Form(
                key: _key,
                child: new Column(children: [
                  new ValueListenableBuilder(
                      valueListenable: _importFilePathNotifier,
                      builder: (_, String? importFilePath, __) =>
                          new StyledTextField(
                            locale.importDialogFileNameTextFieldLabel,
                            onChanged: (value, {bool? submitted}) =>
                                _importFilePathNotifier.value = value ?? '',
                            initialValue: importFilePath ?? '',
                            isRequired: true,
                            validator: (val) {
                              return val == null ||
                                      val
                                          .toLowerCase()
                                          .endsWith('.$_jsonExtension')
                                  ? null
                                  : locale
                                      .importDialogFileNameTextFieldValidationError;
                            },
                          )),
                  new ElevatedButton(
                      child: new Text(locale.importDialogFileSelectorBtnLabel),
                      onPressed: () async {
                        _isJsonMimeSupported ??=
                            await ContextProvider.isFileExtensionSupported(
                                _jsonExtension);

                        final fileResult = await (_isJsonMimeSupported!
                            ? FilePicker.platform.pickFiles(
                                allowedExtensions: [_jsonExtension],
                                type: FileType.custom)
                            : FilePicker.platform.pickFiles());

                        if (fileResult == null) return;

                        final filePath = fileResult.paths
                            .firstWhere((_) => true, orElse: () => null);
                        _importFilePathNotifier.value = filePath;
                      })
                ]))),
        title: new OneLineText(locale.importDialogTitle),
        actions: [
          widget.cancelButton,
          ElevatedButton(
              child: new Text(locale.importDialogImportBtnLabel),
              onPressed: () async {
                final state = _key.currentState;
                if (state == null || !state.validate()) return;

                state.save();

                widget.onPathChosen?.call(_importFilePathNotifier.value);
              })
        ]);
  }

  @override
  void dispose() {
    _importFilePathNotifier.dispose();

    super.dispose();
  }
}

class _ImportFormDialog extends StatefulWidget {
  final Widget cancelButton;

  final void Function(String?)? onPathChosen;

  const _ImportFormDialog(this.cancelButton, this.onPathChosen);

  @override
  _ImportFormDialogState createState() => new _ImportFormDialogState();
}

class ImportDialogResult {
  final Map<StoredPack, List<StoredWord>> packsWithCards;

  final String filePath;

  ImportDialogResult(this.filePath, this.packsWithCards);
}

class ImportDialog extends OutcomeDialog<String> {
  const ImportDialog();

  Future<String?> show(BuildContext context) {
    return showDialog<String>(
        context: context,
        builder: (buildContext) => new _ImportFormDialog(
            new CancelButton(() => returnResult(buildContext, null)),
            (filePath) => returnResult(buildContext, filePath)));
  }
}
