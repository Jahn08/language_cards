import 'package:flutter/material.dart';
import './asset_icon.dart';

class IconOption extends StatelessWidget {
    final Widget _iconWidget;
    final bool _isSelected;
    
    IconOption({Widget icon, bool isSelected}): 
        _iconWidget = icon,
        _isSelected = isSelected;

    @override
    Widget build(BuildContext context) {
        return new Container(
            width: AssetIcon.WIDTH,
            height: AssetIcon.HEIGHT,
            child: _iconWidget,
            margin: EdgeInsets.all(5),
            decoration: new BoxDecoration(
                border: _isSelected ? new Border.all(
                    color: Colors.blueGrey,
                    width: 2
                ): null
            )
        );
    }
}
