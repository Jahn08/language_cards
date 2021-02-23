import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:language_cards/src/models/app_params.dart';

class TestAssetBundle extends CachingAssetBundle {
    static const String _secretParamAssetKey = 'assets/cfg/secret_params.json';
    static const String _paramAssetKey = 'assets/cfg/params.json';

    final AppParams _params;
    final AppParams _secretParams;

    TestAssetBundle.params(AppParams params, { AppParams secretParams }): 
        _params = params, _secretParams = secretParams;

    @override
    Future<ByteData> load(String key) async {
        if (key == _secretParamAssetKey) 
            return _convertToBytes(_secretParams);
        else if (key == _paramAssetKey)
            return _convertToBytes(_params);
			
        return null;
    }

    ByteData _convertToBytes(Object obj) {
        final bytes = new Utf8Codec().encode(jsonEncode(obj));
        return new ByteData.sublistView(Int8List.fromList(bytes));
    }
}
