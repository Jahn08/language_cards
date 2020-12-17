import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:typed_data';

class TestAssetBundle extends CachingAssetBundle {
    static const String _secret_param_asset_key = 'assets/cfg/secret_params.json';
    static const String _param_asset_key = 'assets/cfg/params.json';

    final Object _params;
    final Object _secretParams;

    TestAssetBundle.params(Object params, { Object secretParams }): 
        _params = params, _secretParams = secretParams;

    @override
    Future<ByteData> load(String key) async {
        if (key == _secret_param_asset_key) 
            return _convertToBytes(_secretParams);
        else if (key == _param_asset_key)
            return _convertToBytes(_params);

        return null;
    }

    ByteData _convertToBytes(Object obj) {
        final bytes = new Utf8Codec().encode(jsonEncode(obj));
        return new ByteData.sublistView(Int8List.fromList(bytes));
    }
}
