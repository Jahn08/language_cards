import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utilities/path.dart';

class AssetReader {

	static const String rootPath = 'assets';

	final AssetBundle assetBundle;

	AssetReader(BuildContext context):
		assetBundle = DefaultAssetBundle.of(context);

	Future<String> loadString(List<String> keyPaths) async {
		return await _loadString((keyPaths..insert(0, rootPath)));
	}

	Future<String> _loadString(List<String> keyPaths) async {
		return await assetBundle.loadString(Path.combine(keyPaths));
	}
	
	Future<ByteData> load(List<String> keyPaths) async {
		return await assetBundle.load(Path.combine(keyPaths..insert(0, rootPath)));
	}

	Future<List<String>> listAssetNames([String path]) async {
		if (path != null)
			path = Path.combine([rootPath, path]);

		final paths = (json.decode(await _loadString(['AssetManifest.json'])) as Map<String, dynamic>).keys;
		return (path == null ? paths: paths.where((f) => f.startsWith(path))
			.map((f) => Path.getFileName(f))).toList();
	}
}
