import 'package:flutter/widgets.dart';
import 'package:sentry/sentry.dart';
import 'dart:convert' show jsonDecode;
import '../models/app_params.dart';
import '../data/asset_reader.dart';

export '../models/app_params.dart';

class Configuration {
  static AppParams _params;

  static Future<AppParams> getParams(BuildContext context,
      {bool reload = true}) async {
    try {
      if (_params == null || reload) await _load(context);

      return _params;
    } catch (exception, stackTrace) {
      await Sentry.captureException(
        exception,
        stackTrace: stackTrace,
      );

      return const AppParams();
    }
  }

  static Future<void> _load(BuildContext context) async {
    const cfgFolderName = 'cfg';
    final configs = await Future.wait([
      _tryLoadParams([cfgFolderName, 'secret_params.json'], context,
          isSecret: true),
      _tryLoadParams([cfgFolderName, 'params.json'], context)
    ]);

    final secretConfig = _filterConfigs(configs, isSecret: true);
    final config = _filterConfigs(configs, isSecret: false);

    if (config == null)
      throw new StateError(
          'No proper configuration has been found in the assets');

    _params = config.merge(secretConfig);
  }

  static Future<Map<bool, AppParams>> _tryLoadParams(
      List<String> paths, BuildContext context,
      {bool isSecret}) async {
    AppParams params;

    try {
      final json = await new AssetReader(context).loadString(paths);
      params = new AppParams.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (ex) {
      params = null;
    }

    return {isSecret ?? false: params};
  }

  static AppParams _filterConfigs(List<Map<bool, AppParams>> configs,
          {bool isSecret}) =>
      configs
          .firstWhere((element) => element.containsKey(isSecret),
              orElse: () => null)
          ?.values
          ?.first;
}
