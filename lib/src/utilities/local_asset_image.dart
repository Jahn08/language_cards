import 'package:flutter/material.dart';
import 'string_ext.dart';

class LocalAssetImage extends AssetImage {

  	LocalAssetImage(String fileName, { String fileExtension, String localeName }) : 
		super(joinPaths(['assets', 'images', 
			if (localeName != null) localeName, '$fileName.${fileExtension ?? 'jpg'}']));
}
