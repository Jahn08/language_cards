import 'package:flutter/material.dart';
import 'string_ext.dart';

class LocalAssetImage extends AssetImage {

  	LocalAssetImage(String fileName, [String fileExt]) : 
		super(joinPaths(['assets', 'images', '$fileName.${fileExt ?? 'jpg'}']));
}
