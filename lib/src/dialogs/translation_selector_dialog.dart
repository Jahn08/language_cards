import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'selector_dialog.dart';
import '../utilities/styler.dart';
import '../widgets/dialog_list_view.dart';

class _CheckboxListState extends State<_CheckboxList> {
    final _chosenItems = <String>[];

    @override
    Widget build(BuildContext context) {

        return new DialogListView(
			isShrunk: true,
			buttons: this.widget.buttons,
			title: new CheckboxListTile(
				title: new Text(this.widget.title, style: new Styler(context).titleStyle),
				value: widget.items.length == _chosenItems.length,
				onChanged: (value) => setState(() {
					_chosenItems.clear();

					if (value)
						_chosenItems.addAll(this.widget.items);

					widget.onChange?.call(_chosenItems);
				})
			),
			children: widget.items.map((w) => _buildDialogOption(w)).toList()
		);
    }

    Widget _buildDialogOption(String item) => 
		new ShrinkableSimpleDialogOption(
			new CheckboxListTile(
				title: new Text(item),
				onChanged: (value) => setState(() {
					value ? _chosenItems.add(item) : _chosenItems.remove(item);
					widget.onChange?.call(_chosenItems);
				}),
				value: _chosenItems.contains(item)
			),
			isShrunk: true
		);
}

class _CheckboxList extends StatefulWidget {
    final String title;
    final List<String> items;
    final List<Widget> buttons;
    final Function(List<String>) onChange;

    _CheckboxList(this.title, this.items, 
        { @required this.onChange, @required this.buttons }): super();

    @override
    _CheckboxListState createState() {
        return new _CheckboxListState();
    }
}

class TranslationSelectorDialog extends SelectorDialog<String> {
    List<String> _chosenTranslations;

    final BuildContext _context;

    TranslationSelectorDialog(BuildContext context):
        _context = context,
        super();

    @override
    Future<String> show(List<String> items) {
		final locale = AppLocalizations.of(_context);
        items = items ?? <String>[];
        return items.length > 0 ? showDialog(
            context: _context,
            builder: (dialogContext) {
                return new _CheckboxList(
					locale.translationSelectorDialogTitle, items, 
                    onChange: (chosenItems) => _chosenTranslations = chosenItems,
                    buttons: <Widget>[
                        buildCancelBtn(_context), 
                        _buildDoneBtn(locale)
                    ]
                );
            }
        ) : Future.value(items.firstWhere((_) => true, orElse: () => null));
    }

    Widget _buildDoneBtn(AppLocalizations locale) => new ElevatedButton(
        onPressed: () => returnResult(_context, _chosenTranslations?.join('; ')),
        child: new Text(locale.translationSelectorDoneButtonLabel)
    );
}
