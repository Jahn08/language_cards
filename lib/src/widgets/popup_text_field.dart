import 'package:flutter/material.dart';
import 'styled_text_field.dart';

class _PopupTextFieldState extends State<PopupTextField> {

	final LayerLink _layerLink = LayerLink();

	OverlayEntry _overlayEntry;

	List<ListTile> _tiles;

	bool _isValueChosen;
	String _value;

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
			link: this._layerLink,
			child: StyledTextField(widget.label, 
				isRequired: true, 
				onChanged: widget.onChanged,
				onFocusChanged: (bool hasFocus) => _toggleOverlay(hasFocus),
				onInput: (value) async {
					if (_isValueChosen)
						_isValueChosen = false;
					
					await _setTiles(value);

					_toggleOverlay(true);
				},
				initialValue: _value
			)
		);
	}

	Future<void> _setTiles(String value) async {
		_tiles = (await (widget.popupItemsBuilder?.call(value) ?? Future.value([])))
			.map((t) => new ListTile(
				title: new Text(t), 
				dense: true,
				visualDensity: VisualDensity.comfortable,
				onTap: () { 
					_toggleOverlay(false);
					
					_isValueChosen = true;
					setState(() => _value = t);
				}
			)).toList();
	}

	_toggleOverlay(bool hasFocus) {
		if (_isValueChosen)
			return;

		if (this._overlayEntry != null && this._overlayEntry.mounted)
			this._overlayEntry.remove();

		if (hasFocus && (this._overlayEntry = this._createOverlayEntry()) != null)
			Overlay.of(context).insert(this._overlayEntry);
	}
	
	OverlayEntry _createOverlayEntry() {
		if (_tiles.isEmpty)
			return null;

		RenderBox renderBox = context.findRenderObject();
		var size = renderBox.size;

		return OverlayEntry(
			builder: (context) => Positioned(
				width: size.width,
				child: CompositedTransformFollower(
					link: this._layerLink,
					showWhenUnlinked: false,
					offset: Offset(0.0, size.height + 5.0),
					child: Material(
						elevation: 4.0,
						child: ListView(
							padding: EdgeInsets.zero,
							shrinkWrap: true,
							children: _tiles
						)
					)
				)
			)
		);
	}
}

class PopupTextField extends StatefulWidget {

	final String label;

	final String initialValue;

	final bool isRequired;

	final Function(String value, bool submitted) onChanged;

	final Future<List<String>> Function(String value) popupItemsBuilder;

	PopupTextField(this.label, { @required this.popupItemsBuilder, 
		this.onChanged, this.isRequired, this.initialValue });

	@override
	_PopupTextFieldState createState() => new _PopupTextFieldState();
}
