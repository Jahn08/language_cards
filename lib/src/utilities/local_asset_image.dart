import 'package:flutter/material.dart';
import 'path.dart';
import '../data/asset_reader.dart';

class LocalAssetImage extends AssetImage {
  LocalAssetImage(String fileName, {String? fileExtension, String? localeName})
      : super(Path.combine([
          AssetReader.rootPath,
          'images',
          if (localeName != null) localeName,
          '$fileName.${fileExtension ?? 'jpg'}'
        ]));
}
