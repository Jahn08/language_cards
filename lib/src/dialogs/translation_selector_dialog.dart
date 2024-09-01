import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'selector_dialog.dart';
import '../utilities/styler.dart';
import '../widgets/cancel_button.dart';
import '../widgets/dialog_list_view.dart';

class _CheckboxListState extends State<_CheckboxList> {
  final _chosenItems = <String>{};

  @override
  Widget build(BuildContext context) {
    return new DialogListView(
        isShrunk: true,
        buttons: widget.buttons,
        title: new CheckboxListTile(
            title:
                new Text(widget.title, style: new Styler(context).titleStyle),
            value: widget.items.length == _chosenItems.length,
            onChanged: (value) => setState(() {
                  _chosenItems.clear();

                  if (value) _chosenItems.addAll(widget.items);

                  widget.onChange?.call(_chosenItems);
                })),
        children: widget.items
            .map((item) => new _DialogOption(
                title: item,
                isChosen: _chosenItems.contains(item),
                onChanged: (value) => setState(() {
                      value
                          ? _chosenItems.add(item)
                          : _chosenItems.remove(item);
                      widget.onChange?.call(_chosenItems);
                    })))
            .toList());
  }
}

class _DialogOption extends StatelessWidget {
  final String title;

  final bool isChosen;

  final void Function(bool) onChanged;

  const _DialogOption(
      {@required this.title,
      @required this.isChosen,
      @required this.onChanged});

  @override
  Widget build(BuildContext context) => new ShrinkableSimpleDialogOption(
      new CheckboxListTile(
          title: new Text(title), onChanged: onChanged, value: isChosen),
      isShrunk: true);
}

class _CheckboxList extends StatefulWidget {
  final String title;
  final List<String> items;
  final List<Widget> buttons;
  final Function(Set<String>) onChange;

  const _CheckboxList(this.title, this.items,
      {@required this.onChange, @required this.buttons})
      : super();

  @override
  _CheckboxListState createState() {
    return new _CheckboxListState();
  }
}

class TranslationSelectorDialog extends SelectorDialog<String> {
  Set<String> _chosenTranslations;

  final BuildContext _context;

  TranslationSelectorDialog(BuildContext context)
      : _context = context,
        super();

  @override
  Future<String> show([List<String> items]) {
    final locale = AppLocalizations.of(_context);
    items ??= <String>[];
    return items.isNotEmpty
        ? showDialog(
            context: _context,
            builder: (dialogContext) {
              return new _CheckboxList(
                  locale.translationSelectorDialogTitle, items,
                  onChange: (chosenItems) => _chosenTranslations = chosenItems,
                  buttons: <Widget>[
                    new CancelButton(() => returnResult(_context)),
                    new ElevatedButton(
                        onPressed: () => returnResult(
                            _context, _chosenTranslations?.join('; ')),
                        child:
                            new Text(locale.translationSelectorDoneButtonLabel))
                  ]);
            })
        : Future.value(items.firstWhere((_) => true, orElse: () => null));
  }
}
