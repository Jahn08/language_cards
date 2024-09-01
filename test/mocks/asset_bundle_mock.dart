import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:language_cards/src/models/app_params.dart';

class AssetBundleMock extends CachingAssetBundle {
  static const String _secretParamAssetKey = 'assets/cfg/secret_params.json';
  static const String _paramAssetKey = 'assets/cfg/params.json';

  final AppParams _params;
  final AppParams _secretParams;

  final void Function(String key, ByteData data) onAssetLoaded;

  AssetBundleMock(
      {AppParams params, AppParams secretParams, this.onAssetLoaded})
      : _params = params,
        _secretParams = secretParams;

  @override
  Future<ByteData> load(String key) async {
    if (key == _secretParamAssetKey)
      return _convertToBytes(_secretParams);
    else if (key == _paramAssetKey) return _convertToBytes(_params);

    final data = await rootBundle.load(key);
    onAssetLoaded?.call(key, data);

    return data;
  }

  ByteData _convertToBytes(Object obj) {
    if (obj == null) return null;

    final bytes = const Utf8Codec().encode(jsonEncode(obj));
    return new ByteData.sublistView(Int8List.fromList(bytes));
  }
}
