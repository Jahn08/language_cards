import 'package:flutter/widgets.dart';
import 'package:path/path.dart' show join;
import 'dart:convert'show jsonDecode;
import '../models/app_params.dart';
export '../models/app_params.dart';

class Configuration {
    static AppParams _params;

    static Future<AppParams> getParams(BuildContext context, { bool reload: true }) async {
        if (_params == null || reload)
            await _load(context);

        return _params;
    }

    static _load(BuildContext context) async {
        final cfgRootFolderPath = join('assets', 'cfg');

        final configs = await Future.wait([
            _tryLoadParams(join(cfgRootFolderPath, 'secret_params.json'), context, isSecret: true), 
            _tryLoadParams(join(cfgRootFolderPath, 'params.json'), context)]);

        final secretConfig = _filterConfigs(configs, isSecret: true);
        final config = _filterConfigs(configs, isSecret: false);

        // TODO: Process the error further
        if (config == null)
            throw new StateError('No proper configuration has been found in the assets');

        _params = config.merge(secretConfig);
    }

    static Future<Map<bool, AppParams>> _tryLoadParams(String path, BuildContext context, 
        { bool isSecret }) async {
        AppParams params;

        try {
            final json = await DefaultAssetBundle.of(context).loadString(path);
            params = new AppParams.fromJson(jsonDecode(json));
        }
        catch (ex) {
            params = null;
        }

        return { (isSecret ?? false): params }; 
    }

    static AppParams _filterConfigs(List<Map<bool, AppParams>> configs, { bool isSecret }) => 
        configs.firstWhere((element) => element.containsKey(isSecret), 
            orElse: () => null)?.values?.first;
}
