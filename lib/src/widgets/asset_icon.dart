import 'package:flutter/material.dart';
import '../models/language.dart';
import '../utilities/local_asset_image.dart';

class AssetIcon extends Image {
  static const double widthValue = 40;
  static const double heightValue = 20;

  static final AssetIcon russianFlag = new AssetIcon('flag_ru');
  static final AssetIcon britishFlag = new AssetIcon('flag_uk');
  static final AssetIcon frenchFlag = new AssetIcon('flag_fr');
  static final AssetIcon germanFlag = new AssetIcon('flag_de');
  static final AssetIcon spanishFlag = new AssetIcon('flag_es');
  static final AssetIcon italianFlag = new AssetIcon('flag_it');

  AssetIcon(String name)
      : super(
            image: new LocalAssetImage(name),
            color: null,
            fit: BoxFit.fill,
            width: widthValue,
            height: heightValue);

  static AssetIcon getByLanguage(Language lang) {
    if (lang == Language.english) return britishFlag;
    switch (lang) {
      case Language.english:
        return britishFlag;
      case Language.spanish:
        return spanishFlag;
      case Language.russian:
        return russianFlag;
      case Language.german:
        return germanFlag;
      case Language.french:
        return frenchFlag;
      case Language.italian:
        return italianFlag;
      default:
        return null;
    }
  }
}
