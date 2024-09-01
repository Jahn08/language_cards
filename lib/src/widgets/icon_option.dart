import 'package:flutter/material.dart';
import './asset_icon.dart';

class IconOption extends StatelessWidget {
  final Widget _iconWidget;
  final bool isSelected;

  const IconOption({required Widget icon, bool? isSelected})
      : _iconWidget = icon,
        isSelected = isSelected ?? false;

  @override
  Widget build(BuildContext context) => new Container(
      width: AssetIcon.widthValue,
      height: AssetIcon.heightValue,
      child: _iconWidget,
      decoration: new BoxDecoration(
          border: isSelected
              ? new Border.all(color: Colors.blueGrey, width: 2)
              : null));
}
