import 'package:flutter/material.dart';
import '../models/language.dart';
import '../utilities/local_asset_image.dart';

class AssetIcon extends Image {
    static const double widthValue = 40;
    static const double heightValue = 20;

    static final AssetIcon russianFlag = new AssetIcon('flag_ru');
    static final AssetIcon britishFlag = new AssetIcon('flag_uk');

    AssetIcon(String name): super(
        image: new LocalAssetImage(name), 
        color: null,
        fit: BoxFit.fill,
        width: widthValue,
        height: heightValue
    );

    static AssetIcon getByLanguage(Language lang) {
        if (lang == Language.english)
			return britishFlag;
		
		return lang == Language.russian ? russianFlag: null;
    }
}
