import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utilities/path.dart';

class AssetReader {
  static const String rootPath = 'assets';

  final AssetBundle assetBundle;

  AssetReader(BuildContext context)
      : assetBundle = DefaultAssetBundle.of(context);

  Future<String> loadString(List<String> keyPaths) =>
      _loadString((keyPaths..insert(0, rootPath)));

  Future<String> _loadString(List<String> keyPaths) =>
      assetBundle.loadString(Path.combine(keyPaths));

  Future<ByteData> load(List<String> keyPaths) =>
      assetBundle.load(Path.combine(keyPaths..insert(0, rootPath)));

  Future<List<String>> listAssetNames([String path]) async {
    final paths = (json.decode(await _loadString(['AssetManifest.json']))
            as Map<String, dynamic>)
        .keys;
    if (path == null) return paths.toList();

    final assetPathPrefix = Path.combine([rootPath, path]);
    return paths
        .where((f) => f.startsWith(assetPathPrefix))
        .map((f) => Path.getFileName(f))
        .toList();
  }
}
