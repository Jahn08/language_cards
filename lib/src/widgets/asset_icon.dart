import 'package:path/path.dart';
import 'package:flutter/material.dart';
import '../models/language.dart';

class AssetIcon extends Image {
    static const double WIDTH = 40;
    static const double HEIGHT = 20;

    static final AssetIcon russianFlag = new AssetIcon('flag_ru');
    static final AssetIcon britishFlag = new AssetIcon('flag_uk');

    AssetIcon(String name): super(
        image: new AssetImage(join('assets', 'images', '$name.jpg')), 
        color: null,
        fit: BoxFit.fill,
        width: WIDTH,
        height: HEIGHT
    );

    static AssetIcon getByLanguage(Language lang) {
        switch (lang) {
            case Language.english:
                return britishFlag;
            case Language.russian:
                return russianFlag;
            default:
                return null;
        }
    }
}
