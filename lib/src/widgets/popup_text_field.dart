import 'package:flutter/material.dart';
import 'styled_text_field.dart';
import '../utilities/styler.dart';

class _PopupTextFieldState extends State<PopupTextField> {
  final LayerLink _layerLink = LayerLink();

  OverlayEntry? _overlayEntry;

  late List<ListTile> _tiles;

  late bool _isValueChosen;
  late String _value;

  @override
  void initState() {
    super.initState();

    _tiles = [];

    _value = widget.initialValue;
    _isValueChosen = false;
  }

  @override
  void didUpdateWidget(covariant PopupTextField oldWidget) {
    super.didUpdateWidget(oldWidget);

    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
        link: _layerLink,
        child: StyledTextField(widget.label,
            isRequired: widget.isRequired,
            onChanged: widget.onChanged,
            onFocusChanged: ({bool hasFocus = false}) =>
                _toggleOverlay(hasFocus),
            onInput: (value) async {
              if (_isValueChosen) _isValueChosen = false;

              await _setTiles(context, value);

              _toggleOverlay(true);
            },
            initialValue: _value));
  }

  Future<void> _setTiles(BuildContext context, String value) async {
    final isDense = new Styler(context).isDense;
    final popupItems = await widget.popupItemsBuilder.call(value);
    _tiles = popupItems
        .map((t) => new ListTile(
            title: new Text(t),
            dense: isDense,
            visualDensity: VisualDensity.comfortable,
            onTap: () {
              _toggleOverlay(false);

              _isValueChosen = true;
              setState(() => _value = t);
            }))
        .toList();
  }

  void _toggleOverlay(bool hasFocus) {
    if (_isValueChosen) return;

    if (!hasFocus) {
      if (_overlayEntry != null) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      }

      return;
    }

    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();

      if (_overlayEntry != null) Overlay.of(context).insert(_overlayEntry!);
    } else
      _overlayEntry!.markNeedsBuild();
  }

  OverlayEntry? _createOverlayEntry() {
    if (_tiles.isEmpty) return null;

    final renderBox = context.findRenderObject()! as RenderBox;
    final size = renderBox.size;
    return OverlayEntry(
        builder: (context) => Positioned(
            width: size.width,
            child: CompositedTransformFollower(
                link: _layerLink,
                showWhenUnlinked: false,
                offset: Offset(0.0, size.height + 5.0),
                child: Material(
                    elevation: 4.0,
                    child: ListView(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        children: _tiles)))));
  }
}

class PopupTextField extends StatefulWidget {
  final String label;

  final String initialValue;

  final bool isRequired;

  final Function(String? value, {bool? submitted})? onChanged;

  final Future<Iterable<String>> Function(String value) popupItemsBuilder;

  const PopupTextField(this.label,
      {required this.popupItemsBuilder,
      this.onChanged,
      this.isRequired = false,
      this.initialValue = ''});

  @override
  _PopupTextFieldState createState() => new _PopupTextFieldState();
}
