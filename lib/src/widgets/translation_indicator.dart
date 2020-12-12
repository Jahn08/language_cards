import 'package:flutter/material.dart';
import '../models/language.dart';
import '../widgets/asset_icon.dart';
import '../widgets/icon_option.dart';

class TranslationIndicator extends StatelessWidget {
        
    final Language from;

    final Language to;

    TranslationIndicator(this.from, this.to) {
        assert(this.from != null);
        assert(this.to != null);
        assert(this.from != this.to);
    }

    @override
    Widget build(BuildContext context) => new Container(
        margin: new EdgeInsets.only(right: 5),
        child: new Stack(
            children: <Widget>[
                new IconOption(icon: AssetIcon.getByLanguage(this.from)),
                new Positioned(left: AssetIcon.WIDTH / 2, 
                    child: IconOption(icon: AssetIcon.getByLanguage(this.to)))
            ]
        )
    );
}
